// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsAaveRouter {
  function deposit(address _asset, uint _amount, address _user) external;
  function withdraw(address _asset, uint256 _amount, address _aToken, address _recipient) external;
  function depositMATIC() external payable;
  function withdrawMATIC(uint256 _amount, address _user) external;

}
