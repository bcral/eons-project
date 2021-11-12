// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEonsAaveRouter {
  function depositMATIC(address _lendingPool) external payable;
  function withdrawMATIC(uint256 _amount, address _user, address _lendingPool, address _aToken) external;
}
