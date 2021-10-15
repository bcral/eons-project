// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IiEonsController {
    function updateDevRewards(address a, address b) external returns(uint256, address);
}