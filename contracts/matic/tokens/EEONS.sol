// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../utilities/MinterRole.sol';

contract EEONS is ERC20, MinterRole, Ownable {

  constructor() public ERC20('Eons Interest Bearing Token', 'eEONS') {
  }

  function mint(address recepient, uint amount) external onlyMinter {
    _mint(recepient, amount);
  }

  function burn(address from, uint256 amount) external onlyMinter {
    _burn(from, amount);
  }
}
