// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../iEonsController.sol';

import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IeaEons.sol';
import '../../peripheries/interfaces/IEonsERC20AaveRouter.sol';
import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/interfaces/IiEonsController.sol';
import '../../peripheries/interfaces/IWMATIC.sol';
import '../../peripheries/interfaces/IBonusClaimer.sol';
import '../../peripheries/utilities/Roles.sol';
import '../../peripheries/interfaces/IQSRouter.sol';

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

contract EonsERC20AaveVault is ReentrancyGuard, iEonsController {

    event Deposit(address indexed user, address asset, uint256 amount);
    event Withdraw(address indexed user, address asset, uint256 amount);

    IEonsERC20AaveRouter public router;
    IWMATIC public WMATIC;
    IBonusClaimer public bonusClaimer;
    IQSRouter public QSRouter;

    event BonusPayout(uint256 amount);

    uint256 bonusThreshold;
    address lendingPool;
    address nativeAsset;
    address devVault;
    address aToken;
    address eToken;
    
    constructor(address _wmatic, address _bonusAddress, address _devVault, address _aTokenAddress, address _nativeAssetAddress, address _lendingPoolAddress, address _QSRouter) {
        WMATIC = IWMATIC(_wmatic);
        bonusClaimer = IBonusClaimer(_bonusAddress);
        devVault = _devVault;

        aToken = _aTokenAddress;
        nativeAsset = _nativeAssetAddress;
        lendingPool = _lendingPoolAddress;
        bonusThreshold = 1;
        QSRouter = IQSRouter(_QSRouter);
    }

// ********************** MODIFIERS, GETTERS, & SETTERS *************************

    // Requires the caller to be the eToken contract for the correlating aToken
    modifier onlyEToken() {
        require(msg.sender == eToken, "Only the eToken contract can call this.");
        _;
    }

    function setETokenAddress(address _eToken) external onlyOwner whenPaused {
        eToken = _eToken;
    }

    function setRouterAddress(address _router) external onlyOwner whenPaused {
        router = IEonsERC20AaveRouter(_router);
    }

    function setDevVaultAddress(address _devVault) external onlyOwner {
        devVault = _devVault;
    }

    function setBonusThreshold(uint256 _newThreshold) external onlyOwner {
        bonusThreshold = _newThreshold;
    }

    function setQSRouter(address _QSRouter) external onlyOwner whenPaused {
        QSRouter = IQSRouter(_QSRouter);
    }

// ****************************** EDIT ASSETS *********************************

    // @dev
    // update support for a coin or token. index is the asset's index in the assetInfo
    // map, _asset is the coin or token's contract address, and _eTokenAddress is the
    //  eToken address created for that asset, and _aTokenAddress is the AAVE token 
    // address created for that asset
    function editAsset(address _lendingPool) external onlyOwner whenPaused {
        // assign values to AssetInfo and save to supportedAssets index of assetInfo,
        // and keep pool values the same
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
        IAToken(aToken).transfer(devVault, _amount);
    }

// ************************* DEPOSITS AND WITHDRAWALS ****************************

    // @dev
    // web3 frontend interface must first approve their asset to be transfered by
    // the AAVE router contract, otherwise it will revert
    // deposit function handles both new deposits and deposits on top of previous ones
    // made by the same user.
    function deposit(uint256 _amount) external nonReentrant whenNotPaused {

        // just your basic security checks
        require(_amount > 0, "You can't deposit nothing.");

        // mint eTokens to msg.sender
        IeaEons(eToken).mint(msg.sender, _amount);
        // call deposit() on router, send current _amount
        router.deposit(nativeAsset, _amount, msg.sender, lendingPool);

        emit Deposit(msg.sender, nativeAsset, _amount);
    }

    // @dev
    // web3  This is the amount of the native asset that will be returned to msg.sender
    function withdraw(uint _amount) external nonReentrant whenNotPaused {

        // just your basic security checks
        require(_amount > 0, "You can't withdraw nothing.");
        require(_amount <= IeaEons(eToken).balanceOf(msg.sender), "You don't have the funds for that.");

        // If threshold for bonus is met, retrieve bonus and reinvest it back into
        // the aToken balance
        // ************** UNCOMMENT FOR MAINNET / FORK TESTS ***************
        getBonus();

        // burn eTokens from msg.sender
        IeaEons(eToken).burn(msg.sender, _amount);
        // transfer aTokens to router
        IAToken(aToken).transfer(address(router), _amount);
        // call withdraw() on router
        router.withdraw(nativeAsset, _amount, aToken, msg.sender, lendingPool);

        emit Withdraw(msg.sender, nativeAsset, _amount);
    }

 // ************************ UNWRAP AND REDEPOSIT WMATIC ***************************
    
    // retrieve bonus from AAVE and re-deposit rewards
    function getBonus() internal {

        address[] memory aTokenArray = new address[](1);
        aTokenArray[0] = aToken;
        // call getRewardsBalance to check the total owed
        // send aToken address and vault address as params
        uint256 totalOwed = bonusClaimer.getRewardsBalance(aTokenArray, address(this));
        // check that bonus meets the minimum threshold for retrieving

        // COME UP WITH SOME LOGICAL THRESHOLD TO PUT HERE FOR WITHDRAWAL
        if (totalOwed > bonusThreshold) {
            // Send total owed through AAVE and add to total aToken supply
            bonusClaimer.claimRewards(aTokenArray, totalOwed, address(this));

            // Approve nativeAsset transfer to Quickswap
            IERC20(nativeAsset).approve(address(QSRouter), totalOwed);

            // Create array for quickswap route
            address[2] memory pair = [address(WMATIC), nativeAsset];
            
            // Quickswap convert WMATIC to nativeAsset
            uint256[] memory amounts = QSRouter.swapExactTokensForTokens(totalOwed, 0, pair, address(this), 10000000);
            // Deposit nativeAsset into router, bypassing minting and depositing aTokens
            router.deposit(nativeAsset, amounts[1], address(this), lendingPool);

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
        uint256 amount = IAToken(aToken).balanceOf(address(this));
        IAToken(aToken).transfer(msg.sender, amount);
    }
}