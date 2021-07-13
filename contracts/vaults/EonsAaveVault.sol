// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';


import '../interfaces/ILendingPool.sol';
import '../interfaces/IEonsETH.sol';
import '../interfaces/IEons.sol';
import '../interfaces/IWETH.sol';
import '../interfaces/IEonsAaveRouter.sol';

contract EonsAaveVault is OwnableUpgradeable {

  struct PoolInfo {
    string symbol;
    address eToken;       // eToken of a pool. will mint amount of eToken when a user deposit
    uint16 allocPoint;    // allocation point of a pool
    uint accEonsPerShare; //accumulating emissions per share by eons
    uint16 depositFee;    // depositfee
    uint256 lastBlock;
    uint256 totalStaked;  // original staked amount
  }

  struct UserInfo {
    bool registered;
    uint256 amount;     // amount of which user deposited
    uint256 rewardDebt; // reward debt. used for eons emission distribution
  }

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint indexed pid, uint256 amount);

  PoolInfo[] public poolInfo;  // pid => PoolInfo
  mapping(address => mapping(uint => UserInfo)) public userInfo;  // user address => pid => UserInfo

  IEonsAaveRouter public router;
  IEons public eons;
  uint256 public totalAllocPoint;
  uint256 public poolRewardRate;
  uint256 public devFeeRate;
  address public devAddress;
  mapping(uint256 => uint256) public userCountInPool; // pid => user holder count
  
  function initialize(address _eons, address _dev, address _router) external initializer {
    eons = IEons(_eons);
    totalAllocPoint = 1000;
    poolRewardRate = 850;
    devFeeRate = 150;
    devAddress = _dev;
    router = IEonsAaveRouter(_router);
    __Ownable_init();
  }

  function setRouterAddress(address _router) external onlyOwner {
    router = IEonsAaveRouter(_router);
  }

  function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256) {
      return _to-_from;
  }

  function pendingEons(uint _pid, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_user][_pid];
    if (user.amount > 0) {
      uint currentEonsForUser = pool.accEonsPerShare*user.amount;
      if (currentEonsForUser > user.rewardDebt) {
        return currentEonsForUser-user.rewardDebt;
      } else {
        return 0;
      }
    }
    return 0;
  }

  function stakedOf(uint _pid) external view returns (uint256) {
    uint256 totalStakedOf = router.totalStakedOf(_pid);
    return totalStakedOf;
  }

  function balanceOf(uint256 _pid, address _user) external view returns (uint256) {
    UserInfo storage user = userInfo[_user][_pid];
    return user.amount;
  }

  function totalStaked() external view returns (uint256) {
    uint256 total = 0;
    for (uint i = 0; i < poolInfo.length; i++) {
      uint256 staked = router.totalStakedOf(i);
      total = total+staked;
    }
    return total;
  }

  function pendingRewardDevFeeOf(uint _pid, address _user) public view returns (uint256) {
    UserInfo storage user = userInfo[_user][_pid];
    PoolInfo storage pool = poolInfo[_pid];
    uint256 userShareOfPool = user.amount*1e12/pool.totalStaked;
    uint256 total = router.totalStakedOf(_pid);
    uint256 userStaked = (total-pool.totalStaked)*userShareOfPool/1e12;
    uint256 pendingReward = userStaked*devFeeRate/1000;
    return pendingReward;
  }

  function pendingRewardOf(uint256 _pid, address _user) external view returns (uint256) {
    UserInfo storage user = userInfo[_user][_pid];
    PoolInfo storage pool = poolInfo[_pid];
    uint256 userShareOfPool = user.amount*1e12/pool.totalStaked;
    uint256 total = router.totalStakedOf(_pid);
    uint256 userStaked = (total-pool.totalStaked)*userShareOfPool/1e12;
    uint256 pendingReward = userStaked*poolRewardRate/1000;
    return pendingReward;
  }

  function add(string memory _symbol, address _eToken, uint16 _allocPoint, uint16 _depositFee) external onlyOwner {
    poolInfo.push(PoolInfo({
      symbol: _symbol,
      eToken: _eToken,
      allocPoint: _allocPoint,
      depositFee: _depositFee,
      lastBlock: block.number,
      accEonsPerShare: 0,
      totalStaked: 0
    }));
  }

  function set(uint _pid, string memory _symbol, uint16 _allocPoint, uint16 _depositFee) external onlyOwner {
    PoolInfo storage pool = poolInfo[_pid];
    pool.symbol = _symbol;
    pool.allocPoint = _allocPoint;
    pool.depositFee = _depositFee;
  }

  function deposit(uint256 _amount, uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[msg.sender][_pid];
    router.deposit(_amount, _pid, msg.sender);

    updateEmissionDistribution();
    uint pending = pendingEons(_pid, msg.sender);
    if (pending > 0) {
      eons.transfer(msg.sender, pending);
    }
    IEonsETH(pool.eToken).mint(msg.sender, _amount);
    pool.totalStaked = pool.totalStaked+_amount;
    if (!user.registered) {
      userCountInPool[_pid] = userCountInPool[_pid]+1;
    }
    user.registered = true;
    user.amount = user.amount+_amount;
    user.rewardDebt = user.amount*pool.accEonsPerShare;

    emit Deposit(msg.sender, _pid, _amount);
  }

  function depositETH() external payable {
    PoolInfo storage pool = poolInfo[1];  // ETH pool: 1
    UserInfo storage user = userInfo[msg.sender][1];

    (, address reserve, ) = router.getAsset(1);
    IWETH(reserve).deposit{value: msg.value}();
    IWETH(reserve).approve(address(router), msg.value);
    router.deposit(msg.value, 1, address(this));

    updateEmissionDistribution();
    uint pending = pendingEons(1, msg.sender);
    if (pending > 0) {
      eons.transfer(msg.sender, pending);
    }
    IEonsETH(pool.eToken).mint(msg.sender, msg.value);
    pool.totalStaked = pool.totalStaked+msg.value;
    if (!user.registered) {
      userCountInPool[1] = userCountInPool[1]+1;
    }
    user.registered = true;
    user.amount = user.amount+msg.value;
    user.rewardDebt = user.amount*pool.accEonsPerShare;

    emit Deposit(msg.sender, 1, msg.value);
  }

  function withdraw(uint _amount, uint256 _pid) external {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[msg.sender][_pid];
    uint256 total = router.totalStakedOf(_pid);
    require(_amount <= total, 'Withdraw not good');

    updateEmissionDistribution();
    uint eonsPending = pendingEons(_pid, msg.sender);
    if (eonsPending > 0) {
      eons.transfer(msg.sender, eonsPending);
    }
    if (_amount > 0) {
      uint devFeePending = pendingRewardDevFeeOf(_pid, msg.sender);
      router.withdraw(_pid, _amount, msg.sender);
      if (devFeePending > 0) {
        router.withdraw(_pid, devFeePending, devAddress);
      }
      if (_amount > user.amount) {
        user.amount = 0;
        if (_amount > pool.totalStaked) {
          pool.totalStaked = 0;
        } else {
          pool.totalStaked = pool.totalStaked-user.amount;
        }
      } else {
        user.amount = user.amount-_amount;
        pool.totalStaked = pool.totalStaked-_amount;
      }
      uint256 eTokenBalance = IEonsETH(pool.eToken).balanceOf(msg.sender);
      if (_amount > eTokenBalance) {
        IEonsETH(pool.eToken).burn(msg.sender, eTokenBalance);
      } else {
        IEonsETH(pool.eToken).burn(msg.sender, _amount);
      }
    }
    user.rewardDebt = user.amount*pool.accEonsPerShare;
    emit Withdraw(msg.sender, _pid, _amount);
  }

  function updateEmissionDistribution() public {
    uint eonsBalance = eons.balanceOf(address(this));
    for (uint i = 0; i < poolInfo.length; i++) {
      PoolInfo storage pool = poolInfo[i];
      uint256 total = router.totalStakedOf(i);
      if (total > 0) {
        pool.accEonsPerShare = (pool.accEonsPerShare+eonsBalance)*pool.allocPoint/totalAllocPoint/total;
      }
    }
  }
}
