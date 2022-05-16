// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Payment.sol";

contract Marketplace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _listingsSold;

    enum ListingStatus {
        Open,
        Close,
        Sold
    }

    enum ListingType {
        First,
        Second
    }

    struct Listing {
        uint256 listingId;
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

    constructor(address nftContractAddress) {
        nftContract = IERC721(nftContractAddress);
    }

    event ListingCreated(
        uint256 indexed listingId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    function createListing(
        uint256 tokenId,
        uint256 price,
        address payable paymentAddress
    ) public nonReentrant {
        require(price > 0, "Price must be at least 1 wei");

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        listings[listingId] = Listing(
            listingId,
            tokenId,
            price,
            payable(msg.sender),
            payable(Payment(paymentAddress)),
            ListingType.First,
            ListingStatus.Open,
            address(0)
        );

        IERC721(nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit ListingCreated(listingId, tokenId, msg.sender, address(0), price);
    }

    function deListing(uint256 listingId) public {
        Listing storage listing = listings[listingId];
        listing.status = ListingStatus.Close;
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

        if (listings[listingID].listingType == ListingType.First) {
            listings[listingID].payment.transfer(transferAmount);
            nftContract.transferFrom(address(this), transferTo, tokenId);
            listings[listingID].buyer = transferTo;
        } else {
            listings[listingID].seller.transfer(transferAmount);
            nftContract.transferFrom(address(this), msg.sender, tokenId);
            listings[listingID].buyer = msg.sender;
        }

        _listingsSold.increment();
    }
}
