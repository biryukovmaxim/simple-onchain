// SPDX-License-Identifier: MIT

pragma solidity >=0.8.19 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MockToken is ERC20Permit {
    constructor() ERC20Permit("MockToken") ERC20("MockToken", "MKT") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
