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
    uint256 devFee;
    uint256 discountFee;
    address devVault;

    function initialize(address _aaveVault, address _aaveRouter) external {
        __Ownable_init();
        aaveVault = IEonsAaveVault(_aaveVault);
        aaveRouter = IEonsAaveRouter(_aaveRouter);
        // developer fee * 10**3
        devFee = 150;
        discountFee = 75;
    }

    // Returns % of the rewards for dev fees
    // a = underlying asset
    // b = eToken total supply for this asset
    function calcDevRewards(uint256 a, uint256 b, bool discount) internal view returns(uint256) {
        if(!discount) {
            // return standard dev fee if no discount
            return (((a - b) * (devFee * 10**18)) / 10**21);
        } else {
            // return discounted dev fee if discount
            return (((a - b) * (discountFee * 10**18)) / 10**21);
        }
    }

    function updateDevVault(address _devVault) external onlyOwner {
        devVault = _devVault;
    }

    function updateFee(uint256 _devFee) external onlyOwner {
        // _devFee 150 = 15%
        require(_devFee < 500, "A 50% fee is too high!");
        devFee = _devFee;
        // discount fee = 50% fee
        discountFee = _devFee * 5 / 10;
    }

    // Needs access control (only vault)
    // Receives fee amount, but doesn't withdraw them
    function updateDevRewards(uint256 _underlyingTotal, uint256 _eTokenTotal, uint256 _standardPool, uint256 _discountedPool) external returns(uint256) {
        // return the actual dev fee for each pool, and return total
        uint256 totalRewards = _underlyingTotal - _eTokenTotal;

        // pool/total = percentage of overall at this rate
        // multiply by fee percentage
        // FIGURE OUT WAD/RAY MATH FOR THIS?  MAYBE DS-MATH?
        uint256 discountedFees = (((_discountedPool / _eTokenTotal) * (discountFee * 10**18)) / 10**21);

        uint256 standardFees = (((_standardPool / _eTokenTotal) * (devFee * 10**18)) / 10**21);

        // returns uint256 dev fee to vault to store for dev to withdraw
        return (discountedFees + standardFees);
    }

    // Returns user's discount status - true or false
    // Calls the appropriate sources and determines eligability at user deposit
    function getUsersDiscountStat(address _user) public view returns(bool) {
        // Do the thing here:
        // If discounted, return true
        if (true) {
            return true;
        } else {
            return false;
        }
    }

    function getAnnualizedReturnRate(uint256 aTokens, uint256 eTokens) public view returns(uint256) {
        return ((aTokens - eTokens) / eTokens) / (timeSinceRebalance / annualBlocks);
    }
}