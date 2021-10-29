// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsAaveVault {
  function setRouterAddress(address _router) external;
  function updateEmissionDistribution() external;
  function withdrawDevFees(address _asset, uint256 _amount, address _devWallet) external;
  function getRollingDevFee(address _aToken) external returns(uint256);
  function getWithdrawnDevFees(address _aToken) external view returns(uint256);
}