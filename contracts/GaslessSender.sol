// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@gelatonetwork/relay-context/contracts/GelatoRelayContextERC2771.sol";
import "./Sender.sol";
import "./IPaymaster.sol";

contract GaslessSender is Sender, GelatoRelayContextERC2771 {
    IPaymaster public paymaster;

    modifier maybeGasLess(bytes4 hash) {
        _;
        _payToRelayer(hash);
    }

    constructor(
        IERC20 token_,
        address executor_,
        IPaymaster paymaster_
    ) Sender(token_, executor_) {
        paymaster = paymaster_;
    }

    function setPaymaster(IPaymaster newPaymaster) public onlyOwner {
        paymaster = newPaymaster;
    }

    function createTransfer(
        uint256 amount,
        bytes16 extId,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg
    ) public override maybeGasLess(0x85f0a47f) {
        super.createTransfer(amount, extId, encodedDestination, encodedMsg);
    }

    function createTransferPermitted(
        uint256 amount,
        bytes16 extId,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override maybeGasLess(0xaee2e5a1) {
        super.createTransferPermitted(
            amount,
            extId,
            encodedDestination,
            encodedMsg,
            deadline,
            v,
            r,
            s
        );
    }

    function transferFromPermitted(
        address to,
        uint256 amount,
        bytes calldata encodedMsg,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override maybeGasLess(0x5525b8ca) {
        return super.transferFromPermitted(to, amount, encodedMsg, deadline, v, r, s);
    }

    function transferFrom(
        address to,
        uint256 amount,
        bytes calldata encodedMsg
    ) public override maybeGasLess(0xd311a045) {
        return super.transferFrom(to, amount, encodedMsg);
    }

    function _payToRelayer(bytes4 func) internal {
        if (_isGelatoRelayERC2771(msg.sender)) {
            paymaster.payToRelayer(
                _msgSender(),
                func,
                _getFeeToken(),
                _getFeeCollector(),
                _getFee()
            );
        }
    }

    function _msgSender() internal view override returns (address) {
        return _getMsgSender();
    }

    function _msgData() internal view override returns (bytes calldata) {
        return _getMsgData();
    }
}
