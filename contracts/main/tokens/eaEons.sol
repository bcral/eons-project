// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/utilities/MinterRole.sol';
import '../../peripheries/interfaces/IEonsAaveVault.sol';

contract eaEons is ERC20, MinterRole, Ownable {

  IAToken public aToken;
  IEonsAaveVault public vault;

  constructor(address _aToken, address _vault) public ERC20('Eons Interest Bearing Token', 'eEONS') {
    aToken = IAToken(_aToken);
    vault = IEonsAaveVault(_vault);
  }

  function calcBalance(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
    if (a == 0) {
    return 0;
    }
    // (c / a) * b
    return ((((c * 10**18) / b) * a) / 10**18);
  }

  function mint(address recepient, uint amount) external onlyMinter {
    _mint(recepient, amount);
  }

  function burn(address from, uint256 amount) external onlyMinter {
    _burn(from, amount);
  }

  function balanceOf(address user)
    public
    view
    override(ERC20)
    returns (uint256)
  {
    // send the balance and total supply of the inherited ERC20 contract with the
    // calculated balance of aTokens in the vault
    return calcBalance(super.balanceOf(user), super.totalSupply(), aToken.balanceOf(address(vault)));
  }

  function totalSupply()
    public
    view
    override(ERC20)
    returns (uint256)
  {
    // aToken total supply = eaEons total supply
    return aToken.totalSupply();
  }
}
