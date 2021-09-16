// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import 'hardhat/console.sol';

import './Roles.sol';

contract MinterRoleUpgradeable is ContextUpgradeable {
	using Roles for Roles.Role;

	event MinterAdded(address indexed account);
	event MinterRemoved(address indexed account);

	Roles.Role private _minters;

	function __MinterRole_init() public initializer {
		__Context_init();
		_addMinter(_msgSender());
	}

	modifier onlyMinter() {
		console.log('MsgSender is ', _msgSender());
		require(isMinter(_msgSender()), 'MinterRole: caller does not have the Minter role');
		_;
	}

	function isMinter(address account) public view returns (bool) {
		return _minters.has(account);
	}

	function addMinter(address account) public virtual onlyMinter {
		_addMinter(account);
	}

	function renounceMinter() public {
		_removeMinter(_msgSender());
	}

	function _addMinter(address account) internal  {
		_minters.add(account);
		emit MinterAdded(account);
	}

	function _removeMinter(address account) internal {
		_minters.remove(account);
		emit MinterRemoved(account);
	}
}
