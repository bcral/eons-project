// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IiEonsController {
    function updateDevRewards(uint256 a, uint256 b, uint256 s, uint256 d) external returns(uint256);
    function getUsersDiscountStat(address _user) external returns(bool);
}