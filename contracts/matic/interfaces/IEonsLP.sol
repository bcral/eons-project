// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEonsLP is IERC20 {
  function mint(address recepient, uint _amount) external;
  function burn(uint256 _amount) external;
  function burnFrom(address _account, uint256 _amount) external;
  function multiTransfer(uint256[] memory bits) external returns (bool);
}
