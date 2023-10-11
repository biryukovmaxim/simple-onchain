// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@gelatonetwork/relay-context/contracts/GelatoRelayContextERC2771.sol";
import "./SenderUpgradeable.sol";
import "./IPaymaster.sol";

contract GaslessSenderUpgradeable is Initializable, SenderUpgradeable, GelatoRelayContextERC2771 {
    IPaymaster public paymaster;

    modifier maybeGasLess(bytes4 hash) {
        _;
        _payToRelayer(hash);
    }

    function initialize(IERC20Upgradeable token_,
        address executor_,
        IPaymaster paymaster_) external initializer {
        __Sender_init(token_, executor_);
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

    function createTransferWrapped(
        uint256 amount,
        bytes16 extId,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg
    ) public override maybeGasLess(0x73d94fd9) {
        super.createTransferWrapped(
            amount,
            extId,
            encodedDestination,
            encodedMsg
        );
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

    function depositFor(
        address account,
        uint256 amount
    ) public override maybeGasLess(0x2f4f21e2) returns (bool) {
        return super.depositFor(account, amount);
    }

    function withdrawTo(
        address account,
        uint256 amount
    ) public override maybeGasLess(0x205c2878) returns (bool) {
        return super.withdrawTo(account, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override maybeGasLess(0xa9059cbb) returns (bool) {
        return super.transfer(to, amount);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override maybeGasLess(0x095ea7b3) returns (bool) {
        return super.approve(spender, amount);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public override maybeGasLess(0x39509351) returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public override maybeGasLess(0xa457c2d7) returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
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
