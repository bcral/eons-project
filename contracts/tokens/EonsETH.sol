// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

import '../utilities/MinterRole.sol';

contract EonsETH is ERC20, MinterRole, Ownable {

  constructor() public ERC20('Eons ETH', 'eETH') {

  }

  function mint(address recepient, uint amount) external onlyMinter {
    _mint(recepient, amount);
  }

  function addMinter(address minter) external override onlyOwner {
    _addMinter(minter);
  }
}
