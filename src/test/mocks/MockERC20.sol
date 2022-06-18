// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ERC20} from "../../ERC20/ERC20.sol";
import {DegenERC20} from "../../ERC20/DegenERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {}

    function mint(address to, uint256 totalSupply) public virtual {
        _mint(to, totalSupply);
    }

    function burn(uint256 amount) public virtual {
        _burn(amount);
    }
}

contract MockDegenERC20 is DegenERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) DegenERC20(name, symbol, decimals) {}

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(amount);
    }
}
