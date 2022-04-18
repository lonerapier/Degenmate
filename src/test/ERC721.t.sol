// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {ERC721, IERC721Receiver} from "../ERC721/ERC721.sol";

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

contract MockERC721User is IERC721Receiver {
    ERC721 token;

    constructor(ERC721 _token) {
        token = _token;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function approve(address _approved, uint256 _tokenId) public virtual {
        token.approve(_approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
    {
        token.setApprovalForAll(_operator, _approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        token.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        token.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        token.safeTransferFrom(from, to, tokenId, data);
    }
}

contract ERC721Recipient is IERC721Receiver {
    address public operator;
    address public from;
    uint256 public tokenId;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        tokenId = _tokenId;
        data = _data;

        return IERC721Receiver.onERC721Received.selector;
    }
}

contract ERC721Test is DSTestPlus {
    MockERC721 token;
    address constant sampleAdd = address(0xABC);
    uint256 constant tokenId = 786;

    function setUp() public {
        token = new MockERC721("LetsFuckingGo!", "LFG");
    }

    function testMetadata(string memory tokenName, string memory tokenSymbol)
        public
    {
        MockERC721 sampleToken = new MockERC721(tokenName, tokenSymbol);
        assertEq(sampleToken.name(), tokenName);
        assertEq(sampleToken.symbol(), tokenSymbol);
    }

    function testMint() public {
        token.mint(sampleAdd, tokenId);

        assertEq(token.balanceOf(sampleAdd), 1);
        assertEq(token.ownerOf(tokenId), sampleAdd);
    }

    // @dev this should fail as msg.sender is not owner or approved
    function testBurn() public {
        token.mint(sampleAdd, tokenId);
        vm.prank(sampleAdd);
        token.burn(tokenId);

        assertEq(token.balanceOf(sampleAdd), 0);
        assertEq(token.ownerOf(tokenId), address(0));
    }

    function testSelfApprove() public {
        token.mint(address(this), tokenId);

        token.approve(sampleAdd, tokenId);

        assertEq(token.getApproved(tokenId), sampleAdd);
    }

    function testSelfApproveBurn() public {
        token.mint(address(this), tokenId);

        token.approve(sampleAdd, tokenId);

        token.burn(tokenId);

        assertEq(token.ownerOf(tokenId), address(0));
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.getApproved(tokenId), address(0));
    }

    function testSelfApproveAll() public {
        token.setApprovalForAll(sampleAdd, true);

        assertTrue(token.isApprovedForAll(address(this), sampleAdd));
    }

    function testTransferFrom() public {
        MockERC721User mockUser = new MockERC721User(token);

        token.mint(address(mockUser), tokenId);

        mockUser.approve(address(this), tokenId);

        mockUser.transferFrom(address(mockUser), sampleAdd, tokenId);
        assertEq(token.ownerOf(tokenId), sampleAdd);
        assertEq(token.balanceOf(sampleAdd), 1);
    }

    function testTransferFromSelf() public {
        token.mint(address(this), tokenId);

        token.transferFrom(address(this), sampleAdd, tokenId);

        assertEq(token.ownerOf(tokenId), sampleAdd);
        assertEq(token.balanceOf(sampleAdd), 1);
        assertEq(token.balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        MockERC721User mockUser = new MockERC721User(token);

        token.mint(address(mockUser), tokenId);

        mockUser.setApprovalForAll(address(this), true);

        token.transferFrom(address(mockUser), sampleAdd, tokenId);

        assertEq(token.getApproved(tokenId), address(0));
        assertEq(token.ownerOf(tokenId), sampleAdd);
        assertEq(token.balanceOf(sampleAdd), 1);
        assertEq(token.balanceOf(address(mockUser)), 0);
    }

    function testSafeTransferFromToEOA() public {
        MockERC721User mockUser = new MockERC721User(token);

        token.mint(address(mockUser), tokenId);

        mockUser.setApprovalForAll(address(this), true);

        token.safeTransferFrom(address(mockUser), sampleAdd, tokenId);

        assertEq(token.getApproved(tokenId), address(0));
        assertEq(token.ownerOf(tokenId), sampleAdd);
        assertEq(token.balanceOf(sampleAdd), 1);
        assertEq(token.balanceOf(address(mockUser)), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        MockERC721User mockUser = new MockERC721User(token);
        ERC721Recipient ercRecipient = new ERC721Recipient();

        token.mint(address(mockUser), tokenId);

        mockUser.setApprovalForAll(address(this), true);

        token.safeTransferFrom(
            address(mockUser),
            address(ercRecipient),
            tokenId
        );

        assertEq(token.getApproved(tokenId), address(0));
        assertEq(token.ownerOf(tokenId), address(ercRecipient));
        assertEq(token.balanceOf(address(ercRecipient)), 1);
        assertEq(token.balanceOf(address(mockUser)), 0);

        assertEq(ercRecipient.operator(), address(this));
        assertEq(ercRecipient.from(), address(mockUser));
        assertEq(ercRecipient.tokenId(), tokenId);
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        MockERC721User mockUser = new MockERC721User(token);
        ERC721Recipient ercRecipient = new ERC721Recipient();

        token.mint(address(mockUser), tokenId);

        mockUser.setApprovalForAll(address(this), true);

        token.safeTransferFrom(
            address(mockUser),
            address(ercRecipient),
            tokenId,
            "nft safe transfer"
        );

        assertEq(token.getApproved(tokenId), address(0));
        assertEq(token.ownerOf(tokenId), address(ercRecipient));
        assertEq(token.balanceOf(address(ercRecipient)), 1);
        assertEq(token.balanceOf(address(mockUser)), 0);

        assertEq(ercRecipient.operator(), address(this));
        assertEq(ercRecipient.from(), address(mockUser));
        assertEq(ercRecipient.tokenId(), tokenId);
        assertEq(bytes32(ercRecipient.data()), bytes32("nft safe transfer"));
    }

    function testSafeMintToEOA() public {
        token.safeMint(sampleAdd, tokenId);

        assertEq(token.ownerOf(tokenId), sampleAdd);
        assertEq(token.balanceOf(sampleAdd), 1);
    }

    function testSafeMintToERC721Recipient() public {
        ERC721Recipient ercRecipient = new ERC721Recipient();

        token.safeMint(address(ercRecipient), tokenId);

        assertEq(token.ownerOf(tokenId), address(ercRecipient));
        assertEq(token.balanceOf(address(ercRecipient)), 1);

        assertEq(ercRecipient.operator(), address(this));
        assertEq(ercRecipient.from(), address(0));
        assertEq(ercRecipient.tokenId(), tokenId);
    }

    function testSafeMintToERC721RecipientWithData() public {
        ERC721Recipient ercRecipient = new ERC721Recipient();

        token.safeMint(address(ercRecipient), tokenId, "nft safe mint");

        assertEq(token.ownerOf(tokenId), address(ercRecipient));
        assertEq(token.balanceOf(address(ercRecipient)), 1);

        assertEq(ercRecipient.operator(), address(this));
        assertEq(ercRecipient.from(), address(0));
        assertEq(ercRecipient.tokenId(), tokenId);
        assertEq(bytes32(ercRecipient.data()), bytes32("nft safe mint"));
    }

    function testFailMintToZero() public {
        token.mint(address(0), tokenId);
    }
}
