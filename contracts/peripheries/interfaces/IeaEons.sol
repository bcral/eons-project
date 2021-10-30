// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../utilities/MinterRole.sol';

interface IeaEons is IERC20 {
  function mint(address recepient, uint256 amount) external;
  function addMinter(address minter) external;
  function burn(address from, uint256 amount) external;
  function eBalanceOf(address user) external returns(uint256);
  function eTotalSupply() external returns(uint256);
}
