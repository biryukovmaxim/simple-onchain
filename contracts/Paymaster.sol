// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IPaymaster.sol";

contract Paymaster is Ownable, IPaymaster {
    using SafeERC20 for IERC20;
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public senderContract;
    mapping(address token => bool) public supportedFeeTokens;

    modifier onlySenderContract() {
        require(_msgSender() == senderContract);
        _;
    }

    constructor(address[] memory supportedFeeTokens_) {
        for (uint256 i = 0; i < supportedFeeTokens_.length; i++) {
            supportedFeeTokens[supportedFeeTokens_[i]] = true;
        }
    }

    receive() external payable {}

    function withdraw(
        address[] calldata tokens,
        address destination
    ) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == NATIVE_TOKEN) {
                uint256 balance = address(this).balance;
                if (balance == 0) continue;
                Address.sendValue(payable(destination), balance);
            } else {
                uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
                if (balance == 0) continue;
                IERC20(tokens[i]).safeTransfer(destination, balance);
            }
        }
    }

    function setSenderContract(address senderAddr) public onlyOwner {
        senderContract = senderAddr;
    }

    function addSupportedFeeToken(address token) public onlyOwner {
        supportedFeeTokens[token] = true;
    }

    function disableSupportedFeeToken(address token) public onlyOwner {
        supportedFeeTokens[token] = false;
    }

    function payToRelayer(
        address,
        bytes4,
        address feeToken,
        address feeCollector,
        uint256 fee
    ) public onlySenderContract {
        require(supportedFeeTokens[feeToken], "unsupported fee token");
        if (fee == 0) return;
        feeToken == NATIVE_TOKEN
            ? Address.sendValue(payable(feeCollector), fee)
            : IERC20(feeToken).safeTransfer(feeCollector, fee);
    }
}
