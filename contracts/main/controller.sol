// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

contract Controller is OwnableUpgradeable {
  using SafeMathUpgradeable for uint256;
  IERC20Upgradeable public eons;
  IEonsAaveVault public eonsAaveVault;
  IEonsUniVault public eonsUniVault;
  uint16 public poolEmissionRate = 700;
  uint16 public lpEmissionRate = 150;
  uint16 public burnEmissionRate = 150;

  function initialize(address _eonsAddress, address _eonsAaveVaultAddress, address _eonsUniVaultAddress) public initializer {
    eons = IERC20Upgradeable(_eonsAddress);
    eonsAaveVault = IEonsAaveVault(eonsAaveVault);
    eonsUniVault = IEonsUniVault(eonsUniVault);
  }

  
}
