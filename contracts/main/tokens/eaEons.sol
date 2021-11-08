// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/utilities/MinterRole.sol';
import '../../peripheries/interfaces/IEonsAaveVault.sol';

import '../../peripheries/interfaces/IiEonsController.sol';
import '../../peripheries/libraries/DSMath.sol';

contract eaEons is ERC20, MinterRole, Ownable {
  using DSMath for uint256;

  IAToken public aToken;
  IEonsAaveVault public vault;
  // indexer variable - initiated as 10**18
  uint256 i;
  uint256 WAD = 10**18;
  uint256 RAY = 10**27;
  uint8 once;

  constructor(address _aToken, address _vault) ERC20("Eons Interest Bearing Token", "eaEONS") {
    aToken = IAToken(_aToken);
    vault = IEonsAaveVault(_vault);
    i = RAY;
    once = 0;
  }

  // Does not provide re-entrancy protection
  modifier onlyOnce() {
    require(once == 0, "This function can only be called one time.");
    _;
    once = 1;
  }

  modifier onlyVault() {
    require(msg.sender == address(vault), "Only the vault can call that.");
    _;
  }

  // FOR TESTING ONLY
  function getA() external view returns(uint256, uint256) {
    return(aToken.balanceOf(address(vault)), aToken.scaledBalanceOf(address(vault)));
  }

  // Mints new tokens, but first divides by current index to scale properly
  function mint(address recepient, uint amount) 
    external
    onlyVault
  {
    updateI();
    uint256 mintAmnt = amount.rdiv(i);
    require(mintAmnt > 0, "You can't mint 0.");
    _mint(recepient, mintAmnt);
  }

  // Burns tokens, but first divides by current index to scale properly
  function burn(address from, uint256 amount) 
    external
    onlyVault
  {
    // require the user  to have at least that much eTokens
    require(balanceOf(from) >= amount, "You can't burn that much.");
    updateI();
    uint256 burnAmnt = amount.rdiv(i);
    require(burnAmnt > 0, "You can't burn 0.");
    _burn(from, burnAmnt);
  }

  // for withdrawing current dev rewards
  function fetchRewards() private {
    // ((a-x)*.15) is fees owed
    uint256 r = calcRewards();
    if (r != 0) {
      // call function in vault to take dev rewards in aTokens
      vault.sendRewards(address(aToken), r);
    }
  }

  // for withdrawing current dev rewards
  function calcRewards() private view returns(uint256) {
    // ((a-x)*.15) is fees owed
    uint256 e = eTotalSupply();
    uint256 a = aToken.balanceOf(address(vault));
    return(((a - e.rmul(i)) * 15) / 100);
  }

  // REMOVE FOR PRODUCTION
  // This may or may not be useful in production, but it is currently only used for testing
  // read-only for getting the current index
  function getCurrentIndex() public view returns(uint256) {
    return(i);
  }

  // stores new instance of i based on current values
  function updateI() private {
    // transfer 15% to dev
    fetchRewards();
    i = getNewIndex();
  }

  // read-only for getting updated current index + interim changes
  function getNewIndex() 
    public 
    view 
    returns(uint256) 
  {
    // check for 0 total supply to prevent math confusion
    if (eTotalSupply() != 0) {
      // NI =  ((a-((a-x)*.15))/x)+i-ii
      uint256 e = eTotalSupply();
      uint256 a = aToken.balanceOf(address(vault)) - calcRewards();

      // A/x+i-ii
      return (a.rdiv(e.rmul(i)) + i - RAY);
    } else {
      // if eToken supply is < 0, i should equal 10**18(base number)
      return(i);
    }
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
    return (super.balanceOf(user).rmul(getNewIndex()));
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
    // aToken total supply = eaEons total supply * current i
    return(super.totalSupply().rmul(getNewIndex()));
  }

  // acts as standard ERC20 totalSupply() but for the underlying eTokens
  function eTotalSupply()
    public
    view
    returns (uint256)
  {
    return(super.totalSupply());
  }
}