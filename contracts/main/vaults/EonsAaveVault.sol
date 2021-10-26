// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';


import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IeaEons.sol';
import '../../peripheries/interfaces/IEonsAaveRouter.sol';
import '../../peripheries/interfaces/IAToken.sol';
import '../../peripheries/interfaces/IiEonsController.sol';

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

    event Deposit(address indexed user, address asset, uint256 amount);
    event Withdraw(address indexed user, address asset, uint256 amount);

    IEonsAaveRouter public router;
    IiEonsController public controller;

    // Dev fee values, mapped from aToken address
    mapping(address => uint256) storedDevFees;
    // Previously withdrawn dev fees, mapped from aToken address
    mapping(address => uint256) withdrawnDevFees;

    mapping(address => bool) userDiscount;

    struct AssetInfo {
        address aToken;
        address eToken;
        uint256 standard;
        uint256 discounted;
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
        supportedAssets = 0;
        __Ownable_init();
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
        return(storedDevFees[_aToken]);
    }

    // if discount is applied, returns true
    function getMyDiscountStatus(address _user) public view returns(bool) {
        return userDiscount[_user];
    }

// *************************** ADD & EDIT ASSETS ******************************

    // @dev
    // add support for a new coin or token.  _asset is the coin or token's contract
    // address, and _eTokenAddress is the eToken address created for that asset, and
    // _aTokenAddress is the AAVE token address created for that asset
    // add onlyOwner back after testing
    function addAsset(address _asset, address _eTokenAddress, address _aTokenAddress) external onlyOwner {
        // increment supported assets first
        supportedAssets ++;
        // assign values to AssetInfo and save to supportedAssets index of assetInfo,
        // and set initial values of standard and discounted pools to 0
        assetInfo[supportedAssets] = AssetInfo({eToken: _eTokenAddress, aToken: _aTokenAddress, standard: 0, discounted: 0});
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
    function editAsset(uint256 _index, address _asset, address _eTokenAddress, address _aTokenAddress) external onlyOwner {
        // assign values to AssetInfo and save to supportedAssets index of assetInfo,
        // and keep pool values the same
        assetInfo[_index] = AssetInfo({eToken: _eTokenAddress, aToken: _aTokenAddress, standard: assetInfo[_index].standard, discounted: assetInfo[_index].discounted});
        // map the native asset's address to the assetInfo index for ease of search
        nativeAssetInfo[_asset] = _index;
        // map the asset's aToken address to the assetInfo index for ease of search
        aTokenAssetInfo[_aTokenAddress] = _index;
    }

// ******************************* FEE STUFF **********************************

    // @dev
    // withdraws all stored dev fees in the native aToken.  Includes reentrancy 
    // protection, and only the available % of rewards are ever available at any time.
    function withdrawDevFees(address _aToken, uint256 _amount, address _devWallet) external onlyController {
        AssetInfo memory assetTokens = assetInfo[aTokenAssetInfo[_aToken]];
        // Make sure the dev has that much available to withdraw
        require((storedDevFees[assetTokens.aToken] - withdrawnDevFees[assetTokens.aToken]) >= _amount, "You don't have that much available.");
        // Yes, even the dev can't reenter here
        uint256 devFees = storedDevFees[assetTokens.aToken];
        storedDevFees[assetTokens.aToken] = 0;
        // Transfer the desired amount to the wallet passed as argument
        IAToken(assetTokens.aToken).transfer(_devWallet, _amount);
        // Update dev's current fee availability
        storedDevFees[assetTokens.aToken] = devFees;
    }

    // sorts and stores user's balance in the correct pool based on their current
    // fee status at the time of deposit.
    function storeFeeBalance(address _asset, address _user, uint256 _amount, bool _discount)
        internal
    {
        AssetInfo memory assetTokens = assetInfo[nativeAssetInfo[_asset]];
        // if discount applies...
        if(_discount) {
            // if true, discount previously applied, and still does.
            // add deposited amount to discount
            if(userDiscount[_user]) {
                assetTokens.discounted += _amount;
            // if false, discount did not previousl apply, but now does.
            // subract user's current eToken total from standard pool, and move to
            // discounted pool
            } else {
                assetTokens.standard -= IeaEons(assetTokens.eToken).balanceOf(_user);
                assetTokens.discounted += IeaEons(assetTokens.eToken).balanceOf(_user);
            }
        // if discount does not apply...
        } else {
            // if true, discount previously did apply, but now does not.
            // subtract user's current eToken total from discounted pool, and move
            // to standard pool
            if(userDiscount[_user]) {
                assetTokens.discounted -= IeaEons(assetTokens.eToken).balanceOf(_user);
                assetTokens.standard += IeaEons(assetTokens.eToken).balanceOf(_user);
            // if false, discount previously did not apply, and still does not.
            // add deposited amount to standard
            } else {
                assetTokens.standard += _amount;
            }
        }
        // store user's current discount status
        userDiscount[_user] = _discount;
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
        router.deposit(_asset, _amount, msg.sender);

        // mint eTokens to msg.sender
        IeaEons(assetTokens.eToken).mint(msg.sender, _amount);

        // get user's current discount status
        bool currentStat = controller.getUsersDiscountStat(msg.sender);

        // get assetInfo by index, user, and user's current discount status
        storeFeeBalance(_asset, msg.sender, _amount, currentStat);

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

        // Check user's discount status from deposit to determine where to pull
        // funcds from
        if (userDiscount[msg.sender]) {
            assetTokens.discounted -= _amount;
        } else {
            assetTokens.standard -= _amount;
        }

        // transfer aTokens to router
        IAToken(assetTokens.aToken).transfer(address(router), _amount);
        // burn eTokens
        IeaEons(assetTokens.eToken).burn(msg.sender, _amount);
        // call withdraw() on router
        router.withdraw(_asset ,_amount, assetTokens.aToken, msg.sender);

        emit Withdraw(msg.sender, _asset, _amount);
    }
}