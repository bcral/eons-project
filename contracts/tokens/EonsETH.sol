// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../utilities/MinterRole.sol';

contract EonsETH is ERC20Upgradeable, MinterRole, OwnableUpgradeable {

  function initialize() external initializer {
    __ERC20_init('Eons ETH', 'eETH');
    __MinterRole_init();
    __Ownable_init();
  }

  function mint(address recepient, uint amount) external onlyMinter {
    _mint(recepient, amount);
  }

  function burn(address from, uint256 amount) external onlyMinter {
    _burn(from, amount);
  }
}
