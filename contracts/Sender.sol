// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Sender is Ownable, ERC20Wrapper, ERC20Permit {
    using SafeERC20 for IERC20;

    struct TransferStruct {
        bytes16 extId;
        address from;
        uint256 amount;
        uint256 createdAt;
        bool wrappedToken;
    }

    address private _executor;
    mapping(bytes16 extId => TransferStruct transfer) private _transfers;

    event Queued(
        bytes16 indexed extId,
        TransferStruct transfer,
        bytes encodedDestination,
        bytes encodedMsg
    );
    event SuccessfulTransfer(bytes16 indexed extId, TransferStruct transfer);

    constructor(
        IERC20 token_,
        address executor_
    )
        ERC20("Simple USD", "SUSD")
        ERC20Wrapper(token_)
        ERC20Permit("Simple USD")
    {
        _executor = executor_;
    }

    function setExecutor(address newExecutor) public onlyOwner {
        _executor = newExecutor;
    }

    function createTransfer(
        uint256 amount,
        bytes16 extId,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg,
        bool wrappedToken
    ) public virtual {
        (, bool exists, ) = getTransfer(extId);
        if (!exists) {
            revert("transfer with this ext_id is already exists");
        }
        require(amount > 0, "You need to transfer at least some tokens");
        IERC20 token = wrappedToken ? IERC20(this) : underlying();
        uint256 allowance = token.allowance(_msgSender(), address(this));
        require(allowance >= amount, "Check the token allowance");
        _createTransfer(
            extId,
            amount,
            encodedDestination,
            encodedMsg,
            wrappedToken
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
        bytes32 s,
        bool wrappedToken
    ) public virtual {
        {
            (, bool exists, ) = getTransfer(extId);
            if (!exists) {
                revert("transfer with this ext_id is already exists");
            }
        }
        {
            require(amount > 0, "You need to transfer at least some tokens");
            address token = wrappedToken
                ? address(this)
                : address(underlying());
            IERC20Permit(token).permit(
                _msgSender(),
                address(this),
                amount,
                deadline,
                v,
                r,
                s
            );
        }
        _createTransfer(
            extId,
            amount,
            encodedDestination,
            encodedMsg,
            wrappedToken
        );
    }

    function executeTransfer(bytes16 extId, address to) public {
        require(_msgSender() == _executor, "you are not an executor");

        (
            TransferStruct memory transfer,
            bool exists,
            bool executed
        ) = getTransfer(extId);

        require(exists, "transfer does not exist");
        require(!executed, "transfer is already executed");

        emit SuccessfulTransfer(extId, transfer);

        uint256 amount = transfer.amount;
        require(amount > 0);
        _transfers[extId].amount = 0;
        if (transfer.wrappedToken) {
            _transfer(address(this), to, amount);
        } else {
            _mint(to, amount);
        }
    }

    function getTransfer(
        bytes16 extId
    )
        public
        view
        returns (TransferStruct memory order, bool exists, bool executed)
    {
        order = _transfers[extId];
        if (_transfers[extId].amount > 0) {
            return (order, true, false);
        }
        if (_transfers[extId].extId.length > 0) {
            return (order, true, true);
        }

        return (order, false, false);
    }

    function decimals()
        public
        view
        virtual
        override(ERC20, ERC20Wrapper)
        returns (uint8)
    {
        return 6;
    }

    function _createTransfer(
        bytes16 extId,
        uint256 amount,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg,
        bool wrappedToken
    ) internal {
        IERC20 token = wrappedToken ? IERC20(this) : underlying();
        token.safeTransferFrom(_msgSender(), address(this), amount);
        TransferStruct memory transfer = TransferStruct(
            extId,
            _msgSender(),
            amount,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp,
            wrappedToken
        );
        _transfers[extId] = transfer;
        emit Queued(extId, transfer, encodedDestination, encodedMsg);
    }
}
