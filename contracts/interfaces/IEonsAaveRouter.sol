// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IEonsAaveRouter {
  function getAsset(uint256 _pid) external view returns (address aToken, address reserve, uint256 income);
  function pendingRewardOf(uint256 _pid) external view returns (uint256);
  function deposit(uint _amount, uint _pid, address _user) external;
  function withdraw(uint _pid, uint _amount, address _recipient) external;
  function totalStakedOf(uint _pid) external view returns (uint256);
}
