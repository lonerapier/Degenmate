// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

contract DegenERC721 is IERC165 {

    // ============= Metadata variables =============

    string private _name;
    string private _symbol;

    // ============= Storage variables =============

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    // ============= Approval variables =============

    mapping(address => mapping(address => bool)) private _isApprovedForAll;
    mapping(uint256 => address) _approvals;

    // ============= Constructor =============

    constructor(string memory __name, string memory __symbol) {
        _name = __name;
        _symbol = __symbol;
    }

    /// @notice Get the name of the token.
    /// @return ptr The name of the token.
    function name() public view returns (string memory ptr) {
        assembly {
            // load free memory pointer
            ptr := mload(0x40)

            // load slot to memory
            let slotLoad := sload(_name.slot)

            // check if string length is greater than 31 bytes
            switch and(slotLoad, 1)
            case 0 {
                // string length is less than 32 bytes

                // length = last 2 bytes / 2
                let len := shr(1, and(0xff, slotLoad))

                // store length
                mstore(ptr, len)

                // store string
                mstore(add(ptr, 32), and(slotLoad, not(0xff)))

                // return free memory pointer
                mstore(0x40, add(add(ptr, 32), len))
            }
            case 1 {
                // string length is greater than 31 bytes

                // length = (slotContent - 1) / 2
                let len := shr(1, sub(slotLoad, 1))

                // find slot of the data i.e. keccak256(slot)
                mstore(0, _name.slot)
                let slot := keccak256(0, 32)

                // total slots required = (length + 31) / 32
                let totalSlots := shr(5, add(len, 31))

                // store length
                mstore(ptr, len)

                // store string word by word
                for {
                    let i := 0
                } lt(i, totalSlots) {
                    i := add(i, 1)
                } {
                    mstore(add(add(ptr, 32), mul(i, 32)), sload(add(slot, i)))
                }

                // return mem[0x40 : 0x40 + len +32]
                mstore(0x40, add(add(ptr, 32), len))
            }
        }
    }

    /// @notice Get the symbol of the token.
    /// @return ptr The symbol of the token.
    function symbol() public view returns (string memory ptr) {
        assembly {
            // load free memory pointer
            ptr := mload(0x40)

            // load slot to memory
            let slotLoad := sload(_symbol.slot)

            // check if string length is greater than 31 bytes
            switch and(slotLoad, 1)
            case 0 {
                // string length is less than 32 bytes
                let len := shr(1, and(0xff, slotLoad))

                // store length
                mstore(ptr, len)

                // store string
                mstore(add(ptr, 32), and(slotLoad, not(0xff)))

                // return free memory pointer
                mstore(0x40, add(add(ptr, 32), len))
            }
            case 1 {
                // string length is greater than 31 bytes

                // length = (slotContent - 1) / 2
                let len := shr(1, sub(slotLoad, 1))

                // find slot of the data i.e. keccak256(slot)
                mstore(0, _symbol.slot)
                let slot := keccak256(0, 32)

                // total slots required = (length + 31) / 32
                let totalSlots := shr(5, add(len, 31))

                // store length
                mstore(ptr, len)

                // store string word by word
                for {
                    let i := 0
                } lt(i, totalSlots) {
                    i := add(i, 32)
                } {
                    mstore(add(add(ptr, 32), mul(i, 32)), sload(add(slot, i)))
                }

                // return mem[0x40 : 0x40 + len + 32]
                mstore(0x40, add(add(ptr, 32), len))
            }
        }
    }

    /// @notice Get token URI
    function tokenURI(uint256) public pure virtual returns (string memory) {
        return "";
    }

    /// @notice get current owner of the token
    /// @param _tokenId The token ID.
    /// @return The owner of the token.
    function ownerOf(uint256 _tokenId) public view returns (address) {
        assembly {
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            let owner := sload(keccak256(0, 64))

            mstore(0x40, owner)

            return(0x40, 32)
        }
    }

    /// @notice get current balance of the owner
    /// @param _owner The owner address.
    /// @return The balance of the owner.
    function balanceOf(address _owner) public view returns (uint256) {
        assembly {
            mstore(0, _owner)
            mstore(32, _balances.slot)

            let ownerBalance := sload(keccak256(0, 64))

            mstore(0x40, ownerBalance)

            return(0x40, 32)
        }
    }

    /// @notice support ERC165 logic
    /// @param _interfaceId The interface ID.
    /// @return result True if the interface is supported.
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool result) {
        assembly {
            result := or(
                eq(_interfaceId, 0x01ffc9a7),
                or(
                    eq(_interfaceId, 0x80ac58cd),
                    eq(_interfaceId, 0x5b5e139f)
                )
            )
        }
    }

    /// @notice get the approved address for the token
    /// @param _tokenId The token ID.
    /// @return The approved address.
    function getApproved(uint256 _tokenId) public view virtual  returns(address) {
        assembly {
            mstore(0, _tokenId)
            mstore(32, _approvals.slot)

            let approved := sload(keccak256(0, 64))

            mstore(0x40, approved)

            return(0x40, 32)
        }
    }

    /// @notice cheeck if operator is approved for all tokens of the owner
    /// @param _owner The owner address.
    /// @param _operator The operator address.
    /// @return True if the operator is approved for all tokens of the owner.
    function isApprovedForAll(address _owner, address _operator) public view virtual  returns (bool) {
        assembly {
            mstore(0, _owner)
            mstore(32, _isApprovedForAll.slot)

            let ownerCont := keccak256(0, 64)

            mstore(0, _operator)
            mstore(32, ownerCont)

            let operatorCont := sload(keccak256(0, 64))

            mstore(0x40, operatorCont)

            return(0x40, 32)
        }
    }

    /// @notice set approval of operator for all tokens of the owner
    /// @param _operator The operator address.
    /// @param _approved flag to toggle
    function setApprovalForAll(address _operator, bool _approved) public virtual {
        assembly {
            if iszero(_operator) {
                // error InvalidAddress()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            if eq(_operator, caller()) {
                // error SelfApproval()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            mstore(0, caller())
            mstore(32, _isApprovedForAll.slot)

            let ownerCont := keccak256(0, 64)

            mstore(0, _operator)
            mstore(32, ownerCont)

            let operatorCont := keccak256(0, 64)

            sstore(operatorCont, _approved)
        }
    }

    /// @notice approve operator for the token
    /// @dev emit Approval event
    /// @param _operator The operator address.
    /// @param _tokenId The token ID.
    function approve(address _operator, uint256 _tokenId) public virtual {
        assembly {
            if iszero(_operator) {
                // error InvalidAddress()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            // find owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            let owner := sload(keccak256(0, 64))

            // find approval of the token
            mstore(0, _tokenId)
            mstore(32, _approvals.slot)

            let approved := sload(keccak256(0, 64))

            // find isApprovedForAll of the token
            mstore(0, caller())
            mstore(32, _isApprovedForAll.slot)

            let ownerCont := keccak256(0, 64)

            mstore(0, _operator)
            mstore(32, ownerCont)

            let isApproved := sload(keccak256(0, 64))

            if iszero(
                or(
                    eq(caller(), owner),
                    or(
                        eq(caller(), approved),
                        isApproved
                    )
                )
            ) {
                // error AccessDenied()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            // set approval of the token
            mstore(0, _tokenId)
            mstore(32, _approvals.slot)

            let approvedSlot := keccak256(0, 64)

            sstore(approvedSlot, _operator)

            // emit Approval event
            let approveSigHash :=
            0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
            log4(0, 0, approveSigHash, caller(), _operator, _tokenId)
        }
    }

    /// @notice transfer ownership of the token
    /// @dev emit Transfer event
    /// @param _to The new owner address.
    /// @param _tokenId The token ID.
    function transfer(address _to, uint256 _tokenId) public virtual {
        assembly {
            // find owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            let owner := sload(keccak256(0, 64))

            // revert if token does not exist
            if iszero(owner) {
                // error NoTokenFound()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            if iszero(eq(caller(), owner)) {
                // error AccessDenied()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            // update balances of owner
            mstore(0, caller())
            mstore(32, _balances.slot)

            let ownerBalance := sload(keccak256(0, 64))

            sstore(keccak256(0, 64), sub(ownerBalance, 1))

            // update balances of receiver
            mstore(0, _to)
            mstore(32, _balances.slot)

            let receiverBalance := sload(keccak256(0, 64))

            sstore(keccak256(0, 64), add(receiverBalance, 1))

            // update owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            sstore(keccak256(0, 64), _to)

            // delete approval of the token
            mstore(0, _tokenId)
            mstore(32, _approvals.slot)

            sstore(keccak256(0, 64), 0)

            // emit Transfer event
            let transferSigHash :=
            0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
            log4(0, 0, transferSigHash, owner, _to, _tokenId)
        }
    }

    /// @notice transfer ownership of the token
    /// @dev emit Transfer event
    /// @param _from The previous owner address.
    /// @param _to The new owner address.
    /// @param _tokenId The token ID.
    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual {
        assembly {
            // find owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            let owner := sload(keccak256(0, 64))

            // revert if token does not exist
            if iszero(owner) {
                // error TokenDoesNotExist()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            // find approval of the token
            mstore(0, _tokenId)
            mstore(32, _approvals.slot)

            let approved := sload(keccak256(0, 64))

            // find isApprovedForAll of the token
            mstore(0, caller())
            mstore(32, _isApprovedForAll.slot)

            let ownerCont := keccak256(0, 64)

            mstore(0, _from)
            mstore(32, ownerCont)

            let isApproved := sload(keccak256(0, 64))

            if iszero(
                or(
                    eq(caller(), owner),
                    or(
                        eq(caller(), approved),
                        isApproved
                    )
                )
            ) {
                // error AccessDenied()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            // update balances of owner
            mstore(0, _from)
            mstore(32, _balances.slot)

            let ownerBalance := sload(keccak256(0, 64))

            sstore(keccak256(0, 64), sub(ownerBalance, 1))

            // update balances of receiver
            mstore(0, _to)
            mstore(32, _balances.slot)

            let receiverBalance := sload(keccak256(0, 64))

            sstore(keccak256(0, 64), add(receiverBalance, 1))

            // update owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            sstore(keccak256(0, 64), _to)

            // delete approval of the token
            mstore(0, _tokenId)
            mstore(32, _approvals.slot)

            sstore(keccak256(0, 64), 0)

            // emit Transfer event
            let transferSigHash :=
            0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
            log4(0, 0, transferSigHash, _from, _to, _tokenId)
        }
    }

    // =================== Internal functions ===================

    /// @notice mint a new token
    /// @dev emit Transfer event
    /// @param _to The new owner address.
    /// @param _tokenId The token ID.
    function _mint(address _to, uint256 _tokenId) internal virtual {
        assembly {
            if iszero(_to) {
                // error InvalidAddress()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            // update balances of receiver
            mstore(0, _to)
            mstore(32, _balances.slot)

            let receiverBalance := sload(keccak256(0, 64))

            sstore(keccak256(0, 64), add(receiverBalance, 1))

            // update owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            sstore(keccak256(0, 64), _to)

            // emit Transfer event
            let transferSigHash :=
            0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
            log4(0, 0, transferSigHash, 0, _to, _tokenId)
        }
    }

    /// @notice burn a token
    /// @dev emit Transfer event
    /// @param _tokenId The token ID.
    function _burn(uint256 _tokenId) internal virtual {
        assembly {
            // find owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            let owner := sload(keccak256(0, 64))

            // revert if token does not exist
            if iszero(owner) {
                // error NoTokenFound()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            if iszero(eq(caller(), owner)) {
                // error AccessDenied()
                mstore(0, 0xabcd)
                return(28, 4)
            }

            // update balances of owner
            mstore(0, owner)
            mstore(32, _balances.slot)

            let ownerBalance := sload(keccak256(0, 64))

            sstore(keccak256(0, 64), sub(ownerBalance, 1))

            // update owner of the token
            mstore(0, _tokenId)
            mstore(32, _owners.slot)

            sstore(keccak256(0, 64), 0)

            // emit Transfer event
            let transferSigHash :=
            0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
            log4(0, 0, transferSigHash, owner, 0, _tokenId)
        }
    }
}
