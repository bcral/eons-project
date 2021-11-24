// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQSRouter {
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[2] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}
