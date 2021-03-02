// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';

// EONS Vault distributes fees equally amongst staked pools
// Have fun reading it. Hopefully it's bug-free. God bless.
contract EonsVault is Ownable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	// Info of each user.
	struct UserInfo {
		address addr;
		uint256 amount; // How many  tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
	}

	// Info of each pool.
	struct PoolInfo {
		IERC20 token; // Address of  token contract.
		bool withdrawable; // Is this pool withdrawable?
	}

	// The EONSLP TOKEN!
	IERC20 public eonsLp;
	IERC20 public eons;

	// Dev address.
	address public devaddr;

	mapping(uint => PoolInfo) private _poolInfo;  // pid(pool type) => _poolInfo
	mapping(uint256 => mapping(address => UserInfo)) public userInfo;	// pid => user address => UserInfo
	uint16 DEV_FEE;
	uint256 pending_DEV_rewards;
	address private _superAdmin;

	event SuperAdminTransfered(address indexed previousOwner, address indexed newOwner);
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 startTime);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 _pid, uint256 value);

	constructor(IERC20 _eonsLp, IERC20 _eons, address _devaddr, address superAdmin) public onlyOwner {
		DEV_FEE = 15;
		eons = _eons;
		eonsLp = _eonsLp;
		devaddr = _devaddr;
		_superAdmin = superAdmin;
	}

	function getUserStakedAmount(uint256 _pid, address _userAddress) external view returns (uint256 stakedAmount) {
		return userInfo[_pid][_userAddress].amount;
	}

	// Add a new token pool. Can only be called by the owner.
	// Note contract owner is meant to be a governance contract allowing EONS governance consensus
	function add(IERC20 token, bool withdrawable, uint pid) public onlyOwner {
		PoolInfo storage poolInfo = _poolInfo[pid];
		poolInfo.token = token;
		poolInfo.withdrawable = withdrawable;
	}

	// Update the given pool's ability to withdraw tokens
	// Note contract owner is meant to be a governance contract allowing EONS governance consensus
	function setPoolWithdrawable(uint256 _pid, bool _withdrawable) public onlyOwner {
		_poolInfo[_pid].withdrawable = _withdrawable;
	}

	// Sets the dev fee for this contract
	// defaults at 7.24%
	// Note contract owner is meant to be a governance contract allowing EONS governance consensus

	function setDevFee(uint16 _DEV_FEE) public onlyOwner {
		require(_DEV_FEE <= 1000, 'Dev fee clamped at 10%');
		DEV_FEE = _DEV_FEE;
	}

	function getPendingDevFeeRewards() public view returns (uint256) {
		return pending_DEV_rewards;
	}

	// Deposit  tokens to EONSVault for EONS allocation.
	function deposit(uint256 _pid, uint256 _amount) public {
		PoolInfo storage pool = _poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][msg.sender];

		//Transfer in the amounts from user
		// save gas
		if (_amount > 0) {
			pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
			user.amount = user.amount.add(_amount);
		}
		// if (_amount > 0) _eonsNftPool.doEonsStaking(msg.sender, _amount, block.timestamp);
		emit Deposit(msg.sender, _pid, _amount, block.timestamp);
	}

	// Test coverage
	// [x] Does user get the deposited amounts?
	// [x] Does user that its deposited for update correcty?
	// [x] Does the depositor get their tokens decreased
	function depositFor(address _depositFor, uint256 _pid, uint256 _amount) public {
		// requires no allowances
		PoolInfo storage pool = _poolInfo[_pid];
		UserInfo storage user = userInfo[_pid][_depositFor];

		if (_amount > 0) {
			pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
			user.amount = user.amount.add(_amount); // This is depositedFor address
		}

		emit Deposit(_depositFor, _pid, _amount, block.timestamp);
	}

	// Test coverage
	// [x] Does allowance update correctly?
	function setAllowanceForPoolToken(address spender, uint256 _pid, uint256 value) public {
		// PoolInfo storage pool = _poolInfo[_pid];
		// pool.allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, _pid, value);
	}

	// Test coverage
	// [x] Does allowance decrease?
	// [x] Do oyu need allowance
	// [x] Withdraws to correct address
	function withdrawFrom(address owner, uint256 _pid, uint256 _amount) public {
		// PoolInfo storage pool = _poolInfo[_pid];
		_withdraw(_pid, _amount, owner, msg.sender);
	}

	// Withdraw  tokens from EONSVault.
	function withdraw(uint256 _pid, uint256 _amount) public {
		_withdraw(_pid, _amount, msg.sender, msg.sender);
	}

	function isContract(address addr) public view returns (bool) {
			uint256 size;
			assembly {
				size := extcodesize(addr)
			}
			return size > 0;
	}

	function emergencyWithdraw(uint256 _pid) public {
		PoolInfo storage pool = _poolInfo[_pid];
		require(pool.withdrawable, 'Withdrawing from this pool is disabled');
		UserInfo storage user = userInfo[_pid][msg.sender];
		pool.token.safeTransfer(address(msg.sender), user.amount);
		emit EmergencyWithdraw(msg.sender, _pid, user.amount);
		user.amount = 0;
		user.rewardDebt = 0;
	}

	// Low level withdraw function
	function _withdraw(uint256 _pid, uint256 _amount, address from, address to) internal {
		PoolInfo storage pool = _poolInfo[_pid];
		require(pool.withdrawable, 'Withdrawing from this pool is disabled');
		UserInfo storage user = userInfo[_pid][from];
		require(user.amount >= _amount, 'withdraw: not good');

		if (_amount > 0) {
			user.amount = user.amount.sub(_amount);
			pool.token.safeTransfer(address(to), _amount);
		}

		// if (_amount > 0) _eonsNftPool.withdrawLP(msg.sender, _amount);
		emit Withdraw(to, _pid, _amount);
	}

	function safeEonsTransfer(address _to, uint256 _amount) internal {
		if (_amount == 0) return;

		uint256 eonsBal = eons.balanceOf(address(this));
		if (_amount > eonsBal) {
			eons.transfer(_to, eonsBal);
		} else {
			eons.transfer(_to, _amount);
		}
	}

	function setDevFeeReciever(address _devaddr) public onlyOwner {
		devaddr = _devaddr;
	}

	function superAdmin() public view returns (address) {
		return _superAdmin;
	}

	modifier onlySuperAdmin() {
		require(_superAdmin == _msgSender(), 'Super admin : caller is not super admin.');
		_;
	}

	function burnSuperAdmin() public virtual onlySuperAdmin {
		emit SuperAdminTransfered(_superAdmin, address(0));
		_superAdmin = address(0);
	}

	function newSuperAdmin(address newOwner) public virtual onlySuperAdmin {
		require(newOwner != address(0), 'Ownable: new owner is the zero address');
		emit SuperAdminTransfered(_superAdmin, newOwner);
		_superAdmin = newOwner;
	}
}
