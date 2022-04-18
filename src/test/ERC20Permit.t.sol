// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {ERC20Permit} from "../ERC20/ERC20Permit.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";

contract MockERC20Permit is ERC20Permit {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20Permit(name, symbol, decimals) {}

    function mint(address to, uint256 totalSupply) public virtual {
        _mint(to, totalSupply);
    }

    function burn(uint256 amount) public virtual {
        _burn(amount);
    }
}

contract ERC20PermitTest is DSTestPlus {
    MockERC20Permit token;
    address public constant sampleAdd = address(0xABC);
    bytes32 public constant permitTypehash =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    function setUp() public {
        token = new MockERC20Permit("Mock", "MOCK", 18);
    }

    function testMetaData() public {
        assertEq(token.name(), "Mock");
        assertEq(token.symbol(), "MOCK");
        assertEq(token.decimals(), 18);
    }

    function testPermit() public {
        uint256 privateKey = uint256(0xBDCE);
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            sampleAdd,
                            100,
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        token.permit(owner, sampleAdd, 100, block.timestamp, v, r, s);

        assertEq(token.allowance(owner, sampleAdd), 100);
        assertEq(token.nonces(owner), 1);
    }

    function testPermitTwice() public {
        uint256 privateKey = uint256(0xBDCE);
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            sampleAdd,
                            100,
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        token.permit(owner, sampleAdd, 100, block.timestamp, v, r, s);

        assertEq(token.allowance(owner, sampleAdd), 100);
        assertEq(token.nonces(owner), 1);

        (v, r, s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            sampleAdd,
                            1000,
                            1,
                            block.timestamp
                        )
                    )
                )
            )
        );

        token.permit(owner, sampleAdd, 1000, block.timestamp, v, r, s);

        assertEq(token.allowance(owner, sampleAdd), 1000);
        assertEq(token.nonces(owner), 2);
    }

    function testFailPermitBadDeadline() public {
        uint256 privateKey = uint256(0xBDCE);
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            sampleAdd,
                            100,
                            0,
                            block.timestamp + 1
                        )
                    )
                )
            )
        );

        token.permit(owner, sampleAdd, 100, block.timestamp, v, r, s);
    }

    function testFailPermitInvalidDeadline() public {
        uint256 privateKey = uint256(0xBDCE);
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            sampleAdd,
                            100,
                            0,
                            block.timestamp + 1
                        )
                    )
                )
            )
        );

        token.permit(owner, sampleAdd, 100, block.timestamp - 1, v, r, s);
    }

    function testFailPermitBadNonce() public {
        uint256 privateKey = uint256(0xBDCE);
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            sampleAdd,
                            100,
                            1,
                            block.timestamp + 1
                        )
                    )
                )
            )
        );

        token.permit(owner, sampleAdd, 100, block.timestamp, v, r, s);
    }

    function testFailPermitTwice() public {
        uint256 privateKey = uint256(0xBDCE);
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            sampleAdd,
                            100,
                            0,
                            block.timestamp + 1
                        )
                    )
                )
            )
        );

        token.permit(owner, sampleAdd, 100, block.timestamp, v, r, s);
        token.permit(owner, sampleAdd, 100, block.timestamp, v, r, s);
    }

    function testFuzzPermit(
        address to,
        uint256 value,
        uint256 deadline
    ) public {
        if (deadline < block.timestamp) deadline = block.timestamp;

        uint256 privateKey = uint256(0xbabe);
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            to,
                            value,
                            0,
                            deadline
                        )
                    )
                )
            )
        );

        token.permit(owner, to, value, deadline, v, r, s);

        assertEq(token.allowance(owner, to), value);
        assertEq(token.nonces(owner), 1);
    }

    function testFailFuzzPermitBadDeadline(
        uint256 privateKey,
        address to,
        uint256 value,
        uint256 deadline
    ) public {
        if (privateKey == 0) privateKey = 1;
        if (deadline < block.timestamp) deadline = block.timestamp;

        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.getDomainSeparator(),
                    keccak256(
                        abi.encode(
                            permitTypehash,
                            owner,
                            to,
                            value,
                            0,
                            deadline
                        )
                    )
                )
            )
        );

        token.permit(owner, to, value, deadline + 1, v, r, s);
    }
}
