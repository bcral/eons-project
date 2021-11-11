// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../iEonsController.sol';

import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IeaEons.sol';
import '../../peripheries/interfaces/IEonsAaveRouter.sol';
import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/interfaces/IiEonsController.sol';
import '../../peripheries/interfaces/IWMATIC.sol';
import '../../peripheries/interfaces/IBonusClaimer.sol';
import '../../peripheries/utilities/Roles.sol';

  // Vault core functionality:
  // -store account's aToken values/hold actual aTokens here
  // -mint EaToken to account address for each deposit
  // Deposit flow:
  //    -before deposit, approve transfer to router
  //        X Added in notes for web3 to approve
  //    -check if user already has funds deposited.  if so, handle appropriately
  //    -call deposit function in router
  //        X Called with all required arguments
  //    -mint EaToken to user's address
  // Withdrawal flow:
  //    -check eEONS.userBalanceOf(msg.sender) to ensure user has requested balance
  //    -get vault aTokens balance by calling aTokens.balanceOf(address(this))
  //    -find user's share of vault getAccountShare(user's address)
  //    -divide vault's aTokens by user's share of vault
  //    ^All of this should be handled by eToken.balanceOf()
  //    -check that user's call doesn't exceed shared balance in vault
  //    -approve router to move called aTokens from user's balance
  //    -call router to withdraw original erc20 from Aave
  //    -burn EaToken

contract EonsMATICAaveVault is ReentrancyGuard, iEonsController {

    event Deposit(address indexed user, address asset, uint256 amount);
    event Withdraw(address indexed user, address asset, uint256 amount);

    IEonsAaveRouter public router;
    IWMATIC public WMATIC;
    IBonusClaimer public bonusClaimer;
    IeaEons public eToken;
    IAToken public aToken;

    event BonusPayout(uint256 amount);

    uint256 deposits;
    address lendingPool;

    uint256 MAX_INT;

    address devVault;
    
    constructor(address _wmatic, address _bonusAddress, address _devVault, address _aTokenAddress) {
        WMATIC = IWMATIC(_wmatic);
        bonusClaimer = IBonusClaimer(_bonusAddress);
        devVault = _devVault;
        MAX_INT = type(uint256).max;

        aToken = IAToken(_aTokenAddress);
        deposits = 0;
    }

// ********************** MODIFIERS, GETTERS, & SETTERS *************************

    // Requires the caller to be the eToken contract for the correlating aToken
    modifier onlyEToken() {
        require(msg.sender == address(eToken), "Only the eToken contract can call this.");
        _;
    }

    function setRouterAddress(address _router) external onlyOwner {
        router = IEonsAaveRouter(_router);
    }

    function setDevVaultAddress(address _devVault) external onlyOwner {
        devVault = _devVault;
    }

// ****************************** EDIT ASSETS *********************************

    // @dev
    // update support for a coin or token. index is the asset's index in the assetInfo
    // map, _asset is the coin or token's contract address, and _eTokenAddress is the
    //  eToken address created for that asset, and _aTokenAddress is the AAVE token 
    // address created for that asset
    function editAsset(address _eTokenAddress, address _lendingPool) external onlyOwner whenPaused {
        eToken = IeaEons(_eTokenAddress);
        lendingPool = _lendingPool;
    }

// ******************************* FEE STUFF **********************************

    // @dev
    // withdraws all stored dev fees in the native aToken.  Includes reentrancy 
    // protection, and only the available % of rewards are ever available at any time.
    function sendRewards(uint256 _amount) 
        external 
        onlyEToken
    {
        // Transfer the desired amount to the wallet passed as argument
        aToken.transfer(devVault, _amount);
    }

    // REMOVE FOR PRODUCTION
    // FOR TESTING ONLY
    function devA() external view returns(uint256) {
        return(aToken.balanceOf(devVault));
    }

// ************************ NATIVE ASSET TRANSACTIONS ***************************

    // @dev
    // deposit function handles both new deposits and deposits on top of previous ones
    // made by the same user.  Only works for native token
    function depositMATIC() external payable nonReentrant whenNotPaused {

        // just your basic security checks
        require(msg.value > 0, "You can't deposit nothing.");

        // mint eTokens to msg.sender
        eToken.mint(msg.sender, msg.value);
        // send MATIC to router for transfer to AAVE
        router.depositMATIC{value: msg.value}(lendingPool);
        // store deposited amount in the asset's rolling total
        deposits += msg.value;

        emit Deposit(msg.sender, address(0), msg.value);
    }


    // @dev
    // withdraw function handles all withdrawals in native token
    function withdrawMATIC(uint256 _amount) external nonReentrant whenNotPaused {

        // just your basic security checks
        require(_amount > 0, "You can't withdraw nothing.");
        require(_amount <= eToken.balanceOf(msg.sender), "You don't have the funds for that.");
        // If threshold for bonus is met, retrieve bonus and reinvest it back into
        // the aToken balance

        // Uncomment for mainnet/fork tests
        getBonus();

        // If amount requested is the largest number possible, withdraw user's entire
        // balance.
        if(_amount == MAX_INT) {
            _amount = eToken.balanceOf(msg.sender);
        }

        // burns eTokens from msg.sender
        eToken.burn(msg.sender, _amount);
        // transfer user's withdrawn aTokens to the router to cash in
        aToken.transfer(address(router), _amount);
        // call withdrawMATIC() on router, send current value
        router.withdrawMATIC(_amount, msg.sender, lendingPool, address(aToken));
        // subtract amount from the asset's rolling total
        if (eToken.totalSupply() > 0) {
            deposits -= _amount;
        }

        emit Deposit(msg.sender, address(0), _amount);
    }

 // ************************ UNWRAP AND REDEPOSIT WMATIC ***************************
    
    // retrieve bonus from AAVE and re-deposit rewards
    function getBonus() internal {

        address[] memory aTokenArray = new address[](1);
        aTokenArray[0] = address(aToken);
        // call getRewardsBalance to check the total owed
        // send aToken address and vault address as params
        uint256 totalOwed = bonusClaimer.getRewardsBalance(aTokenArray, address(this));
        // check that bonus meets the minimum threshold for retrieving

        // COME UP WITH SOME LOGICAL THRESHOLD TO PUT HERE FOR WITHDRAWAL
        if (totalOwed > 1000000000000) {
            // Send total owed through AAVE and add to total aToken supply
            bonusClaimer.claimRewards(aTokenArray, totalOwed, address(this));
            
            // // Call contract to unwrap and redeposit to AAVE
            WMATIC.withdraw(totalOwed);
            // // Deposit MATIC into router, bypassing minting and depositing aTokens
            router.depositMATIC{value: totalOwed}(lendingPool);

            emit BonusPayout(totalOwed);
        }
    }

    // Fallbacck for receiving MATIC
    receive() external payable {}

    // FOR TESTING ONLY
    // REMOVE FOR DEPLOYMENT
    // To prevent funds from being trapped durring mainnet testing, this "drain plug" 
    // lets the owner drain the funds from the contract and return them to owner.
    function drainPlug() external onlyOwner {
        uint256 amount = aToken.balanceOf(address(this));
        aToken.transfer(msg.sender, amount);
    }
}