// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GNToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("GN", "GNToken") {
        _mint(msg.sender, initialSupply);
    }
}
