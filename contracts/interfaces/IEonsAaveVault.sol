// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IEonsAaveVault {
  function setRouterAddress(address _router) external;
  function depositFor(address recipient, uint amount, uint pid) external;
}