// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ERC1155 Token
/// @author Zartaj
/// @notice Simple free NFT contract
/// @dev Simple implementation of ERC1155

contract Joker is IERC1155 {
    /// @notice stores the basse URI which is later concatenated with token ID to get the token URI
    string baseUri;

    ///@notice assigns unique ids to each token. increments every time new token is minted
    uint256 tokenId;

    ///@notice owner of the contract
    address owner;

    ///@notice name and symbol
    string public name;
    string public symbol;

    ///@notice stores totalSupply of each token
    mapping(uint256 => uint256) private totalSupply;

///@notice stores maximum supply of each token
    mapping(uint256 => uint256) private Cap;
    mapping(uint256 => mapping(address => uint256)) private Balance;
    mapping(address => mapping(address => bool)) private OperatorApproval;
    mapping(uint256 => string) private Uri;
    mapping(uint256 => address) private isOwner;

    constructor(string memory _uri) {
        baseUri = _uri;
        owner = msg.sender;
        name = "Zartaj's collection";
        symbol = "ZAR";

        while (tokenId < 4) {
            mintNew(owner, 10, "", 20);
            isOwner[tokenId] = msg.sender;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getUri(uint256 _tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    function uri(uint256 _tokenId) external view returns (string memory) {
        string memory mappedUri = Uri[_tokenId];
        if (bytes(mappedUri).length > 0) {
            return mappedUri;
        } else {
            return getUri(_tokenId);
        }
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        require(account != address(0), "address is Invalid");
        return Balance[id][account];
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory)
    {
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

    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return OperatorApproval[account][operator];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "neither owner nor approved"
        );
        require(Balance[_id][_from] >= _amount, "Not enough balance");
        require(_to != address(0), "zero address");

        Balance[_id][_from] -= _amount;
        Balance[_id][_to] += _amount;

        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
        safeTransferCheck(msg.sender, _from, _to, _id, _amount, _data);
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

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            uint256 amount = _amounts[i];
            require(Balance[id][_from] >= amount, "Not enough balance");
            Balance[id][_from] -= amount;
            Balance[id][_to] += amount;
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
        SafeBatchTransferCheck(msg.sender, _from, _to, _ids, _amounts, data);
    }

    function mintNew(
        address _to,
        uint256 _amount,
        string memory _uri,
        uint256 maxSupply
    ) public {
        uint256 _tokenId = tokenId;
        Cap[_tokenId] = maxSupply;
        require(
            totalSupply[_tokenId] + _amount <= maxSupply,
            "Amount can't exceed maximum supply"
        );
        Balance[_tokenId][_to] += _amount;
        Uri[_tokenId] = _uri;
        totalSupply[_tokenId] += _amount;
        tokenId++;
        isOwner[_tokenId] = msg.sender;
        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
        emit URI(_uri, _tokenId);
    }

    function mintOld(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(msg.sender == isOwner[_tokenId], "Sender not the owner");
        require(
            totalSupply[_tokenId] + _amount <= Cap[_tokenId],
            "Amount can't exceed maximum supply"
        );
        require(_tokenId < tokenId, "token Id deosn't exists");

        Balance[_tokenId][_to] += _amount;
        totalSupply[_tokenId] += _amount;

        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
    }

    function burn(uint256 _tokenId, uint256 _amount) external {}

    function isContract(address _addr) private view returns (bool) {
        return _addr.code.length > 0;
    }

    function safeTransferCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function SafeBatchTransferCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }
}
