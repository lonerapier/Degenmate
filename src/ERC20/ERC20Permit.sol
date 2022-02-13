// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

contract ERC20Permit is ERC20 {

    // EIP-2612 storage variables
    mapping (address => uint256) public nonces;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {
    }

    function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
        require(_deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");


        bytes32 hashStruct = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            _owner,
            _spender,
            _value,
            nonces[_owner]++,
            _deadline
        ));

        unchecked {
            bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                getDomainSeparator(),
                hashStruct
            ));

            address recoverAddress = ecrecover(digest, v, r, s);
            require(recoverAddress != address(0) && recoverAddress == _owner, "PERMIT_RECOVER_FAILED");

            _allowance[_owner][_spender] = _value;
        }

        emit Approval(_owner, _spender, _value);
    }

    function getDomainSeparator() public view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}
