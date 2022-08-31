// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ERC721} from "../../ERC721/ERC721.sol";
import {DegenERC721} from "../../ERC721/DegenERC721.sol";

contract MockERC721 is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(address _to, uint256 _tokenId) public virtual {
        _mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) public virtual {
        _burn(_tokenId);
    }

    function safeMint(address _to, uint256 _tokenId) public virtual {
        _safeMint(_to, _tokenId);
    }

    function safeMint(
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual {
        _safeMint(_to, _tokenId, data);
    }
}

contract MockDegenERC721 is DegenERC721 {
    constructor(string memory _name, string memory _symbol)
        DegenERC721(_name, _symbol)
    {}

    function mint(address _to, uint256 _tokenId) public virtual {
        _mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) public virtual {
        _burn(_tokenId);
    }
}
