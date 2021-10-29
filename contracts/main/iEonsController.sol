// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../peripheries/interfaces/IEonsAaveVault.sol';
import '../peripheries/interfaces/IEonsAaveRouter.sol';
import '../peripheries/interfaces/IEons.sol';
import '../peripheries/libraries/DSMath.sol';

contract iEonsController is OwnableUpgradeable {
    using DSMath for uint256;

    struct PoolInterestRate {
        uint256 pid;
        uint256 rate;
        bool increased;
    }

    IEonsAaveVault public aaveVault;
    IEonsAaveRouter public aaveRouter;
    // address for dev to withdraw to.
    address devVault;
    uint256 WAD = 10**18;

    function initialize(address _aaveVault, address _aaveRouter, address _devVault) external {
        __Ownable_init();
        aaveVault = IEonsAaveVault(_aaveVault);
        aaveRouter = IEonsAaveRouter(_aaveRouter);
        devVault = _devVault;
    }

    function updateDevVault(address _devVault) external onlyOwner {
        devVault = _devVault;
    }
}