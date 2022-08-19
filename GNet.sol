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
    address private feeToken;
    address private feeReceiver;
    uint private feeAmount;

    struct Node{
        address pid;
        uint32 role;
        uint32 weight;
        string addr;
    }
    
    mapping(address => bool) private appMap;
    address[] public apps;

    mapping(address => mapping(bytes32 => bool)) private zoneMap;
    mapping(address => bytes32[]) zones;

    mapping(address => mapping(bytes32 => mapping(bytes32 => bool))) private shardMap;
    mapping(address => mapping(bytes32 => bytes32[])) private shards;

    mapping(address => mapping(bytes32 => mapping(bytes32 => mapping(address => uint)))) private nodeMap;
    mapping(address => mapping(bytes32 => mapping(bytes32 => Node[]))) private nodes;

    constructor (address _feeToken, address _feeReceiver, uint _feeAmount) {
        feeToken = _feeToken;
        feeReceiver = _feeReceiver;
        feeAmount = _feeAmount;
    }

    event NewApp(address indexed sender);
    event CreateZone(address indexed sender, bytes32 name);
    event CreateShard(address indexed sender, bytes32 zone, bytes32 name);
    event CreateNode(address indexed sender, bytes32 zone, bytes32 shard, address indexed pid, uint32 role, uint32 weight, string addr);
    event UpdateNode(address indexed sender, bytes32 zone, bytes32 shard, address indexed pid, uint32 role, uint32 weight, string addr);
    event DeleteNode(address indexed sender, bytes32 zone, bytes32 shard, address indexed pid);

    modifier onlyAppExist(address app){
        require(appMap[app] == true, "app_not_found");
        _;
    }

    modifier onlyAppNotExist(address app){
        require(appMap[app] == false, "app_already_exists");
        _;
    }
    
    modifier onlyZoneExist(address app, bytes32 zone){
        require(appMap[app] == true, "app_not_found");
        require(zoneMap[app][zone] == true, "zone_not_found");
        _;
    }

    modifier onlyZoneNotExist(address app, bytes32 zone){
        require(appMap[app] == true, "app_not_found");
        require(zoneMap[app][zone] == false, "zone_already_exists");
        _;
    }

    modifier onlyShardExist(address app, bytes32 zone, bytes32 shard){
        require(appMap[app] == true, "app_not_found");
        require(zoneMap[app][zone] == true, "zone_not_found");
        require(shardMap[app][zone][shard] == true, "shard_not_found");
        _;
    }

    modifier onlyShardNotExist(address app, bytes32 zone, bytes32 shard){
        require(appMap[app] == true, "app_not_found");
        require(zoneMap[app][zone] == true, "zone_not_found");
        require(shardMap[app][zone][shard] == false, "shard_already_exists");
        _;
    }

    modifier onlyNodeExist(address app, bytes32 zone, bytes32 shard, address pid){
        require(appMap[app] == true, "app_not_found");
        require(zoneMap[app][zone] == true, "zone_not_found");
        require(shardMap[app][zone][shard] == true, "shard_not_found");
        require(nodeMap[app][zone][shard][pid] > 0, "node_not_found");
        _;
    }
    modifier onlyNodeNotExist(address app, bytes32 zone, bytes32 shard, address pid){
        require(appMap[app] == true, "app_not_found");
        require(zoneMap[app][zone] == true, "zone_not_found");
        require(shardMap[app][zone][shard] == true, "shard_not_found");
        require(nodeMap[app][zone][shard][pid] == 0, "node_already_exists");
        _;
    }

    function setFeeToken(address _feeToken)public onlyOwner {
        feeToken = _feeToken;
    }
    function setFeeReceiver(address _feeReceiver)public onlyOwner{
        feeReceiver = _feeReceiver;
    }

    function setFeeAmount(uint _feeAmount)public onlyOwner{
        feeAmount = _feeAmount;
    }

    function newApp() public onlyAppNotExist(msg.sender){
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        appMap[msg.sender] = true;
        apps.push(msg.sender);
        emit NewApp(msg.sender);
    }

    function createZone(bytes32 name)public onlyZoneNotExist(msg.sender, name){
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        zoneMap[msg.sender][name] = true;
        zones[msg.sender].push(name);
        emit CreateZone(msg.sender, name);
    }

    function createShard(bytes32 zone, bytes32 name)public onlyShardNotExist(msg.sender, zone, name){
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        shardMap[msg.sender][zone][name] = true;
        shards[msg.sender][zone].push(name);
        emit CreateShard(msg.sender, zone, name);
    }

    function createNode(bytes32 zone, bytes32 shard, address pid, uint32 role, uint32 weight, string calldata addr) public onlyNodeNotExist(msg.sender, zone, shard, pid){
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        uint index = nodes[msg.sender][zone][shard].length;
        nodeMap[msg.sender][zone][shard][pid] = index + 1;
        Node memory node = Node(pid, role, weight, addr);
        nodes[msg.sender][zone][shard].push(node);
        emit CreateNode(msg.sender, zone, shard, pid, role, weight, addr);
    }

    function updateNode(bytes32 zone, bytes32 shard, address pid, uint32 role, uint32 weight, string calldata addr)public onlyNodeExist(msg.sender, zone, shard, pid) {
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        uint index = nodeMap[msg.sender][zone][shard][pid];
        nodes[msg.sender][zone][shard][index-1] = Node(pid, role, weight, addr);
        emit UpdateNode(msg.sender, zone, shard, pid, role, weight, addr);
    }

    function deleteNode(bytes32 zone, bytes32 shard, address pid)public onlyNodeExist(msg.sender, zone, shard, pid) {
        ERC20Helper.safeTransferFrom(feeToken, msg.sender, feeReceiver, feeAmount);
        uint index = nodeMap[msg.sender][zone][shard][pid] - 1;
        uint nodesLen =  nodes[msg.sender][zone][shard].length;
        if (nodesLen > 1){
            nodes[msg.sender][zone][shard][index] = nodes[msg.sender][zone][shard][nodesLen - 1];
        }
        nodes[msg.sender][zone][shard].pop();
        delete nodeMap[msg.sender][zone][shard][pid];
        emit DeleteNode(msg.sender, zone, shard, pid);
    }

    function getAppList()public view returns (address[] memory){
        return apps;
    }
    
    function getZoneList(address app)public view onlyAppExist(app) returns(bytes32[] memory){
        return zones[app];
    }
    
    function getShardList(address app, bytes32 zone)public view onlyZoneExist(app, zone) returns(bytes32[] memory){
        return shards[app][zone];
    }

    function getNodeListByName(address app, bytes32 zone, bytes32 shard)public view onlyShardExist(app, zone, shard) returns(Node[] memory){
        return nodes[app][zone][shard];
    }
}
