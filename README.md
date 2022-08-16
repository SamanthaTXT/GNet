# GNet
Smart Contract for the CRUD of GNet nodes.


## 合约
**contracts/GNToken.sol** 代币合约

**contracts/GNet.sol** 节点增删查改合约


### 外部方法
```
newApp(); #1 创建应用信息
createShard(name); #2 创建分片信息
createNode(pid, role, weight, addr, shard); #3.1 新增节点信息
updateNode(pid, role, weight, addr, shard); #3.2 更新节点信息
deleteNode(pid, shard); #3.3 删除节点信息
```

### 权限方法（owner）
```
setFeeToken(_token); #更新代币地址
setFeeReceiver(_receiver); #设置收款地址
setFeeAmount(_feeAmount); #调整扣除的代币数量
```

## 测试环境（BSC-testnet）：
GNToken: 0x88ED4e7c46261AE27898a8B516A64D0FBDBd0211

GNet: 0xa027ed8287d826ade034f0b8a1fffb31cdf23729

测试地址：0xf06037e05365327d707fa88e78c11cf311a06a3b

