// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//import "./EmperorUtils.sol";
//import "./EmperorTemplates.sol";

contract Emperor is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    //address contractAddress;

    //nftId => EmperorInfo
    //mapping(uint256 => EmperorInfo) public mintedEmperors;

    // constructor(address marketplaceAddress) ERC721("Emperor", "NFT") {
    //     contractAddress = marketplaceAddress;
    // }

    constructor() ERC721("Emperor", "NFT") {}

    function mintNFT(address recipient, string memory tokenURI)
        public
        returns (uint256)
    {
        //Template memory template = getTemplateById(templateId);
        //require(template.id > 0, "Template not exists");

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        // EmperorInfo memory info;
        // info.templateId = templateId;
        // info.isMetadatLocked = true;
        // mintedEmperors[newItemId] = info;

        //setApprovalForAll(contractAddress, true);

        return newItemId;
    }
}
