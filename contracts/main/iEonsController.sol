// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../peripheries/interfaces/IEonsAaveVault.sol';
import '../peripheries/interfaces/IEonsUniVault.sol';
import '../peripheries/interfaces/IEonsAaveRouter.sol';
import '../peripheries/interfaces/IEonsUniRouter.sol';
import '../peripheries/interfaces/IEons.sol';

contract Controller is OwnableUpgradeable {

  struct PoolInterestRate {
    uint256 pid;
    uint256 rate;
    bool increased;
  }

  IEonsAaveVault public aaveVault;
  IEonsAaveRouter public aaveRouter;
  IEonsUniVault public uniVault;
  IEonsUniRouter public uniRouter;
  uint256 devFee;
  address devVault;

    function initialize(address _aaveVault, address _aaveRouter, address _treasury) external {
        __Ownable_init();
        aaveVault = IEonsAaveVault(_aaveVault);
        aaveRouter = IEonsAaveRouter(_aaveRouter);
        // developer fee * 10**3
        devFee = 150;
    }

    // Returns 15% of the rewards for dev fees
    // a = underlying asset
    // b = eToken total supply for this asset
    function calcDevRewards(uint256 a, uint256 b) internal view returns(uint256) {
        // 15% of (total aToken - total eToken)
        return (((a - b) * (devFee * 10**18)) / 10**21);
    }

    function updateDevVault(address _devVault) external onlyOwner {
        devVault = _devVault;
    }

    function updateFee(uint256 _devFee) external onlyOwner {
        require(_devFee < 500, "That fee is too high!");
        devFee = _devFee;
    }

    // Needs access control
    // Receives fees and transfers them where needed
    function updateDevRewards(address _underlying, address _eToken) external returns(uint256, address) {
        // actually run logic, not this
        return (IERC20(_underlying).totalSupply() - IERC20(_eToken).totalSupply(), address(devVault));
    }
}