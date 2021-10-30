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
  IiEonsController public controller;
  // indexer variable - initiated as 10**18
  uint256 i;

  uint256 WAD = 10**18;

  constructor(address _aToken, address _vault, address _controller) ERC20('Eons Interest Bearing Token', 'eEONS') {
    aToken = IAToken(_aToken);
    vault = IEonsAaveVault(_vault);
    controller = IiEonsController(_controller);
    i = WAD;

  }

  modifier onlyController() {
    require(msg.sender == address(controller), "Only the controller can call that.");
    _;
  }

  modifier onlyVault() {
    require(msg.sender == address(vault), "Only the vault can call that.");
    _;
  }
  // Add onlyVault modifier after tests
  // Mints new tokens, but first divides by current index to scale properly
  function mint(address recepient, uint amount) 
    external
  {
    updateI();
    uint256 mintAmnt = amount.wdiv(i);
    require(mintAmnt > 0, "You can't mint 0.");
    _mint(recepient, mintAmnt);
  }

  // ADD onlyMinter
  // Burns tokens, but first divides by current index to scale properly
  function burn(address from, uint256 amount) 
    external 
  {
    // require the user  to have at least that much eTokens
    require(balanceOf(msg.sender) >= amount, "You can't burn that much.");
    updateI();
    uint256 burnAmnt = amount.wdiv(i);
    require(burnAmnt > 0, "You can't burn 0.");
    _burn(from, burnAmnt);
  }

  // read-only for displaying current dev rewards
  function fetchDevRewards() public view returns(uint256) {
    // ((a+r-x)*.15)-r) is fees owed
    uint256 r = vault.getWithdrawnDevFees(address(aToken));
    uint256 x = totalSupply();
    uint256 a = aToken.balanceOf(address(vault));
    return((((a + r - x) * 15) / 100) - r);
  }

  // read-only for getting the current index
  function getCurrentIndex() public view returns(uint256) {
    return(i);
  }

  // stores new instance of i based on current values
  function updateI() internal {
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
      // NI =  ((a-((a+r-x)*.15)-r)/x)+i-WAD
      uint256 r = vault.getWithdrawnDevFees(address(aToken));
      uint256 x = eTotalSupply();
      uint256 a = aToken.balanceOf(address(vault));

      return((a - ((((a + r - x) * 15) / 100) - r).wdiv(x)) + i - WAD);
    } else {
      // if eToken supply is < 0, i should equal 10**18(base number)
      return(WAD);
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
    return super.balanceOf(user).wmul(getNewIndex());
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
    return(super.totalSupply().wmul(getNewIndex()));
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