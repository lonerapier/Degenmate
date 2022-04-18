// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

contract MultiSigWallet {
    struct Transaction {
        uint32 id;
        address to;
        address submittedBy;
        uint256 amount;
        uint256 numConfirmations;
        uint256 numRejections;
        bool isExecuted;
    }

    uint256 public numConfirmationsRequired;
    address[] public owners;
    mapping(address => bool) private isOwner;
    mapping(uint256 => mapping(address => bool)) public isApproved;
    Transaction[] private txs;

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransactionEvent(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event ApproveTransactionEvent(
        address indexed owner,
        uint32 indexed txIndex
    );
    event ExecuteTransactionEvent(
        address indexed owner,
        uint32 indexed txIndex
    );
    event RejectTransactionEvent(address indexed owner, uint32 indexed txIndex);
    event ExecutableTransaction(uint32 indexed txIndex);

    /// @dev function to receive ether into the contract
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// @dev modifier to access control
    modifier onlyOwner() {
        require(isOwner[msg.sender] == true, "not an owner");
        _;
    }

    modifier isValidTransaction(uint32 _txId) {
        require(_txId < txs.length, "invalid tx");
        _;
    }

    modifier isActiveTransaction(uint32 _txId) {
        require(
            txs[_txId].numRejections < numConfirmationsRequired,
            "rejected tx"
        );
        _;
    }

    modifier notAlreadyApprovedTransaction(uint32 _txId) {
        require(
            !isApproved[_txId][msg.sender],
            "can't approve an already approved tx"
        );
        _;
    }

    modifier notExecuted(uint32 _txId) {
        require(!txs[_txId].isExecuted, "already executed");
        _;
    }

    constructor(address[] memory _owners) {
        require(_owners.length > 0, "invalid owners length");

        uint256 len = _owners.length;
        for (uint256 i = 0; i < len; i++) {
            require(!isOwner[_owners[i]], "owner already present");
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }

        if (_owners.length > 1) {
            numConfirmationsRequired = (_owners.length * 2) / 3;
        } else {
            numConfirmationsRequired = 1;
        }
    }

    function submitTransaction(address _to, uint256 _amount) public {
        require(_amount <= address(this).balance, "insufficient balance");

        uint32 txId = uint32(txs.length) + 1;
        txs.push(Transaction(txId, _to, msg.sender, _amount, 0, 0, false));
        emit SubmitTransactionEvent(msg.sender, _to, _amount);

        if (isOwner[msg.sender]) {
            approveTransaction(txId);
        }
    }

    function approveTransaction(uint32 _txId)
        public
        onlyOwner
        isValidTransaction(_txId)
        isActiveTransaction(_txId)
        notAlreadyApprovedTransaction(_txId)
        notExecuted(_txId)
    {
        isApproved[_txId][msg.sender] = true;
        txs[_txId].numConfirmations++;

        emit ApproveTransactionEvent(msg.sender, _txId);

        if (txs[_txId].numConfirmations >= numConfirmationsRequired) {
            emit ExecutableTransaction(_txId);
        }
    }

    function rejectTransaction(uint32 _txId)
        public
        onlyOwner
        isValidTransaction(_txId)
        isActiveTransaction(_txId)
        notAlreadyApprovedTransaction(_txId)
        notExecuted(_txId)
    {
        isApproved[_txId][msg.sender] = false;
        txs[_txId].numRejections++;

        emit RejectTransactionEvent(msg.sender, _txId);
    }

    function executeTransaction(uint32 _txId)
        public
        onlyOwner
        isValidTransaction(_txId)
        isActiveTransaction(_txId)
        notExecuted(_txId)
        returns (bool)
    {
        require(
            txs[_txId].numConfirmations >= numConfirmationsRequired,
            "not executable"
        );

        address payable _to = payable(txs[_txId].to);
        (bool success, ) = _to.call{value: txs[_txId].amount}("");
        if (success) {
            txs[_txId].isExecuted = true;
            emit ExecuteTransactionEvent(msg.sender, _txId);
        }

        return success;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransaction(uint32 _txId)
        public
        view
        isValidTransaction(_txId)
        returns (
            address to,
            address submittedBy,
            uint256 amount,
            uint256 numConfirmations,
            uint256 numRejections,
            bool isExecuted
        )
    {
        Transaction storage txx = txs[_txId];

        return (
            txx.to,
            txx.submittedBy,
            txx.amount,
            txx.numConfirmations,
            txx.numRejections,
            txx.isExecuted
        );
    }
}
