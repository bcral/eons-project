// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import '../interfaces/ILendingPool.sol';
import '../interfaces/IEonsETH.sol';

contract EonsAaveVault is Ownable {
  using SafeMath for uint256;

  struct PoolInfo {
    address aToken;
    address eToken;
    uint profit;
    uint timestamp;
  }

  struct UserInfo {
    uint amount;
  }

  mapping(uint => PoolInfo) private _poolInfo;  // pid => PoolInfo
  mapping(uint => mapping(uint => UserInfo)) private _userInfo;  // user address => pid => UserInfo
  mapping(uint => address[]) private _users;  // pid => user address

  address public router;

  constructor() public {

  }

  function setRouterAddress(address _router) {
    router = _router;
  }

  function addPool(address aToken, address eToken, uint pid) external onlyOwner {
    _poolInfo[pid] = PoolInfo({eToken: eToken, aToken: aToken, aTokenIncome: 0});
  }

  function depositFor(address recipient, uint amount, uint pid) external {
    poolInfo memory pool = _poolInfo[pid];
    IEonsETH(pool.eToken).mint(recepient, amount);
    UserInfo storage user = _userInfo[recipient][pid];
    user.amount = user.amount.add(amount);
    if (_isNew(pid, recipient)) {
      _users[pid].push(recipient);
    }
  }

  function setProfit(uint pid, uint profit) external onlyOwner {
    PoolInfo storage pool = _poolInfo[pid];
    pool.profit = profit;
    pool.timestamp = block.timestamp;
  }

  function ditributeProfitToUser(uint pid, address user) external onlyOwner {

  }

  function calcProfitFor(uint pid) external returns (uint) {
    PoolInfo storage pool = _poolInfo[pid];
    uint income = IERC20(pool.aToken).balanceOf(router);
    uint profit = income - asset.income;
    asset.income = income;
    return profit;
  }

  function _isNew(uint pid, address user) internal view returns (bool) {
    address[] memory users = _users[pid];
    for (uint i = 0; i < users.length; i++) {
      if (keccak256(abi.encodePacked(user) == keccak256(abi.encodePacked(users[i]))) {
        return true;
      }
    }
    return false;
  }
}
