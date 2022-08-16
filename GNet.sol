// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

library ERC20Helper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20Helper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20Helper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERC20Helper: TRANSFER_FROM_FAILED');
    }
}

contract GNet is Ownable {
    address feeToken;
    address feeReceiver;
    uint feeAmount;

    struct Node{
        address pid;
        uint32 role;
        uint32 weight;
        string addr;
    }
    
    mapping(address => bool) appMap;
    address[] public apps;

    mapping(address => mapping(string => bool)) shardMap;
    mapping(address => string[]) shards;

    mapping(address => mapping(string => mapping(address => uint))) nodeMap;
    mapping(address => mapping(string => Node[])) nodes;

    constructor (address _token, address _receiver, uint _feeAmount) {
        feeToken = _token;
        feeReceiver = _receiver;
        feeAmount = _feeAmount;
    }

    event NewApp(address indexed sender);
    event CreateShard(address indexed sender, string name);
    event CreateNode(address indexed sender, address indexed pid, uint32 role, uint32 weight, string addr, string shard);
    event UpdateNode(address indexed sender, address indexed pid, uint32 role, uint32 weight, string addr, string shard);
    event DeleteNode(address indexed sender, address indexed pid, string shard);

    modifier onlyAppExist(){
        require(appMap[msg.sender] == true, "app_not_found");
        _;
    }

    modifier onlyAppNotExist(){
        require(appMap[msg.sender] == false, "app_already_exists");
        _;
    }
    
    modifier onlyShardExist(string calldata shardName){
        require(appMap[msg.sender] == true, "app_not_found");
        require(shardMap[msg.sender][shardName] == true, "shard_not_found");
        _;
    }

    modifier onlyShardNotExist(string calldata shardName){
        require(appMap[msg.sender] == true, "app_not_found");
        require(shardMap[msg.sender][shardName] == false, "shard_already_exists");
        _;
    }

    modifier onlyNodeExist(address pid, string calldata shardName){
        require(appMap[msg.sender] == true, "app_not_found");
        require(shardMap[msg.sender][shardName] == true, "shard_not_found");
        require(nodeMap[msg.sender][shardName][pid] > 0, "node_not_found");
        _;
    }
    modifier onlyNodeNotExist(address pid, string calldata shardName){
        require(appMap[msg.sender] == true, "app_not_found");
        require(shardMap[msg.sender][shardName] == true, "shard_not_found");
        require(nodeMap[msg.sender][shardName][pid] == 0, "node_already_exists");
        _;
    }

    function setFeeToken(address _token)public onlyOwner {
        feeToken = _token;
    }
    function setFeeReceiver(address _receiver)public onlyOwner{
        feeReceiver = _receiver;
    }

    function setFeeAmount(uint _feeAmount)public onlyOwner{
        feeAmount = _feeAmount;
    }

    function newApp() public onlyAppNotExist{
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        appMap[msg.sender] = true;
        apps.push(msg.sender);
        emit NewApp(msg.sender);
    }

    function createShard(string calldata name)public onlyShardNotExist(name){
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        shardMap[msg.sender][name] = true;
        shards[msg.sender].push(name);
        emit CreateShard(msg.sender, name);
    }

    function createNode(address pid, uint32 role, uint32 weight, string calldata addr, string calldata shardName) public onlyNodeNotExist(pid, shardName){
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        uint index = nodes[msg.sender][shardName].length;
        nodeMap[msg.sender][shardName][pid] = index + 1;
        Node memory node = Node(pid, role, weight, addr);
        nodes[msg.sender][shardName].push(node);
        emit CreateNode(msg.sender, pid, role, weight, addr, shardName);
    }

    function updateNode(address pid, uint32 role, uint32 weight, string calldata addr, string calldata shardName)public onlyNodeExist(pid, shardName) {
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        uint index = nodeMap[msg.sender][shardName][pid];
        nodes[msg.sender][shardName][index-1] = Node(pid, role, weight, addr);
        emit UpdateNode(msg.sender, pid, role, weight, addr, shardName);
    }

    function deleteNode(address pid, string calldata shardName)public onlyNodeExist(pid, shardName) {
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        uint index = nodeMap[msg.sender][shardName][pid] - 1;
        uint nodesLen =  nodes[msg.sender][shardName].length;
        if (nodesLen > 1){
            nodes[msg.sender][shardName][index] = nodes[msg.sender][shardName][nodesLen - 1];
        }
        nodes[msg.sender][shardName].pop();
        delete nodeMap[msg.sender][shardName][pid];
        emit DeleteNode(msg.sender, pid, shardName);
    }

    function getAppList()public view returns (address[] memory){
        return apps;
    }
    
    function getShardList()public view onlyAppExist returns(string[] memory){
        return shards[msg.sender];
    }

    function getNodeListByName(string calldata shardName)public view onlyShardExist(shardName) returns(Node[] memory){
        return nodes[msg.sender][shardName];
    }
}
