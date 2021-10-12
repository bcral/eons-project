// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsAaveVault {
  function setRouterAddress(address _router) external;
  // Keep for now, but probably remove later
  function updateEmissionDistribution() external;
}