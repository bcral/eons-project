// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsAaveVault {
  function setRouterAddress(address _router) external;
  function depositFor(address recipient, uint amount, uint pid) external;
  function updateEmissionDistribution() external;
}