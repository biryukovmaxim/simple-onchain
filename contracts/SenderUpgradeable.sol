// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract SenderUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC20WrapperUpgradeable,
    ERC20PermitUpgradeable
{
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

    //    function initialize(IERC20Upgradeable token_, address executor_) external initializer {
    //        __ERC20_init("Simple USD", "SUSD");
    //        __ERC20Wrapper_init(token_);
    //        __ERC20Permit_init("Simple USD");
    //        _executor = executor_;
    //    }

    function setExecutor(address newExecutor) public onlyOwner {
        _executor = newExecutor;
    }

    function createTransfer(
        uint256 amount,
        bytes16 extId,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg
    ) public virtual {
        (, bool exists, ) = getTransfer(extId);
        if (!exists) {
            revert("transfer with this ext_id is already exists");
        }
        require(amount > 0, "You need to transfer at least some tokens");
        uint256 allowance = underlying().allowance(_msgSender(), address(this));
        require(allowance >= amount, "Check the token allowance");

        _createTransfer(extId, amount, encodedDestination, encodedMsg, false);
    }

    function createTransferWrapped(
        uint256 amount,
        bytes16 extId,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg
    ) public virtual {
        (, bool exists, ) = getTransfer(extId);
        if (!exists) {
            revert("transfer with this ext_id is already exists");
        }
        require(amount > 0, "You need to transfer at least some tokens");
        _createTransfer(extId, amount, encodedDestination, encodedMsg, true);
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
    ) public virtual {
        {
            (, bool exists, ) = getTransfer(extId);
            if (!exists) {
                revert("transfer with this ext_id is already exists");
            }
        }
        {
            require(amount > 0, "You need to transfer at least some tokens");
            IERC20Permit(address(underlying())).permit(
                _msgSender(),
                address(this),
                amount,
                deadline,
                v,
                r,
                s
            );
        }
        _createTransfer(extId, amount, encodedDestination, encodedMsg, false);
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
        override(ERC20Upgradeable, ERC20WrapperUpgradeable)
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
        IERC20Upgradeable token = wrappedToken
            ? IERC20Upgradeable(this)
            : underlying();
        IERC20(address(token)).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
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

    function __Sender_init(
        IERC20Upgradeable token_,
        address executor_
    ) internal onlyInitializing {
        __ERC20_init("Simple USD", "SUSD");
        __ERC20Wrapper_init(token_);
        __ERC20Permit_init("Simple USD");
        _executor = executor_;
    }
}
