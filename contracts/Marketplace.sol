// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Payment.sol";

contract Marketplace is
    IERC165,
    IERC721Receiver,
    IERC1155Receiver,
    ReentrancyGuard,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _listingsSold;

    enum ListingStatus {
        Open,
        Close,
        Sold
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    enum ListingType {
        Primary,
        Secondary
    }

    struct Listing {
        uint256 listingId;
        TokenType tokenType;
        uint256 tokenId;
        uint256 price;
        address payable seller; //who list this sale
        address payable payment;
        ListingType listingType;
        ListingStatus status;
        address buyer;
    }

    mapping(uint256 => Listing) private listings;

    IERC721 nftContract;
    IERC1155 nftFusionContract;

    constructor(address nftContractAddress, address nftFusionContractAddress) {
        nftContract = IERC721(nftContractAddress);
        nftFusionContract = IERC1155(nftFusionContractAddress);
    }

    event ListingCreated(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event ListingDelisted(
        uint256 indexed listingId,
        string tokenType,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    function createPrimaryListing(
        TokenType tokenType,
        uint256 tokenId,
        uint256 price,
        address payable paymentAddress
    ) public onlyOwner nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        require(
            owner() == Payment(paymentAddress).owner(),
            "Payment should belong to listing owner"
        );

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        listings[listingId] = Listing(
            listingId,
            tokenType,
            tokenId,
            price,
            payable(msg.sender),
            payable(Payment(paymentAddress)),
            ListingType.Primary,
            ListingStatus.Open,
            address(0)
        );

        if (tokenType == TokenType.ERC721) {
            IERC721(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        } else {
            IERC1155(nftFusionContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                1,
                "0x0"
            );
        }

        emit ListingCreated(listingId, tokenId, msg.sender, price);
    }

    function createSecondaryListing(
        TokenType tokenType,
        uint256 tokenId,
        uint256 price
    ) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");
        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        listings[listingId] = Listing(
            listingId,
            tokenType,
            tokenId,
            price,
            payable(msg.sender),
            payable(address(0)),
            ListingType.Secondary,
            ListingStatus.Open,
            address(0)
        );

        if (tokenType == TokenType.ERC721) {
            IERC721(nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        } else {
            IERC1155(nftFusionContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                1,
                "0x0"
            );
        }

        emit ListingCreated(listingId, tokenId, msg.sender, price);
    }

    function getListingById(uint256 listingId)
        public
        view
        returns (Listing memory)
    {
        return listings[listingId];
    }

    function deListing(uint256 listingId) public {
        Listing storage listing = listings[listingId];
        listing.status = ListingStatus.Close;

        if (listing.tokenType == TokenType.ERC721) {
            IERC721(nftContract).safeTransferFrom(
                address(this),
                listing.seller,
                listing.tokenId
            );
        } else {
            IERC1155(nftFusionContract).safeTransferFrom(
                address(this),
                listing.seller,
                listing.tokenId,
                1,
                "0x0"
            );
        }

        emit ListingDelisted(
            listing.listingId,
            listing.tokenType,
            listing.tokenId,
            listing.seller,
            listing.price
        );
    }

    function getUnsoldListings() public view returns (Listing[] memory) {
        uint256 listingCount = _listingIds.current();
        uint256 unsoldItemCount = _listingIds.current() -
            _listingsSold.current();
        uint256 currentIndex = 0;

        Listing[] memory unsoldListings = new Listing[](unsoldItemCount);
        for (uint256 i = 0; i < listingCount; i++) {
            if (listings[i + 1].buyer == address(0)) {
                uint256 currentId = i + 1;
                Listing memory currentItem = listings[currentId];
                unsoldListings[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return unsoldListings;
    }

    function purchase(uint256 listingID, address transferTo)
        public
        payable
        nonReentrant
    {
        uint256 price = listings[listingID].price;
        uint256 tokenId = listings[listingID].tokenId;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );

        //calculate operation fee(2%)
        uint256 operationFee = (price * 200) / 10000;
        uint256 transferAmount = price - operationFee;

        if (listings[listingID].listingType == ListingType.Primary) {
            listings[listingID].payment.transfer(transferAmount);
            if (listings[listingID].tokenType == TokenType.ERC721) {
                nftContract.transferFrom(address(this), transferTo, tokenId);
            } else {
                nftFusionContract.safeTransferFrom(
                    address(this),
                    transferTo,
                    tokenId,
                    1,
                    "0x0"
                );
            }

            listings[listingID].buyer = transferTo;
        } else {
            listings[listingID].seller.transfer(transferAmount);
            if (listings[listingID].tokenType == TokenType.ERC721) {
                nftContract.transferFrom(address(this), msg.sender, tokenId);
            } else {
                nftFusionContract.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    1,
                    "0x0"
                );
            }
            listings[listingID].buyer = msg.sender;
        }

        _listingsSold.increment();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
