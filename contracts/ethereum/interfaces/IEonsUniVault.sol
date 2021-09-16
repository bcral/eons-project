// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IEonsUniVault {
  function getUserStakedAmount(uint256 _pid, address _userAddress) external view returns (uint256 stakedAmount);
  function isContract(address addr) external view returns (bool);
  function add(IERC20 token, bool withdrawable, uint pid) external;
  function setPoolWithdrawable(uint256 _pid, bool _withdrawable) external;
  function deposit(uint256 _pid, uint256 _amount) external;
  function depositFor(address _depositFor, uint256 _pid, uint256 _amount) external;
  function setAllowanceForPoolToken(address spender, uint256 _pid, uint256 value) external;
  function withdrawFrom(address owner, uint256 _pid, uint256 _amount) external;
  function withdraw(uint256 _pid, uint256 _amount) external;
  function emergencyWithdraw(uint256 _pid) external;
  function updateEmissionDistribution() external;
}