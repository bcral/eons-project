// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBonusClaimer {
    function getRewardsBalance(address _aToken, address _vault) external returns(uint256);
    function claimRewards(address _aToken, uint256 _amount, address _vault) external;
}