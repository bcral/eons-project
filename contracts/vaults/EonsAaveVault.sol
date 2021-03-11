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
    uint income;
    uint timestamp;
  }

  struct UserInfo {
    uint percentage;
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
    _poolInfo[pid] = PoolInfo({eToken: eToken, aToken: aToken, income: 0, profit: 0, timestamp: block.timestamp});
  }

  function depositFor(address recipient, uint amount, uint pid) external {
    poolInfo memory pool = _poolInfo[pid];
    IEonsETH(pool.eToken).mint(recepient, amount);
    UserInfo storage user = _userInfo[recipient][pid];
    user.percentage = pool.aToken.balanceOf(router).div(amount).mul(100);
    if (_isNew(pid, recipient)) {
      _users[pid].push(recipient);
    }
  }

  function distributeProfit(uint pid, uint profit) external onlyOwner {
    PoolInfo storage pool = _poolInfo[pid];
    pool.profit = profit;
    pool.timestamp = block.timestamp;
  }

  function distributeProfitToUser(uint pid, address user) external onlyOwner {
    PoolInfo memory _pool = _poolInfo[pid];
    address[] memory _user = _users[pid];
    for (uint32 i = 0; i < user.length; i++) {
      uint profitByPercentage = _pool.profit.mul(_userInfo[user[i]][pid].percentage).div(100);
      _pool.eToken.mint(user[i], profit);
    }
  }

  function calcAndDistributeProfitFor(uint pid) external returns (uint) {
    PoolInfo storage pool = _poolInfo[pid];
    uint income = IERC20(pool.aToken).balanceOf(router);
    uint profit = income.sub(pool.income);
    pool.income = income;
    distributeProfitToUser(pid, profit);
    return profit;
  }

  function _isNew(uint pid, address user) internal view returns (bool) {
    UserInfo memory user = _userInfo[user][pid];
    if (user.amount == 0) {
      return true;
    }
    return false;
  }
}
