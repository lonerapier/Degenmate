// SPDX-License-Identifier: Unlicense
pragma solidity >= 0.8.5;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "./ERC721.sol";

/// @title ERC721Enumerable
/// @author [@dsam82](https://github.com/dsam82)
/// @notice Extension of {ERC721} contract with enumerable functionality
/// on tokens owned by the account and all the tokens in the contract.
/// @dev Assumes tokenId starts from 1 and increments
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    address[] private _ownerByIndex;
    uint256[] private _ownerIndexByToken;
    mapping(address => uint256[]) private _ownedTokens;


    function totalSupply() public view virtual override returns (uint256) {
        return _ownerByIndex.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index > 0 && index <= balanceOf(owner), "owner index out of bounds");

        return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) public view virtual override
    returns (uint256) {
        require(index < totalSupply(), "index out of bounds");
        return index + 1;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0)) {
            uint256 index = _ownerIndexByToken[tokenId];
            uint256 lastTokenId = _ownedTokens[from][_ownedTokens[from].length - 1];

            delete _ownerByIndex[tokenId];
            if (index != _ownedTokens[from].length - 1) {
                _ownedTokens[from][index] = lastTokenId;
                _ownerIndexByToken[lastTokenId] = index;
            }
            delete _ownerIndexByToken[tokenId];
            _ownedTokens[from].pop();
        }

        if (to != address(0)) {
            _ownerByIndex[tokenId] = to;
            _ownedTokens[to].push(tokenId);
            _ownerIndexByToken[tokenId] = _ownedTokens[to].length;
        }
    }
}
