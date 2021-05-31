// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IEonsAaveVault {
  function setRouterAddress(address _router) external;
  function depositFor(address recipient, uint amount, uint pid) external;
  function updateEmissionDistribution() external;
}