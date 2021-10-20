// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/utilities/MinterRole.sol';
import '../../peripheries/interfaces/IEonsAaveVault.sol';

import '../../peripheries/interfaces/IiEonsController.sol';

contract eaEons is ERC20, MinterRole, Ownable {

  IAToken public aToken;
  IEonsAaveVault public vault;
  IiEonsController public controller;

  constructor(address _aToken, address _vault, address _controller) public ERC20('Eons Interest Bearing Token', 'eEONS') {
    aToken = IAToken(_aToken);
    vault = IEonsAaveVault(_vault);
    controller = IiEonsController(_controller);
  }

  // Getters for required dev fee values
  // Calculates overall dev fees collected from all users, from both pools
  function getRollingDevFee() internal view returns(uint256) {
    return(vault.getRollingDevFee(address(aToken)));
  }

  function calcReturns(uint256 _userBalance, uint256 _totalE, uint256 _totalA) internal view returns (uint256) {
    // If user is broke, no rewards
    if (_userBalance == 0) {
        return 0;
    }
    // Gets total rewards, subtracts fees taken
    // Needs to do more stuff
    return ((_totalA - _totalE) - getRollingDevFee());
  }

  // Overriding balanceOf() standard ERC20 function to allow for live updates of user
  // balance without needing to execute any transfers
  function balanceOf(address user)
    public
    view
    override(ERC20)
    returns (uint256)
  {
    // send the balance and total supply of the inherited ERC20 contract with the
    // calculated balance of aTokens in the vault
    return super.balanceOf(user) + calcReturns(super.balanceOf(user), super.totalSupply(), aToken.balanceOf(address(vault)));
  }

  function mint(address recepient, uint amount) external onlyMinter {
    _mint(recepient, amount);
  }

  function burn(address from, uint256 amount) external onlyMinter {
    _burn(from, amount);
  }

  // acts as the underlying eToken ERC20 balanceOf() function
  function eBalanceOf(address user)
    public
    view
    returns (uint256)
  {
    return super.balanceOf(user);
  }

  // overriding ERC20 totalSupply() function that returns the total aToken supply
  function totalSupply()
    public
    view
    override(ERC20)
    returns (uint256)
  {
    // aToken total supply = eaEons total supply
    return aToken.balanceOf(address(vault));
  }

  // acts as standard ERC20 totalSupply() but for the underlying eTokens
  function eTotalSupply()
    public
    view
    returns (uint256)
  {
    return super.totalSupply();
  }
}
