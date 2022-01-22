// https://eips.ethereum.org/EIPS/eip-721, http://erc721.org/
// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 is IERC165 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title ERC721 Implementation
/// @author @dsam82
/// @notice Implmentation of ERC721 contract using rari-capital/solmate
/// and OZs 721 implementation
/// @dev Explain to a developer any extra details
abstract contract ERC721 is IERC165, IERC721, IERC721Metadata {

    string private _name;

    string private _symbol;

    mapping (uint256 => address) private _owners;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => bool)) private _isApprovedForAll;

    mapping(uint256 => address) _approvals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public pure virtual returns (string memory) {
        return "";
    }

    modifier _exists(uint256 _tokenId) {
        require(_owners[_tokenId] != address(0), "not yet minted");
        _;
    }

    modifier _validAddress(address _owner) {
        require(_owner != address(0), "invalid owner");
        _;
    }

    function _isOwnerOrApproved(address spender, uint256 tokenId) internal view virtual returns (bool) {
        return spender == _owners[tokenId] || spender == _approvals[tokenId] || _isApprovedForAll[_owners[tokenId]][spender];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return _owners[_tokenId];
    }

    function balanceOf(address _owner) public view _validAddress(_owner) returns (uint256) {
        return _balances[_owner];
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
        interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId;
    }

    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        return _isApprovedForAll[_owner][_operator];
    }

    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        return _approvals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public virtual override _validAddress(_operator) {
        require (msg.sender != _operator, "approval to caller");

        _isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function approve(address _approved, uint256 _tokenId) public virtual override {
        require(_approved != address(0), "invalid approval");
        require(_isOwnerOrApproved(msg.sender, _tokenId), "access denied");

        _approvals[_tokenId] = _approved;

        emit Approval(msg.sender, _approved, _tokenId);
    }

    function _transfer (address _from, address _to, uint256 _tokenId) internal virtual {
        require(_from == _owners[_tokenId], "not the owner");

        unchecked {
            _balances[_from]--;
            _balances[_to]++;
        }

        _owners[_tokenId] = _to;

        delete _approvals[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransfer (address _from, address _to, uint256 _tokenId, bytes memory data) internal virtual {
        _transfer(_from, _to, _tokenId);

        require(_checkOnERC721Received(_from, _to, _tokenId, data), "recipient not safe");
    }

    function transferFrom (address _from, address _to, uint256 _tokenId) public virtual override payable _exists(_tokenId) _validAddress(_to) {
        require(_isOwnerOrApproved(msg.sender, _tokenId), "access denied");

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom (address _from, address _to, uint256 _tokenId) public virtual override _exists(_tokenId) _validAddress(_to) {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public virtual override _exists(_tokenId) _validAddress(_to) {
        require(_isOwnerOrApproved(msg.sender, _tokenId), "access denied");

        _safeTransfer(_from, _to, _tokenId, data);
    }

    function _safeMint(address _to, uint256 _tokenId) internal virtual {
        _safeMint(_to, _tokenId, "");
    }

    function _safeMint(address _to, uint256 _tokenId, bytes memory data) internal virtual {
        _mint(_to, _tokenId);

        require(_checkOnERC721Received(address(0), _to, _tokenId, data), "recipient not safe");
    }

    function _mint(address _to, uint256 _tokenId) internal virtual _validAddress(_to) {
        require(_owners[_tokenId] == address(0), "already minted");

        unchecked {
            _balances[_to]++;
        }

        _owners[_tokenId] = _to;

        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal virtual {
        address owner = _owners[_tokenId];
        require(owner != address(0), "not minted yet");

        require(_isOwnerOrApproved(msg.sender, _tokenId), "not owner or approved");

        unchecked {
            _balances[owner]--;
        }

        delete _owners[_tokenId];
        delete _approvals[_tokenId];

        emit Transfer(owner, address(0), _tokenId);
    }

    function _checkOnERC721Received(address operator, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        return (
            to.code.length == 0 ||
            IERC721Receiver(to).onERC721Received(msg.sender, operator, tokenId, data) == IERC721Receiver.onERC721Received.selector);
    }
}

/// @title IERC721Receiver
/// @notice Any receiver must implement this to be a valid user to receive
/// an ERC721 token.
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data)
        external returns (bytes4);
}
