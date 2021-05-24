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
    address eToken;
    uint16 allocPoint;
    uint accEonsPerShare;
    uint16 depositFee;
    uint256 lastBlock;
  }

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  mapping(uint => PoolInfo) private _poolInfo;  // pid => PoolInfo
  mapping(address => mapping(uint => UserInfo)) private _userInfo;  // user address => pid => UserInfo
  mapping(uint => address[]) private _users;  // pid => user address

  address public router;
  IERC20Upgradeable public eons;
  uint256 public emissionRate;
  uint256 public totalAllocPoint;
  uint256 public eonsReward; // 70% of emissions
  function initialize(address _eons) public initializer {
    eons = IERC20Upgradeable(_eons);
    emissionRate = 35;
    totalAllocPoint = 1000;
    eonsReward = 700;
  }

  function setRouterAddress(address _router) external {
    router = _router;
  }

  function add(uint pid, address eToken, uint16 allocPoint, uint16 depositFee) external onlyOwner {
    _poolInfo[pid] = PoolInfo({eToken: eToken, allocPoint: allocPoint, depositFee: depositFee, lastBlock: block.number, accEonsPerShare: 0});
  }

  function set(uint pid, uint16 allocPoint, uint16 depositFee) external onlyOwner {
    PoolInfo storage poolInfo = _poolInfo[pid];
    poolInfo.allocPoint = allocPoint;
    poolInfo.depositFee = depositFee;
  }

  // function deposit(uint amount, uint pid) external payable {
  //   PoolInfo storage poolInfo = _poolInfo[pid];
  //   require(poolInfo.aToken != address(0), 'AaveVaultError: pool is not existing');
  //   UserInfo storage userInfo = _userInfo[msg.sender][pid];

  //   updatePool(pid);
  //   if (pid == 1) {   // if eth pool
  //     require(amount == msg.value, 'AaveVaultError: insufficient funds');

  //     if (userInfo.amount > 0) {
  //       uint256 pending = user.amount.mul(pool.accEonsPerShare).div(1e12);
  //       if (pending > 0) {
  //         safeETokenTransfer(msg.sender, pending);
  //       }
  //       if (amount > 0) {
  //         // router.depositETH()
  //       }
  //     }
  //   }
  // }

  function depositFor(address recipient, uint amount, uint pid) external {
    PoolInfo storage pool = _poolInfo[pid];
    IEonsETH(pool.eToken).mint(recipient, amount);
    UserInfo storage user = _userInfo[recipient][pid];
    user.amount = amount;
  }

  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
      return _to.sub(_from);
  }

  function pendingEons(uint pid, address user) external view returns (uint256) {
    PoolInfo storage pool = _poolInfo[pid];
    UserInfo storage user = _userInfo[user][pid];
    uint256 accEonsPerShare = pool.accEonsPerShare;
    uint256 totalSupply = eons.totalSupply();
    if (block.number > pool.lastBlock) {
      uint256 multiplier = getMultiplier(pool.lastBlock, block.number);
      uint256 reward = multiplier.mul(emissionRate).mul(pool.allocPoint).div(totalAllocPoint);
      accEonsPerShare = accEonsPerShare.add(reward.mul(eonsReward).div(1000));
    }
    return user.amount.mul(accEonsPerShare).div(1e12).sub(user.rewardDebt);
  }
}
