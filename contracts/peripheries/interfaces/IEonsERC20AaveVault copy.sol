// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsERC20AaveVault {
  function setRouterAddress(address _router) external;
  function sendRewards(uint256 _amount) external;
  function setDevVaultAddress(address _devVault) external;
}