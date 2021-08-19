// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IWETHGateway {
  function withdrawETH(
    address lendingPool,
    uint256 amount,
    address onBehalfOf
  ) external;
}
