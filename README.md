# GNet
Smart Contract for the CRUD of GNet nodes.


## 合约
**GNToken.sol** 代币合约

**GNet.sol** 节点增删查改合约


### 外部方法
```
newApp(); #1 创建应用信息
createZone(name); #2 创建分区信息
createShard(zone, name); #3 创建分片信息
createNode(zone, shard, pid, role, weight, addr); #4.1 新增节点信息
updateNode(zone, shard, pid, role, weight, addr); #4.2 更新节点信息
deleteNode(zone, shard, pid); #4.3 删除节点信息
```

### 权限方法（owner）
```
setFeeToken(_feeToken); #更新代币地址
setFeeReceiver(_feeReceiver); #设置收款地址
setFeeAmount(_feeAmount); #调整扣除的代币数量
```

## 测试环境（BSC-testnet）：
GNToken: 0x88ED4e7c46261AE27898a8B516A64D0FBDBd0211

GNet: 0x91914C27c892F3a4f4a2E0769bC9c8A012F1Cdae

测试地址：0xf06037e05365327d707fa88e78c11cf311a06a3b

