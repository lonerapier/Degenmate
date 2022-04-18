// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {ERC20} from "../ERC20/ERC20.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";

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

contract MockERC20User {
    ERC20 _token;

    constructor(ERC20 token) {
        _token = token;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        return _token.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        return _token.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        return _token.approve(spender, amount);
    }
}

contract ERC20Test is DSTestPlus {
    MockERC20 token;
    address constant sampleAdd = address(0xABC);

    function setUp() public {
        token = new MockERC20("ERC20Token", "TOK", 18);
    }

    function invariantMetadata() public {
        assertEq(token.name(), "ERC20Token");
        assertEq(token.symbol(), "TOK");
        assertEq(token.decimals(), 18);
    }

    function testMetadata() public {
        assertEq(token.name(), "ERC20Token");
        assertEq(token.symbol(), "TOK");
        assertEq(token.decimals(), 18);
    }

    function testMint() public {
        token.mint(sampleAdd, 1e18);
        assertEq(token.balanceOf(sampleAdd), 1e18);
        assertEq(token.totalSupply(), 1e18);
    }

    function testBurn() public {
        token.mint(sampleAdd, 10);

        vm.prank(sampleAdd);
        token.burn(5);

        assertEq(token.balanceOf(sampleAdd), 5);
        assertEq(token.totalSupply(), 5);
    }

    function testTransfer() public {
        token.mint(address(this), 10);

        assertTrue(token.transfer(sampleAdd, 10));

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(sampleAdd), 10);
    }

    function testApprove() public {
        token.mint(address(this), 10);

        assertTrue(token.approve(sampleAdd, 10));

        assertEq(token.allowance(address(this), sampleAdd), 10);
    }

    function testTransferFrom() public {
        token.mint(address(this), 10);

        MockERC20User user = new MockERC20User(token);
        token.approve(address(user), 10);

        assertTrue(user.transferFrom(address(this), sampleAdd, 5));

        assertEq(token.allowance(address(this), address(user)), 5);
        assertEq(token.balanceOf(address(this)), 5);
        assertEq(token.balanceOf(sampleAdd), 5);
    }

    function testFailBurnInvalidAddress() public {
        token.mint(sampleAdd, 10);

        token.burn(10);
    }

    function testFailBurnInsufficientBalance() public {
        token.mint(sampleAdd, 10);

        token.burn(11);
    }

    function testFailTransferInsufficientBalance() public {
        token.mint(address(this), 10);

        token.transfer(sampleAdd, 11);
    }

    function testFailTransferFromInsufficientAllowance() public {
        token.mint(address(this), 10);
        MockERC20User user = new MockERC20User(token);

        token.approve(address(user), 9);
        user.transferFrom(address(this), sampleAdd, 10);
    }
}
