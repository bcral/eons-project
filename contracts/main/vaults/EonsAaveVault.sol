// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';


import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IeaEons.sol';
import '../../peripheries/interfaces/IEonsAaveRouter.sol';
import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/interfaces/IiEonsController.sol';
import '../../peripheries/interfaces/IWMATIC.sol';

  // Vault core functionality:
  // -store account's aToken values/hold actual aTokens here
  // -mint EaToken to account address for each deposit
  // Deposit flow:
  //    -before deposit, approve transfer to router
  //        X Added in notes for web3 to approve
  //    -check if user already has funds deposited.  if so, handle appropriately
  //    -call deposit function in router
  //        X Called with all required arguments
  //    -update fee status - do this here to prevent flash-loan exploitation?
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

contract EonsAaveVault is OwnableUpgradeable {
    using Roles for Roles.Role;

    event Deposit(address indexed user, address asset, uint256 amount);
    event Withdraw(address indexed user, address asset, uint256 amount);

    IEonsAaveRouter public router;
    IiEonsController public controller;

    mapping(address => bool) userDiscount;

    struct AssetInfo {
        address aToken;
        address eToken;
        uint256 deposits;
        // Previously withdrawn dev rewards
        uint256 withdrawnDevFees;
        address lendingPool;
    }
    // map AssetInfo by indexer(supportedAssets)
    mapping(uint => AssetInfo) public assetInfo;
    // search for assetInfo by native asset address
    mapping(address => uint) public nativeAssetInfo;
    // search for assetInfo by aToken address
    mapping(address => uint) public aTokenAssetInfo;
    // counter for total supported assets(used as index)
    uint256 public supportedAssets;
    
    function initialize() external initializer {
        __Ownable_init();
        supportedAssets = 1;
    }

// ********************** MODIFIERS, GETTERS, & SETTERS *************************

    modifier onlyController() {
        require(msg.sender == address(controller), "Only the controller can call that.");
        _;
    }

    function setRouterAddress(address _router) external onlyOwner {
        router = IEonsAaveRouter(_router);
    }

    function setControllerAddress(address _controller) external onlyOwner {
        controller = IiEonsController(_controller);
    }

    // returns the current total of fees collected from selected aToken pool
    function getAvailableDevFees(address _aToken) public view onlyController returns(uint256) {
        
    }

    // returns the withdrawn dev fees up to this point
    function getWithdrawnDevFees(address _aToken) public view returns(uint256) {
        // retrn withdrawnDevFees from assetInfo mapping with aToken address
        return(assetInfo[aTokenAssetInfo[_aToken]].withdrawnDevFees);
    }

// *************************** ADD & EDIT ASSETS ******************************

    // @dev
    // add support for a new coin or token.  _asset is the coin or token's contract
    // address, and _eTokenAddress is the eToken address created for that asset, and
    // _aTokenAddress is the AAVE token address created for that asset
    // add onlyOwner back after testing
    function addAsset(address _asset, address _eTokenAddress, address _aTokenAddress, address _lendingPool) external onlyOwner {
        // increment supported assets first
        supportedAssets ++;
        // assign values to AssetInfo and save to supportedAssets index of assetInfo,
        // and set initial values of standard and discounted pools to 0
        assetInfo[supportedAssets] = AssetInfo({eToken: _eTokenAddress, aToken: _aTokenAddress, deposits: 0, withdrawnDevFees: 0, lendingPool: _lendingPool});
        // map the native asset's address to the assetInfo index for ease of search
        nativeAssetInfo[_asset] = supportedAssets;
        // map the asset's aToken address to the assetInfo index for ease of search
        aTokenAssetInfo[_aTokenAddress] = supportedAssets;
    }

    // @dev
    // update support for a coin or token. index is the asset's index in the assetInfo
    // map, _asset is the coin or token's contract address, and _eTokenAddress is the
    //  eToken address created for that asset, and _aTokenAddress is the AAVE token 
    // address created for that asset
    function editAsset(uint256 _index, address _asset, address _eTokenAddress, address _aTokenAddress, address _lendingPool) external onlyOwner {
        // assign values to AssetInfo and save to supportedAssets index of assetInfo,
        // and keep pool values the same
        assetInfo[_index].eToken = _eTokenAddress;
        assetInfo[_index].aToken = _aTokenAddress;
        assetInfo[_index].lendingPool = _lendingPool;
        // map the native asset's address to the assetInfo index for ease of search
        nativeAssetInfo[_asset] = _index;
        // map the asset's aToken address to the assetInfo index for ease of search
        aTokenAssetInfo[_aTokenAddress] = _index;
    }

// ******************************* FEE STUFF **********************************

    // @dev
    // withdraws all stored dev fees in the native aToken.  Includes reentrancy 
    // protection, and only the available % of rewards are ever available at any time.
    function withdrawDevFees(address _aToken, uint256 _amount, address _devWallet) 
        external 
        onlyController 
    {
        AssetInfo memory assetTokens = assetInfo[aTokenAssetInfo[_aToken]];
        // Check the current amount of available fees for the dev to collect
        // Get actual difference in (total a + r) - totalSupply()
        uint256 availableToWithdraw = 2345352;
        // Make sure the dev has that much available to withdraw
        require(availableToWithdraw >= _amount, "You don't have that much available.");
        // Transfer the desired amount to the wallet passed as argument
        IAToken(assetTokens.aToken).transfer(_devWallet, _amount);
        // Add withdrawn amount to withdrawn dev fee total
        assetTokens.withdrawnDevFees += _amount;
    }

// ************************* DEPOSITS AND WITHDRAWALS ****************************

    // @dev
    // web3 frontend interface must first approve their asset to be transfered by
    // the AAVE router contract, otherwise it will revert
    // deposit function handles both new deposits and deposits on top of previous ones
    // made by the same user.
    // NEEDS REENTRANCY PROTECTION
    function deposit(address _asset, uint256 _amount) external {

        // Search the assetInfo mapping for a token at the index found by passing
        // nativeAssetInfo[_asset] as an argument
        AssetInfo memory assetTokens = assetInfo[nativeAssetInfo[_asset]];

        // just your basic security checks
        require(assetTokens.aToken != address(0), "That coin or token is not supported(yet!).");
        require(_amount > 0, "You can't deposit nothing.");

        // call deposit() on router, send current _amount
        router.deposit(_asset, _amount, msg.sender, assetTokens.lendingPool);
        // mint eTokens to msg.sender
        IeaEons(assetTokens.eToken).mint(msg.sender, _amount);
        // store deposited amount in the asset's rolling total

        
        // MUST WRITE TO MAPPING, NOT READ-ONNLY
        assetTokens.deposits += _amount;

        emit Deposit(msg.sender, _asset, _amount);
    }

    // @dev
    // web3 frontend call must be made with the native asset's address as the _asset
    // argument.  This is the asset that will be returned to msg.sender
    // NEEDS REENTRANCY PROTECTION
    function withdraw(uint _amount, address _asset) external {
        // Search the assetInfo mapping for a token at the index found by passing
        // nativeAssetInfo[_asset] as an argument
        AssetInfo memory assetTokens = assetInfo[nativeAssetInfo[_asset]];

        // just your basic security checks
        require(assetTokens.aToken != address(0), "That coin or token is not supported(yet!).");
        require(_amount > 0 && _amount <= IeaEons(assetTokens.eToken).balanceOf(msg.sender), "You can't withdraw 0.");

        // transfer aTokens to router
        IAToken(assetTokens.aToken).transfer(address(router), _amount);
        // burn eTokens
        IeaEons(assetTokens.eToken).burn(msg.sender, _amount);
        // call withdraw() on router
        router.withdraw(_asset ,_amount, assetTokens.aToken, msg.sender, assetTokens.lendingPool);
        // subtract amount from the asset's rolling total
        assetTokens.deposits += _amount;

        emit Withdraw(msg.sender, _asset, _amount);
    }

// ************************ NATIVE ASSET TRANSACTIONS ***************************

    // @dev
    // deposit function handles both new deposits and deposits on top of previous ones
    // made by the same user.  Only works for native token
    // NEEDS REENTRANCY PROTECTION
    function depositMATIC() external payable {
        // Search the assetInfo mapping for a token at the index found by passing
        // nativeAssetInfo[_asset] as an argument
        AssetInfo memory assetTokens = assetInfo[0];

        // just your basic security checks
        require(msg.value > 0, "You can't deposit nothing.");

        // send MATIC to router for transfer to AAVE
        router.depositMATIC{value: msg.value}(assetTokens.lendingPool);
        // mint eTokens to msg.sender
        IeaEons(assetTokens.eToken).mint(msg.sender, msg.value);
        // store deposited amount in the asset's rolling total
        assetTokens.deposits += msg.value;

        emit Deposit(msg.sender, address(0), msg.value);
    }


    // @dev
    // withdraw function handles all withdrawals in native token
    // NEEDS REENTRANCY PROTECTION
    function withdrawMATIC(uint256 _amount) external {
        // Search the assetInfo mapping for a token at the index found by passing
        // nativeAssetInfo[_asset] as an argument
        AssetInfo memory assetTokens = assetInfo[0];

        // just your basic security checks
        require(_amount > 0, "You can't deposit nothing.");

        // transfer user's withdrawn aTokens to the router to cash in
        IAToken(assetTokens.aToken).transfer(address(router), _amount);
        // mint eTokens to msg.sender
        IeaEons(assetTokens.eToken).burn(msg.sender, _amount);
        // call withdrawMATIC() on router, send current value
        router.withdrawMATIC(_amount, msg.sender, assetTokens.lendingPool);
        // subtract amount from the asset's rolling total
        assetTokens.deposits -= _amount;

        emit Deposit(msg.sender, address(0), _amount);
    }
}