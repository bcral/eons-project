// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsUniRouter {
  function deposit(uint _amount, uint _pid, address _user) external;
  function withdraw(uint _pid, uint _amount, address _recipient) external;
}
