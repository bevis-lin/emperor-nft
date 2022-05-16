// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Payment is PaymentSplitter {
    string public paymentTitle;

    // _payee comprise creator,commission
    constructor(
        string memory _paymentTitle,
        address[] memory _payees,
        uint256[] memory _shares
    ) payable PaymentSplitter(_payees, _shares) {
        paymentTitle = _paymentTitle;
    }
}
