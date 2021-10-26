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
import '../peripheries/libraries/DSMath.sol';

contract Controller is OwnableUpgradeable {
    using DSMath for uint256;

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
    uint256 WAD = 10**18;

    function initialize(address _aaveVault, address _aaveRouter) external {
        __Ownable_init();
        aaveVault = IEonsAaveVault(_aaveVault);
        aaveRouter = IEonsAaveRouter(_aaveRouter);
        // developer fee * 10**3
        devFee = 15 * 10**16;
        discountFee = devFee.wdiv(2);
    }

    function updateDevVault(address _devVault) external onlyOwner {
        devVault = _devVault;
    }

    // returns standard dev fee, discounted dev fee as % of WAD
    function getDevFees() public view returns(uint256, uint256) {
        return(devFee, discountFee);
    }

    // Needs access control (only vault)
    // Receives fee amount, but doesn't withdraw them
    function updateDevRewards(uint256 _underlyingTotal, uint256 _eTokenTotal, uint256 _standardPool, uint256 _discountedPool)
        external 
        returns(uint256) 
    {
        // return the actual dev fee for each pool, and return total
        uint256 totalRewards = _underlyingTotal - _eTokenTotal;

        // totalRewards / _eTokenTotal * Pool
        uint256 discountedFeeShare = (totalRewards.wdiv(_eTokenTotal)).wmul(_discountedPool);
        uint256 standardFeeShare = (totalRewards.wdiv(_eTokenTotal)).wmul(_standardPool);
        // multiply by fees as a percentage
        uint256 discountedFees = discountedFeeShare.wmul(discountFee);
        uint256 standardFees = standardFeeShare.wmul(devFee);

        // returns uint256 dev fee to vault to store for dev to withdraw
        return(discountedFees + standardFees);
    }
}