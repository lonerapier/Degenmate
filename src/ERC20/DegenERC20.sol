// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title DegenERC20
/// @author @dsam82
/// @dev ERC20 Token standarad in assembly
abstract contract DegenERC20 {
    // transferSigHash: 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
    // allowanceSigHash: 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925

    // =================== Private Variables ===================

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // =================== Public Variables ====================

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // =================== Constructor ==========================

    constructor(
        string memory __name,
        string memory __symbol,
        uint8 __decimals
    ) {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    // =================== Metadata Functions ======================

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

    /// @notice Get the number of decimals of the token.
    /// @return The number of decimals of the token.
    function decimals() public view returns (uint8) {
        assembly {
            // load slot value to memory
            mstore(0, and(0xff, sload(_decimals.slot)))

            // return mem[0:32]
            return(0, 32)
        }
    }

    // =================== Public Functions ======================

    /// @notice Get balance of an address
    /// @param account The address to query the balance of.
    /// @return ptr The amount of tokens owned by the address.
    function balanceOf(address account) public view returns (uint256 ptr) {
        assembly {
            // load free memory pointer
            ptr := mload(0x40)

            // find hashed value slot i.e. keccak256(account+slot)

            // load account to memory
            mstore(0, account)
            // load slot to memory
            mstore(32, _balances.slot)
            // hash the slot and account
            let slot := keccak256(0, 64)

            // load slot value to memory
            mstore(ptr, sload(slot))

            // return mem[ptr:ptr+32]
            return(ptr, 32)
        }
    }

    /// @notice get total supply of the token
    /// @return ptr total supply of the token.
    function totalSupply() public view returns (uint256 ptr) {
        assembly {
            // load free memory pointer
            ptr := mload(0x40)

            // load slot to memory
            mstore(ptr, sload(_totalSupply.slot))

            // return mem[ptr:ptr+32]
            return(ptr, 32)
        }
    }

    /// @notice get allowances of spender on behalf of owner
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @return The amount of tokens the spender is allowed to spend on behalf of the owner.
    function allowances(address owner, address spender)
        public
        view
        returns (uint256)
    {
        assembly {
            // find hashed slot i.e. keccak256(spender + keccak256(owner + allowanceSlot))
            mstore(0, owner)
            mstore(32, _allowances.slot)
            let ownerSlot := keccak256(0, 64)

            mstore(0, spender)
            mstore(32, ownerSlot)
            let spenderSlot := keccak256(0, 64)

            // load slot value to memory
            mstore(0, sload(spenderSlot))

            // return mem[0:32]
            return(0, 32)
        }
    }

    /// @notice approve spender to spend amount of tokens on behalf of owner
    /// @param spender The address of the spender.
    /// @param amount The amount of tokens to be approved.
    function approve(address spender, uint256 amount) public {
        assembly {
            // find hashed slot i.e. keccak256(spender + keccak256(msg.sender + allowanceSlot))
            mstore(0, caller())
            mstore(32, _allowances.slot)
            let ownerSlot := keccak256(0, 64)

            mstore(0, spender)
            mstore(32, ownerSlot)
            let spenderSlot := keccak256(0, 64)

            // load slot value to memory
            sstore(spenderSlot, add(sload(spenderSlot), amount))

            let
                approveSigHash
            := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925

            mstore(0, amount)

            // emit approve event
            log3(0, 32, approveSigHash, caller(), spender)
        }
    }

    /// @notice transfer amount of tokens to recipient
    /// @param recipient The address of the recipient.
    /// @param amount The amount of tokens to be transferred.
    /// @return True if the transfer was successful.
    function transfer(address recipient, uint256 amount) public returns (bool) {
        assembly {
            // check balance of sender > amount

            // find hashed slot i.e. keccak256(msg.sender + balancesSlot)
            mstore(0, caller())
            mstore(32, _balances.slot)
            let senderSlot := keccak256(0, 64)

            // load slot value to memory
            let senderBalance := sload(senderSlot)

            // check if sender balance is greater than amount
            if gt(amount, senderBalance) {
                // bytes4(keccak256("InsufficientBalance()"))
                mstore(0, 0xf4d678b8)
                revert(28, 4)
            }

            sstore(senderSlot, sub(senderBalance, amount))

            // find hashed slot i.e. keccak256(recipient + balancesSlot)

            // load recipient to memory
            mstore(0, recipient)
            mstore(32, _balances.slot)
            let recipientSlot := keccak256(0, 64)

            // load slot value to memory
            let recipientBalance := sload(recipientSlot)

            // store new balance
            sstore(recipientSlot, add(recipientBalance, amount))

            mstore(0, amount)

            // emit transfer event
            log3(
                0,
                32,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                caller(),
                recipient
            )

            // return true
            mstore(0, 1)
            return(0, 32)
        }
    }

    /// @notice transfer amount of tokens from one address to another
    /// @param spender The address to transfer from.
    /// @param recipient The address to transfer to.
    /// @param amount The amount of tokens to be transferred.
    /// @return True if the transfer was successful.
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        assembly {
            // check balance of spender > amount

            mstore(0, spender)
            mstore(32, _balances.slot)
            let spenderSlot := keccak256(0, 64)

            // load slot value to memory
            let spenderBalance := sload(spenderSlot)

            // check if spender balance is greater than amount
            if gt(amount, spenderBalance) {
                // bytes4(keccak256("InsufficientBalance()"))
                mstore(0, 0xf4d678b8)
                revert(28, 4)
            }

            // check allowance if caller != spender
            if iszero(eq(caller(), spender)) {
                // find hashed slot i.e. keccak256(spender + keccak256(caller + allowanceSlot))
                mstore(0, spender)
                mstore(32, _allowances.slot)
                let spenderAllowanceSlot := keccak256(0, 64)

                mstore(0, caller())
                mstore(32, spenderAllowanceSlot)
                let callerAllowanceSlot := keccak256(0, 64)

                // load slot value to memory
                let callerAllowance := sload(callerAllowanceSlot)

                // check if caller allowance is greater than amount
                if gt(amount, callerAllowance) {
                    // bytes4(keccak256("InsufficientAllowance()"))
                    mstore(0, 0x13be252b)
                    revert(28, 4)
                }

                // store new allowance
                sstore(callerAllowanceSlot, sub(callerAllowance, amount))
            }

            // store new balance
            sstore(spenderSlot, sub(spenderBalance, amount))

            // find hashed slot i.e. keccak256(recipient + balancesSlot)
            mstore(0, recipient)
            mstore(32, _balances.slot)
            let recipientSlot := keccak256(0, 64)

            // load slot value to memory
            let recipientBalance := sload(recipientSlot)

            // store new balance
            sstore(recipientSlot, add(recipientBalance, amount))

            // emit transfer event
            mstore(0, amount)
            log3(
                0,
                32,
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                caller(),
                recipient
            )

            // return true
            mstore(0, 1)
            return(0, 32)
        }
    }

    // =================== Internal Functions ====================

    /// @notice mint new tokens
    /// @param account The address to mint the tokens to.
    /// @param amount The amount of tokens to mint.
    function _mint(address account, uint256 amount) internal {
        assembly {
            // revert zero account mint
            if iszero(account) {
                // 0xe6c4247b: bytes4(keccak256("InvalidAddress()"))
                mstore(0, 0xe6c4247b)

                // return mem[28:32]
                revert(28, 4)
            }

            // find hashed value slot i.e. keccak256(account+slot)
            mstore(0, account)
            mstore(32, _balances.slot)
            let accountSlot := keccak256(0, 64)

            // old total supply
            let oldSupply := sload(_totalSupply.slot)

            // new total supply
            let newSupply := add(oldSupply, amount)

            // check for overflow
            if or(lt(newSupply, oldSupply), lt(newSupply, amount)) {
                // abi.encodeWithSignature("Panic(uint256)", 0x11);
                mstore(0, 0x4e487b71)
                mstore(32, 0x11)

                // return mem[28:64]
                revert(28, 36)
            }

            // update totalSupply to totalSupply + amount
            sstore(_totalSupply.slot, newSupply)

            // update balance to value + amount
            sstore(accountSlot, add(amount, sload(accountSlot)))

            // transfer sig hash
            let
                sigHash
            := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

            mstore(0, amount)

            // emit Transfer(address indexed from, address indexed to, uint256 value)
            log3(0, 32, sigHash, caller(), account)
        }
    }

    /// @notice burn tokens
    /// @param amount The amount of tokens to burn.
    function _burn(uint256 amount) internal {
        assembly {
            // find account slot i.e. keccak256(caller+slot)
            mstore(0, caller())
            mstore(32, _balances.slot)
            let accountSlot := keccak256(0, 64)

            // current balance
            let oldBalance := sload(accountSlot)

            // revert if balance too low
            if lt(oldBalance, amount) {
                // bytes4(keccak256("InsufficientBalance()"))
                mstore(0, 0xf4d678b8)
                revert(28, 4)
            }

            // update balance to value - amount
            sstore(accountSlot, sub(oldBalance, amount))

            // update totalSupply to totalSupply - amount
            sstore(_totalSupply.slot, sub(sload(_totalSupply.slot), amount))

            // transfer sig hash
            let
                sigHash
            := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

            mstore(0, amount)

            // emit Transfer(address indexed from, address indexed to, uint256 value)
            log3(0, 32, sigHash, caller(), 0)
        }
    }
}
