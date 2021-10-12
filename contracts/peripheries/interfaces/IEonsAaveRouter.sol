// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsAaveRouter {
  function deposit(address _asset, uint _amount, address _user) external;
  function withdraw(uint256 _amount, address _recipient) external;
}
