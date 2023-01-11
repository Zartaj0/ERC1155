// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Joker is IERC1155 {
    string baseUri;
    uint tokenId;
    address owner;
    string public name;
    string public symbol;

    mapping(uint => uint) private totalSupply;
    mapping(uint => uint) private Cap;
    mapping(uint => mapping(address => uint)) private Balance;
    mapping(address => mapping(address => bool)) private OperatorApproval;
    mapping(uint => string) private Uri;

    constructor(string memory _uri) {
        baseUri = _uri;
        owner = msg.sender;
        name = "Zartaj's collection";
        symbol = "ZAR";

        while (tokenId < 4) {
            mintNew(owner, 10, "", 20);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getUri(uint _tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    function uri(uint _tokenId) external view returns (string memory) {
        string memory mappedUri = Uri[_tokenId];
        if (bytes(mappedUri).length > 0) {
            return mappedUri;
        } else {
            return getUri(_tokenId);
        }
    }

    function balanceOf(
        address account,
        uint256 id
    ) public view returns (uint256) {
        require(account != address(0), "address is Invalid");
        return Balance[id][account];
    }

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalance = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalance[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalance;
    }

    function setApprovalForAll(address operator, bool approved) external {
        OperatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view returns (bool) {
        return OperatorApproval[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "neither owner nor approved"
        );
        require(Balance[id][from] >= amount, "Not enough balance");
        require(to != address(0), "zero address");

        Balance[id][from] -= amount;
        Balance[id][to] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes calldata data
    ) external {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "neither owner nor approved"
        );
        require(_to != address(0), "zero address");

        require(
            _ids.length == _amounts.length,
            "ids and amounts array length should be same"
        );

        for (uint i = 0; i < _ids.length; i++) {
            uint id = _ids[i];
            uint amount = _amounts[i];
            require(Balance[id][_from] >= amount, "Not enough balance");
            Balance[id][_from] -= amount;
            Balance[id][_to] += amount;
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function mintNew(
        address _to,
        uint _amount,
        string memory _uri,
        uint maxSupply
    ) public {
        uint _tokenId = tokenId;
        Cap[_tokenId] = maxSupply;
        require(
            totalSupply[_tokenId] + _amount <= maxSupply,
            "Amount can't exceed maximum supply"
        );
        Balance[_tokenId][_to] += _amount;
        Uri[_tokenId] = _uri;
        totalSupply[_tokenId] += _amount;
        tokenId++;
        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
        emit URI(_uri, _tokenId);
    }

    function mintOld(address _to, uint _tokenId, uint _amount) public {
        require(
            totalSupply[_tokenId] + _amount <= Cap[_tokenId],
            "Amount can't exceed maximum supply"
        );
        require(_tokenId < tokenId, "token Id deosn't exists");

        Balance[_tokenId][_to] += _amount;
        totalSupply[_tokenId] += _amount;

        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
    }
}
