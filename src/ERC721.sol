// https://eips.ethereum.org/EIPS/eip-721, http://erc721.org/
// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.5;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

/** @title ERC721
 * @author [@dsam82](https://github.com/dsam82)
 * @notice Implmentation of ERC721 contract using rari-capital/solmate
 * and OZs 721 implementation
 * @dev Explain to a developer any extra details
 */
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

    function _transfer (address _from, address _to, uint256 _tokenId) internal virtual _validAddress(_to) {
        require(_from == _owners[_tokenId], "not the owner");

        _beforeTokenTransfer(_from, _to, _tokenId);

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

    function transferFrom (address _from, address _to, uint256 _tokenId) public virtual override _exists(_tokenId) {
        require(_isOwnerOrApproved(msg.sender, _tokenId), "access denied");

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom (address _from, address _to, uint256 _tokenId) public virtual override _exists(_tokenId) {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public virtual override _exists(_tokenId) {
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

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual {}
}
