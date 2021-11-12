// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../../peripheries/interfaces/IiEonsController.sol';
import '../../peripheries/interfaces/IWMATIC.sol';
import '../../peripheries/interfaces/IBonusClaimer.sol';
import '../../peripheries/utilities/Roles.sol';

contract FetchBonus {

    IWMATIC public WMATIC;
    IBonusClaimer public bonusClaimer;

    event BonusPayout(uint256 amount);

    address aToken;

    constructor(address _wmatic, address _bonusAddress) {
        WMATIC = IWMATIC(_wmatic);
        bonusClaimer = IBonusClaimer(_bonusAddress);
    }

    // retrieve bonus from AAVE and re-deposit rewards
    function getBonus(address _tokenAddress, address _sender, address _asset) internal {

        address[] memory aTokenArray = new address[](1);
        aTokenArray[0] = _tokenAddress;
        // call getRewardsBalance to check the total owed
        // send aToken address and vault address as params
        uint256 totalOwed = bonusClaimer.getRewardsBalance(aTokenArray, address(this));
        // check that bonus meets the minimum threshold for retrieving

        // COME UP WITH SOME LOGICAL THRESHOLD TO PUT HERE FOR WITHDRAWAL
        if (totalOwed > 1000000000000) {
            // Send total owed through AAVE and add to total aToken supply
            bonusClaimer.claimRewards(aTokenArray, totalOwed, address(this));
            
            // Swap WMATIC for base asset

            // Call ERC20 approve(_sender, totalOwed) to approve transaction to vault 

            // Call deposit on _sender(vault) address to re-deposit base asset and
            // add all aTokens to the total pool

            emit BonusPayout(totalOwed);
        }
    }
}