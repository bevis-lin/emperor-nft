// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract EmperorFusion is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;
    mapping(uint256 => string) private _uris;
    string public name = "Emperor";

    constructor() public ERC1155("") {}

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    // function setTokenUri(uint256 tokenId, string memory uri) public {
    //     _uris[tokenId] = uri;
    // }

    function mintNFT(
        address recipient,
        uint256 amount,
        string memory tokenURI
    ) public returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _uris[newItemId] = tokenURI;
        _mint(recipient, newItemId, amount, "");
        return newItemId;
    }
}
