// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "./IERC20.sol";

/// @title ERC20 token standard
/// @author @dsam82 (Sambhav Dusad)
/// @author Copilot (comments)
/// @dev Explain to a developer any extra details
abstract contract ERC20 is IERC20 {
    // storage variables
    uint256 public totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowance;

    // metadata variables
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    // constructor
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @notice return balance of address
    /// @param _owner address whose balance is returned
    /// @return balance of address
    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    /// @notice returns allowance of spender for owner tokens
    /// @param _owner address who allows another address to spend _spendAmount of tokens
    /// @param _spender address who is allowed to spend _spendAmount of tokens
    /// @return allowance of spender by owner
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowance[_owner][_spender];
    }

    /// @notice allow _spender to spend _value of tokens
    /// @dev emit an approval event
    /// @param _spender address who is allowed to spend _value of tokens
    /// @param _value amount of tokens to be spent
    /// @return true if the operation was successful
    function approve(address _spender, uint256 _value)
        public
        virtual
        returns (bool)
    {
        require(_value <= balanceOf(msg.sender), "insufficient balance");

        _allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /// @notice transfer tokens from sender to receiver
    /// @dev emit Transfer event for successful transfer
    /// @param _to address to transfer tokens to
    /// @param _value amount of tokens to be transferred
    /// @return true if the operation was successful
    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, _to, _value);

        return true;
    }

    /// @notice transfer tokens from sender to receiver
    /// @dev emit Transfer event for transfer
    /// @param _from address to transfer tokens from
    /// @param _to address to transfer tokens to
    /// @param _value amount of tokens to be transferred
    /// @return true if the operation was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool) {
        uint256 allowed = allowance(_from, msg.sender);

        require(_value <= allowed, "insufficient allowance");

        _allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }

    // Internal functions (Burn/Mint)

    /// @notice internal function to transfer tokens
    /// @dev emit Transfer event for successful transfer
    /// @param _from address to transfer tokens from
    /// @param _to address to transfer tokens to
    /// @param _value amount of tokens to be transferred
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0), "invalid receiver");
        require(_value > 0, "invalid amount");

        require(balanceOf(_from) >= _value, "insufficient balance");

        unchecked {
            _balances[_from] -= _value;
            _balances[_to] += _value;
        }

        emit Transfer(_from, _to, _value);
    }

    /// @notice internal function to mint tokens
    /// @dev emit Transfer event on successful mint
    /// @param _to address to mint tokens to
    /// @param _totalSupply amount of tokens to be minted
    function _mint(address _to, uint256 _totalSupply) internal virtual {
        require(_to != address(0), "invalid receiver");
        require(_totalSupply > 0, "invalid supply of tokens");

        totalSupply = _totalSupply;

        unchecked {
            _balances[_to] = _totalSupply;
        }

        emit Transfer(address(0), _to, _totalSupply);
    }

    /// @notice internal function to burn tokens
    /// @dev emit Transfer event on successful burn
    /// @param _burnAmount amount of tokens to be burned
    function _burn(uint256 _burnAmount) internal virtual {
        require(_balances[msg.sender] >= _burnAmount, "insufficient balance");
        require(_burnAmount > 0, "invalid amount");

        unchecked {
            _balances[msg.sender] -= _burnAmount;
            totalSupply -= _burnAmount;
        }

        emit Transfer(msg.sender, address(0), _burnAmount);
    }
}
