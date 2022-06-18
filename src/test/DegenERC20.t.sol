// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {MockDegenERC20} from "./mocks/MockERC20.sol";
import {Test, stdError} from "std/Test.sol";

contract DegenERC20Test is Test {
    MockDegenERC20 token;

    function setUp() public {
        token = new MockDegenERC20(
            "SampleBlockGreaterThan31BytesToTestTheFunction",
            "DEG",
            18
        );
    }

    function testName() public {
        assertEq(
            token.name(),
            "SampleBlockGreaterThan31BytesToTestTheFunction"
        );
    }

    function testSymbol() public {
        assertEq(token.symbol(), "DEG");
    }

    function testDecimals() public {
        assertEq(token.decimals(), 18);
    }

    function testTotalSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    function testBalanceOf() public {
        assertEq(token.balanceOf(address(0x0)), 0);
    }

    function testMint() public {
        token.mint(address(this), 100);

        assertEq(token.totalSupply(), 100);
        assertEq(token.balanceOf(address(this)), 100);

        token.mint(address(0xabcd), 10000);

        assertEq(token.totalSupply(), 10100);
        assertEq(token.balanceOf(address(0xabcd)), 10000);
    }

    function testMintAddressZero() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        token.mint(address(0), 10);
    }

    function testMintOverflow() public {
        token.mint(address(this), type(uint256).max);

        vm.expectRevert(stdError.arithmeticError);
        token.mint(address(this), 10);
    }

    function testBurn() public {
        token.mint(address(this), 100);

        token.burn(100);

        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testBurnPartial() public {
        token.mint(address(this), 100);

        token.burn(50);

        assertEq(token.totalSupply(), 50);
        assertEq(token.balanceOf(address(this)), 50);
    }

    function testBurnInsufficientBalance() public {
        token.mint(address(this), 100);

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        token.burn(101);
    }

    function testApprove() public {
        token.approve(address(0xabcd), 100);

        assertEq(token.allowances(address(this), address(0xabcd)), 100);
    }

    function testTransferInsufficientBalance() public {
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        token.transfer(address(0xabcd), 50);
    }

    function testTransfer() public {
        token.mint(address(this), 100);

        bool success = token.transfer(address(0xabcd), 50);
        assertTrue(success);

        assertEq(token.balanceOf(address(this)), 50);
        assertEq(token.balanceOf(address(0xabcd)), 50);
    }

    function testTransferFromInsufficientAllowance() public {
        token.mint(address(this), 100);

        token.approve(address(0xabcd), 50);

        vm.expectRevert(abi.encodeWithSignature("InsufficientAllowance()"));
        vm.prank(address(0xabcd));
        token.transferFrom(address(this), address(0xdead), 51);
    }

    function testTransferFromInsufficientBalance() public {
        token.mint(address(this), 100);

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        token.transferFrom(address(this), address(0xdead), 101);
    }

    function testTransferFrom() public {
        token.mint(address(this), 100);

        bool success = token.transferFrom(address(this), address(0xdead), 50);
        assertTrue(success);

        assertEq(token.balanceOf(address(this)), 50);
        assertEq(token.balanceOf(address(0xdead)), 50);
    }

    function testTransferFromToZero() public {
        token.mint(address(this), 100);

        token.approve(address(0xabcd), 50);

        bool success = token.transferFrom(address(this), address(0x0), 50);
        assertTrue(success);

        vm.prank(address(0xabcd));
        success = token.transferFrom(address(this), address(0x0), 50);
        assertTrue(success);

        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(0x0)), 100);
        assertEq(token.allowances(address(this), address(0xabcd)), 0);
    }
}
