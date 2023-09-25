// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPaymaster {
    function payToRelayer(
        address msgSender,
        bytes4 func,
        address feeToken,
        address feeCollector,
        uint256 fee
    ) external;
}
