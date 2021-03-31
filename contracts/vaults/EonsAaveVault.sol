// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';

import '../interfaces/ILendingPool.sol';
import '../interfaces/IEonsETH.sol';

contract EonsAaveVault is OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;

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
  mapping(address => mapping(uint => UserInfo)) private _userInfo;  // user address => pid => UserInfo
  mapping(uint => address[]) private _users;  // pid => user address

  address public router;

  function initialize() public initializer {

  }

  function setRouterAddress(address _router) external {
    router = _router;
  }

  function addPool(address aToken, address eToken, uint pid) external onlyOwner {
    _poolInfo[pid] = PoolInfo({eToken: eToken, aToken: aToken, income: 0, profit: 0, timestamp: block.timestamp});
  }

  function depositFor(address recipient, uint amount, uint pid) external {
    PoolInfo memory pool = _poolInfo[pid];
    IEonsETH(pool.eToken).mint(recipient, amount);
    UserInfo storage user = _userInfo[recipient][pid];
    user.percentage = IERC20Upgradeable(pool.aToken).balanceOf(router).div(amount).mul(100);
    if (_isNew(pid, recipient)) {
      _users[pid].push(recipient);
    }
  }

  function distributeProfit(uint pid, uint profit) external onlyOwner {
    PoolInfo storage pool = _poolInfo[pid];
    pool.profit = profit;
    pool.timestamp = block.timestamp;
  }

  function calcAndDistributeProfitFor(uint pid) external returns (uint) {
    PoolInfo storage pool = _poolInfo[pid];
    uint income = IERC20Upgradeable(pool.aToken).balanceOf(router);
    uint profit = income.sub(pool.income);
    pool.income = income;
    pool.profit = profit;
    _distributeProfit(pid, msg.sender);
    return profit;
  }

  function distributeProfitToUser(uint pid, address user) external onlyOwner {
    _distributeProfit(pid, user);
  }

  function _distributeProfit(uint pid, address user) internal {
    PoolInfo memory _pool = _poolInfo[pid];
    uint profitByPercentage = _pool.profit.mul(_userInfo[user][pid].percentage).div(100);
    IEonsETH(_pool.eToken).mint(user, _pool.profit.mul(profitByPercentage));
  }
  function _isNew(uint pid, address user) internal view returns (bool) {
    UserInfo memory user = _userInfo[user][pid];
    if (user.percentage == 0) {
      return true;
    }
    return false;
  }
}
