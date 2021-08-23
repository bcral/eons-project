// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import 'hardhat/console.sol';

import '../interfaces/IEonsLP.sol';
// EONS Vault distributes fees equally amongst staked pools
// Have fun reading it. Hopefully it's bug-free. God bless.
contract EonsUniswapVault is OwnableUpgradeable {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	// Info of each user.
	struct UserInfo {
		address addr;
		uint256 amount; // How many  tokens the user has provided.
		uint256 rewardDebt; // Reward debt. See explanation below.
	}

	// The EONSLP TOKEN!
	IEonsLP private _eonsLp;
	IERC20Upgradeable private _eons;

	// Dev address.
	address private _devaddr;

	mapping(uint256 => mapping(address => UserInfo)) private userInfo;	// pid => user address => UserInfo
	uint16 DEV_FEE;
	address private _superAdmin;

	event SuperAdminTransfered(address indexed previousOwner, address indexed newOwner);
	event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 startTime);
	event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
	event Approval(address indexed owner, address indexed spender, uint256 _pid, uint256 value);

	function initialize(address eonsLp, address eons, address devaddr, address superAdmin) external initializer {
		DEV_FEE = 1500;
		_eons = IERC20Upgradeable(eons);
		_eonsLp = IEonsLP(eonsLp);
		_devaddr = devaddr;
		_superAdmin = superAdmin;
	}

	function getUserStakedAmount(uint256 _pid, address _userAddress) external view returns (uint256 stakedAmount) {
		return userInfo[_pid][_userAddress].amount;
	}

	// Sets the dev fee for this contract
	// defaults at 7.24%
	// Note contract owner is meant to be a governance contract allowing EONS governance consensus

	function setDevFee(uint16 _DEV_FEE) external onlyOwner {
		require(_DEV_FEE <= 1000, 'Dev fee clamped at 10%');
		DEV_FEE = _DEV_FEE;
	}

	// Deposit  tokens to EONSVault for EONS allocation.
	function deposit(uint256 _pid, uint256 _amount) external {
		UserInfo storage user = userInfo[_pid][msg.sender];

		//Transfer in the amounts from user
		// save gas
		if (_amount > 0) {
			_eonsLp.mint(address(msg.sender), _amount);
			user.amount = user.amount+_amount;
		}
		// if (_amount > 0) _eonsNftPool.doEonsStaking(msg.sender, _amount, block.timestamp);
		emit Deposit(msg.sender, _pid, _amount, block.timestamp);
	}

	function depositFor(address _depositFor, uint256 _pid, uint256 _amount) external {
		// requires no allowances
		UserInfo storage user = userInfo[_pid][_depositFor];

		if (_amount > 0) {
			user.amount = user.amount+_amount;
			_eonsLp.mint(_depositFor, _amount);
		}

		emit Deposit(_depositFor, _pid, _amount, block.timestamp);
	}

	// Test coverage
	// [x] Does allowance update correctly?
	function setAllowanceForPoolToken(address spender, uint256 _pid, uint256 value) external {
		// PoolInfo storage pool = _poolInfo[_pid];
		// pool.allowance[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, _pid, value);
	}

	// Test coverage
	// [x] Does allowance decrease?
	// [x] Do oyu need allowance
	// [x] Withdraws to correct address
	function withdrawFrom(address owner, uint256 _pid, uint256 _amount, bool ethOnly) external {
		// PoolInfo storage pool = _poolInfo[_pid];
		_withdraw(_pid, _amount, owner, msg.sender, ethOnly);
	}

	// Withdraw  tokens from EONSVault.
	function withdraw(uint256 _pid, uint256 _amount, bool ethOnly) external {
		_withdraw(_pid, _amount, msg.sender, msg.sender, ethOnly);
	}

	function isContract(address addr) external view returns (bool) {
			uint256 size;
			assembly {
				size := extcodesize(addr)
			}
			return size > 0;
	}
	function distributeIncomeToUser(address distributer, uint amount, uint pid) external onlyOwner {
		UserInfo storage user = userInfo[pid][distributer];
		if (amount > 0) {
			_eonsLp.mint(distributer, amount);
			user.amount = user.amount+amount;
		}
	}

	// Low level withdraw function
	// TODO: not completed yet
	function _withdraw(uint256 pid, uint256 amount, address from, address to, bool ethOnly) internal {
		UserInfo storage user = userInfo[pid][from];
		require(user.amount >= amount, 'withdraw: not good');

		if (amount > 0) {
			
			_eonsLp.burnFrom(msg.sender, amount);
			user.amount = user.amount-amount;
		}

		emit Withdraw(to, pid, amount);
	}
/*
	function safeEonsTransfer(address _to, uint256 _amount) internal {
		if (_amount == 0) return;

		uint256 eonsBal = _eons.balanceOf(address(this));
		if (_amount > eonsBal) {
			_eons.transfer(_to, eonsBal);
		} else {
			_eons.transfer(_to, _amount);
		}
	}
*/
	function setDevFeeReciever(address devaddr) external onlyOwner {
		_devaddr = devaddr;
	}

	function superAdmin() external view returns (address) {
		return _superAdmin;
	}

	modifier onlySuperAdmin() {
		require(_superAdmin == _msgSender(), 'Super admin : caller is not super admin.');
		_;
	}

	function burnSuperAdmin() external virtual onlySuperAdmin {
		emit SuperAdminTransfered(_superAdmin, address(0));
		_superAdmin = address(0);
	}

	function newSuperAdmin(address newOwner) external virtual onlySuperAdmin {
		require(newOwner != address(0), 'Ownable: new owner is the zero address');
		emit SuperAdminTransfered(_superAdmin, newOwner);
		_superAdmin = newOwner;
	}
}
