// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IERC1155, IERC1155Receiver} from "./IERC1155.sol";

abstract contract ERC1155 is IERC1155 {
    // ================= Custom Errors =================

    error InvalidLength();
    error InsufficientBalance();
    error Unauthorised();
    error UnsafeReceipient();

    // ================= Storage =================

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // ================= Metadata Logic =================

    function uri(uint256) public view virtual returns (string memory) {
        return "";
    }

    // ================= Public Functions =================

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256 len = _ids.length;

        if (len != _owners.length) revert InvalidLength();

        uint256[] memory result = new uint256[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                result[i] = balanceOf[_owners[i]][_ids[i]];
            }
        }
        return result;
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
    {
        isApprovedForAll[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) public virtual {
        if (msg.sender != _from && !isApprovedForAll[_from][msg.sender])
            revert Unauthorised();
        if (balanceOf[_from][_id] < _value) revert InsufficientBalance();

        unchecked {
            balanceOf[_from][_id] -= _value;
            balanceOf[_to][_id] += _value;
        }

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        if (
            _to.code.length == 0
                ? _to == address(0)
                : ERC1155Receiver(_to).onERC1155Received(
                    msg.sender,
                    _from,
                    _id,
                    _value,
                    _data
                ) != IERC1155Receiver.onERC1155Received.selector
        ) revert UnsafeReceipient();
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) public virtual {
        uint256 len = _ids.length;

        if (len != _values.length) revert InvalidLength();
        if (msg.sender != _from && !isApprovedForAll[_from][msg.sender])
            revert Unauthorised();

        for (uint256 i; i < len; ++i) {
            uint256 _id = _ids[i];

            if (balanceOf[_from][_id] < _values[i])
                revert InsufficientBalance();
            unchecked {
                balanceOf[_from][_id] -= _values[i];
                balanceOf[_to][_id] += _values[i];
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        if (
            _to.code.length == 0
                ? _to == address(0)
                : ERC1155Receiver(_to).onERC1155BatchReceived(
                    msg.sender,
                    _from,
                    _ids,
                    _values,
                    _data
                ) == IERC1155Receiver.onERC1155BatchReceived.selector
        ) revert UnsafeReceipient();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    // ================= Internal Functions =================

    function _mint(
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) internal virtual {
        unchecked {
            balanceOf[_to][_id] += _value;
        }

        emit TransferSingle(msg.sender, address(0), _to, _id, _value);

        if (
            _to.code.length == 0
                ? _to == address(0)
                : ERC1155Receiver(_to).onERC1155Received(
                    msg.sender,
                    address(0),
                    _id,
                    _value,
                    _data
                ) != IERC1155Receiver.onERC1155Received.selector
        ) revert UnsafeReceipient();
    }

    function _batchMint(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) internal virtual {
        uint256 len = _ids.length;

        if (len != _values.length) revert InvalidLength();

        unchecked {
            for (uint256 i; i < len; ++i) {
                balanceOf[_to][_ids[i]] += _values[i];
            }
        }

        emit TransferBatch(msg.sender, address(0), _to, _ids, _values);

        if (
            _to.code.length == 0
                ? _to == address(0)
                : ERC1155Receiver(_to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    _ids,
                    _values,
                    _data
                ) == IERC1155Receiver.onERC1155BatchReceived.selector
        ) revert UnsafeReceipient();
    }

    function _burn(uint256 _id, uint256 _value) internal virtual {
        if (balanceOf[msg.sender][_id] < _value) revert InsufficientBalance();

        unchecked {
            balanceOf[msg.sender][_id] -= _value;
        }

        emit TransferSingle(msg.sender, msg.sender, address(0), _id, _value);
    }

    function _batchBurn(uint256[] calldata _ids, uint256[] calldata _values)
        internal
        virtual
    {
        uint256 len = _ids.length;

        if (len != _values.length) revert InvalidLength();

        for (uint256 i; i < len; ++i) {
            if (balanceOf[msg.sender][_ids[i]] < _values[i])
                revert InsufficientBalance();
        }

        unchecked {
            for (uint256 i; i < len; ++i) {
                balanceOf[msg.sender][_ids[i]] -= _values[i];
            }
        }

        emit TransferBatch(msg.sender, msg.sender, address(0), _ids, _values);
    }
}

abstract contract ERC1155Receiver is IERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure virtual returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}
