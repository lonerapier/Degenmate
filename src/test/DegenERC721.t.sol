// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Test, stdError} from "std/Test.sol";
import {MockERC721} from "./mocks/MockERC721.sol";

contract DegenERC721Test is Test {
    MockERC721 public token;

    function setUp() public {
        token = new MockERC721(
            "DegenERC721",
            "DEGEN"
        );
    }

    function testMetadata() public {
        assertEq(token.name(), "DegenERC721");
        assertEq(token.symbol(), "DEGEN");
    }

    function testMint() public {
        token.mint(address(0xabcd), 1);

        assertEq(token.balanceOf(address(0xabcd)), 1);
    }
}
