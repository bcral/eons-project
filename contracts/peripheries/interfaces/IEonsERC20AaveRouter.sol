// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsERC20AaveRouter {
  function deposit(address _asset, uint _amount, address _user, address _lendingPool) external;
  function withdraw(address _asset, uint256 _amount, address _aToken, address _recipient, address _lendingPool) external;
}
