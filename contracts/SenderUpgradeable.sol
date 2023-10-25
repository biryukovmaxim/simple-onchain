// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SenderUpgradeable is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    struct TransferStruct {
        bytes16 extId;
        address from;
        uint256 amount;
        uint256 createdAt;
    }

    IERC20 public token;
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
        uint256 allowance = token.allowance(_msgSender(), address(this));
        require(allowance >= amount, "Check the token allowance");

        _createTransfer(extId, amount, encodedDestination, encodedMsg);
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
            IERC20Permit(address(token)).permit(
                _msgSender(),
                address(this),
                amount,
                deadline,
                v,
                r,
                s
            );
        }
        _createTransfer(extId, amount, encodedDestination, encodedMsg);
    }

    function transferFromPermitted(
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(amount > 0, "You need to transfer at least some tokens");
        IERC20Permit(address(token)).permit(
            _msgSender(),
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        token.safeTransferFrom(_msgSender(), to, amount);
    }

    function transferFrom(address to, uint256 amount) public virtual {
        uint256 allowance = token.allowance(_msgSender(), address(this));
        require(allowance >= amount, "Check the token allowance");
        token.safeTransferFrom(_msgSender(), to, amount);
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

        token.safeTransfer(to, amount);
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

    function _createTransfer(
        bytes16 extId,
        uint256 amount,
        bytes calldata encodedDestination,
        bytes calldata encodedMsg
    ) internal {
        token.safeTransferFrom(_msgSender(), address(this), amount);
        TransferStruct memory transfer = TransferStruct(
            extId,
            _msgSender(),
            amount,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
        _transfers[extId] = transfer;
        emit Queued(extId, transfer, encodedDestination, encodedMsg);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Sender_init(
        IERC20 token_,
        address executor_,
        address owner_
    ) internal onlyInitializing {
        __Ownable_init();
        _transferOwnership(owner_);
        _executor = executor_;
        token = token_;
    }
}
