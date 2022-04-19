// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {IERC1155, IERC1155Receiver} from "../ERC1155/IERC1155.sol";
import {ERC1155, ERC1155Receiver} from "../ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        _mint(to, id, amount, data);
    }

    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public {
        _batchMint(to, ids, amounts, data);
    }

    function burn(uint256 id, uint256 value) public {
        _burn(id, value);
    }

    function batchBurn(uint256[] calldata ids, uint256[] calldata values)
        public
    {
        _batchBurn(ids, values);
    }
}

contract MockERC1155Receiver is ERC1155Receiver {}

contract RevertingERC1155Receiver is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert(
            string(
                abi.encodePacked(IERC1155Receiver.onERC1155Received.selector)
            )
        );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert(
            string(
                abi.encodePacked(
                    IERC1155Receiver.onERC1155BatchReceived.selector
                )
            )
        );
    }
}

contract InvalidDataERC1155Receiver is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return 0xC0FFEEEE;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure override returns (bytes4) {
        return 0xC0FFEEEE;
    }
}

contract NonERC1155Receiver {
    fallback() external {}
}

contract TestERC1155 is DSTestPlus, ERC1155Receiver {
    address constant mockUser = address(0xbabe);

    MockERC1155 token;
    MockERC1155Receiver receiver;
    RevertingERC1155Receiver revertingReceiver;
    InvalidDataERC1155Receiver invalidDataReceiver;
    NonERC1155Receiver nonERC1155Receiver;

    function setUp() public {
        vm.label(mockUser, "MockUser");
        token = new MockERC1155();

        receiver = new MockERC1155Receiver();
        vm.label(address(receiver), "MockReceiver");

        revertingReceiver = new RevertingERC1155Receiver();
        vm.label(address(revertingReceiver), "RevertingReceiver");

        invalidDataReceiver = new InvalidDataERC1155Receiver();
        vm.label(address(invalidDataReceiver), "InvalidDataReceiver");

        nonERC1155Receiver = new NonERC1155Receiver();
        vm.label(address(nonERC1155Receiver), "NonERC1155Receiver");
    }

    function testMintSingleValueExternalEOA() public {
        uint256 id = 1;
        uint256 amount = 1;

        token.mint(mockUser, id, amount, hex"");

        assertEq(token.balanceOf(mockUser, id), amount);
    }

    function testMintMultipleValueExternalEOA() public {
        uint256 id = 1;
        uint256 value = 1e4;

        token.mint(mockUser, id, value, hex"");

        assertEq(token.balanceOf(mockUser, id), value);
    }

    function testMintMultipleIDExternalEOA() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256 value = 1e4;

        for (uint256 i = 0; i < ids.length; ++i) {
            token.mint(mockUser, ids[i], value, hex"");
        }

        assertEq(token.balanceOf(mockUser, ids[0]), value);
        assertEq(token.balanceOf(mockUser, ids[1]), value);
    }

    function testMintMultipleIDsMultipleExternalEOA() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256 value = 1e4;

        for (uint256 i = 0; i < ids.length; ++i) {
            token.mint(mockUser, ids[i], value, hex"");
        }

        assertEq(token.balanceOf(mockUser, ids[0]), value);
        assertEq(token.balanceOf(mockUser, ids[1]), value);
    }

    function testMintToMockERC1155Receiver() public {
        uint256 id = 1;
        uint256 amount = 1;

        token.mint(address(receiver), id, amount, hex"");

        assertEq(token.balanceOf(address(receiver), id), amount);
    }

    function testMintToRevertingERC1155Receiver() public {
        uint256 id = 1;
        uint256 amount = 1;

        vm.expectRevert(
            abi.encodePacked(ERC1155Receiver.onERC1155Received.selector)
        );
        token.mint(address(revertingReceiver), id, amount, hex"");

        assertEq(token.balanceOf(address(revertingReceiver), id), 0);
    }

    function testMintToInvalidDataERC1155Receiver() public {
        uint256 id = 1;
        uint256 amount = 1;

        vm.expectRevert(abi.encodeWithSignature("UnsafeRecipient()"));
        token.mint(address(invalidDataReceiver), id, amount, hex"");

        assertEq(token.balanceOf(address(invalidDataReceiver), id), 0);
    }

    function testFailMintToNonERC1155Receiver() public {
        uint256 id = 1;
        uint256 amount = 1;

        token.mint(address(nonERC1155Receiver), id, amount, hex"");

        assertEq(token.balanceOf(address(nonERC1155Receiver), id), 0);
    }

    function testBatchMint() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1e4;
        values[1] = 2e4;

        token.batchMint(mockUser, ids, values, hex"");

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), values[i]);
        }
    }

    function testBatchMintMultipleAddress() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1e4;
        values[1] = 2e4;

        token.batchMint(mockUser, ids, values, hex"");
        token.batchMint(address(receiver), ids, values, hex"");

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), values[i]);
            assertEq(token.balanceOf(address(receiver), ids[i]), values[i]);
        }
    }

    function testBatchMintInvalidLength() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](1);
        values[0] = 1e4;

        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        token.batchMint(mockUser, ids, values, hex"");
    }

    function testBatchMintToMockERC1155Receiver() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1e4;
        values[1] = 2e4;

        token.batchMint(address(receiver), ids, values, hex"");

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(address(receiver), ids[i]), values[i]);
        }
    }

    function testBatchMintToRevertingERC1155Receiver() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1e4;
        values[1] = 2e4;

        vm.expectRevert(
            abi.encodePacked(ERC1155Receiver.onERC1155BatchReceived.selector)
        );
        token.batchMint(address(revertingReceiver), ids, values, hex"");

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(address(revertingReceiver), ids[i]), 0);
        }
    }

    function testBatchMintToInvalidDataERC1155Receiver() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1e4;
        values[1] = 2e4;

        vm.expectRevert(abi.encodeWithSignature("UnsafeRecipient()"));
        token.batchMint(address(invalidDataReceiver), ids, values, hex"");

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(address(invalidDataReceiver), ids[i]), 0);
        }
    }

    function testFailBatchMintToNonERC1155Receiver() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1e4;
        values[1] = 2e4;

        token.batchMint(address(nonERC1155Receiver), ids, values, hex"");

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(address(nonERC1155Receiver), ids[i]), 0);
        }
    }

    function testBurn() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");
        vm.prank(mockUser);
        token.burn(id, amount);

        assertEq(token.balanceOf(mockUser, id), 0);
    }

    function testBurnMultipleAddress() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");
        vm.prank(mockUser);
        token.burn(id, amount);
        token.mint(address(receiver), id, amount, hex"");
        vm.prank(address(receiver));
        token.burn(id, amount);

        assertEq(token.balanceOf(mockUser, id), 0);
        assertEq(token.balanceOf(address(receiver), id), 0);
    }

    function testBurnInsufficientBalance() public {
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        token.burn(1, 1);
    }

    function testBatchBurn() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");
        vm.prank(mockUser);
        token.batchBurn(ids, amounts);

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), 0);
        }
    }

    function testBatchBurnMultipleAddress() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");
        vm.prank(mockUser);
        token.batchBurn(ids, amounts);
        token.batchMint(address(receiver), ids, amounts, hex"");
        vm.prank(address(receiver));
        token.batchBurn(ids, amounts);

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), 0);
            assertEq(token.balanceOf(address(receiver), ids[i]), 0);
        }
    }

    function testBatchBurnInsufficientBalance() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");
        vm.prank(mockUser);
        token.batchBurn(ids, amounts);
        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        token.batchBurn(ids, amounts);
    }

    function testBatchBurnInvalidLength() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e4;

        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        token.batchBurn(ids, amounts);
    }

    function testSetApprovalForAll() public {
        vm.prank(mockUser);
        token.setApprovalForAll(address(receiver), true);

        assertTrue(token.isApprovedForAll(mockUser, address(receiver)));
    }

    function testBalanceOfBatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        address[] memory addresses = new address[](2);
        addresses[0] = mockUser;
        addresses[1] = address(receiver);

        token.batchMint(mockUser, ids, amounts, hex"");
        token.batchMint(address(receiver), ids, amounts, hex"");
        uint256[] memory amount = token.balanceOfBatch(addresses, ids);

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(amount[i], amounts[i]);
        }
    }

    function testBalanceOfBatchInvalidLength() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        address[] memory addresses = new address[](1);
        addresses[0] = mockUser;

        vm.expectRevert(abi.encodeWithSignature("InvalidLength()"));
        token.balanceOfBatch(addresses, ids);
    }

    function testSafeTransferFromBySelf() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");

        vm.prank(mockUser);
        token.safeTransferFrom(mockUser, address(0xdead), id, amount, hex"");

        assertEq(token.balanceOf(mockUser, id), 0);
        assertEq(token.balanceOf(address(0xdead), id), amount);
    }

    function testSafeTransferFromByApproval() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");

        vm.prank(mockUser);
        token.setApprovalForAll(address(this), true);

        token.safeTransferFrom(mockUser, address(0xdead), id, amount, hex"");

        assertEq(token.balanceOf(mockUser, id), 0);
        assertEq(token.balanceOf(address(0xdead), id), amount);
    }

    function testSafeTransferFromToERC1155Receiver() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");

        vm.prank(mockUser);
        token.safeTransferFrom(mockUser, address(receiver), id, amount, hex"");

        assertEq(token.balanceOf(mockUser, id), 0);
        assertEq(token.balanceOf(address(receiver), id), amount);
    }

    function testSafeTransferFromToRevertingReceiver() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");

        vm.expectRevert(
            abi.encodePacked(ERC1155Receiver.onERC1155Received.selector)
        );
        vm.prank(mockUser);
        token.safeTransferFrom(
            mockUser,
            address(revertingReceiver),
            id,
            amount,
            hex""
        );

        assertEq(token.balanceOf(mockUser, id), amount);
        assertEq(token.balanceOf(address(revertingReceiver), id), 0);
    }

    function testSafeTransferFromToInvalidReceiver() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");

        vm.expectRevert(abi.encodeWithSignature("UnsafeRecipient()"));
        vm.prank(mockUser);
        token.safeTransferFrom(
            mockUser,
            address(invalidDataReceiver),
            id,
            amount,
            hex""
        );

        assertEq(token.balanceOf(mockUser, id), amount);
        assertEq(token.balanceOf(address(invalidDataReceiver), id), 0);
    }

    function testSafeTransferFromUnauthorised() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");

        vm.expectRevert(abi.encodeWithSignature("Unauthorised()"));
        token.safeTransferFrom(mockUser, address(0xdead), id, amount, hex"");

        assertEq(token.balanceOf(mockUser, id), 1e4);
        assertEq(token.balanceOf(address(0xdead), id), 0);
    }

    function testSafeTransferFromInsufficientBalance() public {
        uint256 id = 1;
        uint256 amount = 1e4;

        token.mint(mockUser, id, amount, hex"");

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        vm.prank(mockUser);
        token.safeTransferFrom(
            mockUser,
            address(0xdead),
            id,
            amount + 1,
            hex""
        );

        assertEq(token.balanceOf(mockUser, id), 1e4);
        assertEq(token.balanceOf(address(0xdead), id), 0);
    }

    function testSafeBatchTransferFromToEOA() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");

        vm.prank(mockUser);
        token.safeBatchTransferFrom(
            mockUser,
            address(0xdead),
            ids,
            amounts,
            hex""
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), 0);
            assertEq(token.balanceOf(address(0xdead), ids[i]), amounts[i]);
        }
    }

    function testSafeBatchTransferFromApprovals() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");

        vm.prank(mockUser);
        token.setApprovalForAll(address(this), true);

        token.safeBatchTransferFrom(
            mockUser,
            address(0xdead),
            ids,
            amounts,
            hex""
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), 0);
            assertEq(token.balanceOf(address(0xdead), ids[i]), amounts[i]);
        }
    }

    function testSafeBatchTransferFromToERC1155Receiver() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");

        vm.prank(mockUser);
        token.safeBatchTransferFrom(
            mockUser,
            address(receiver),
            ids,
            amounts,
            hex""
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), 0);
            assertEq(token.balanceOf(address(receiver), ids[i]), amounts[i]);
        }
    }

    function testSafeBatchTransferFromToRevertingReceiver() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");

        vm.expectRevert(
            abi.encodePacked(ERC1155Receiver.onERC1155BatchReceived.selector)
        );
        vm.prank(mockUser);
        token.safeBatchTransferFrom(
            mockUser,
            address(revertingReceiver),
            ids,
            amounts,
            hex""
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), amounts[i]);
            assertEq(token.balanceOf(address(revertingReceiver), ids[i]), 0);
        }
    }

    function testSafeBatchTransferFromToInvalidReceiver() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");

        vm.expectRevert(abi.encodeWithSignature("UnsafeRecipient()"));
        vm.prank(mockUser);
        token.safeBatchTransferFrom(
            mockUser,
            address(invalidDataReceiver),
            ids,
            amounts,
            hex""
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), amounts[i]);
            assertEq(token.balanceOf(address(invalidDataReceiver), ids[i]), 0);
        }
    }

    function testSafeBatchTransferFromToUnauthorised() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");

        vm.expectRevert(abi.encodeWithSignature("Unauthorised()"));
        token.safeBatchTransferFrom(
            mockUser,
            address(0xdead),
            ids,
            amounts,
            hex""
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), amounts[i]);
            assertEq(token.balanceOf(address(0xdead), ids[i]), 0);
        }
    }

    function testSafeBatchTransferFromToInsufficientBalance() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1e4;
        amounts[1] = 2e4;

        token.batchMint(mockUser, ids, amounts, hex"");

        vm.prank(mockUser);

        uint256[] memory amounts2 = new uint256[](2);
        amounts2[0] = 1e4;
        amounts2[1] = 3e4;

        vm.expectRevert(abi.encodeWithSignature("InsufficientBalance()"));
        token.safeBatchTransferFrom(
            mockUser,
            address(0xdead),
            ids,
            amounts2,
            hex""
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            assertEq(token.balanceOf(mockUser, ids[i]), amounts[i]);
            assertEq(token.balanceOf(address(0xdead), ids[i]), 0);
        }
    }
}
