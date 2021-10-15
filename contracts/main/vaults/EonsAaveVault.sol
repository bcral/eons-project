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
  //    -call deposit function in router
  //        X Called with all required arguments
  //    -update emissions - do this here to prevent flash-loan exploitation?
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

    address feeAddress;

    struct AssetInfo {
        address aToken;
        address eToken;
    }
    // map AssetInfo by indexer(supportedAssets)
    mapping(uint => AssetInfo) public assetInfo;
    // search for assetInfo by native asset address
    mapping(address => uint) public nativeAssetInfo;
    // search for assetInfo by aToken address
    mapping(address => uint) public aTokenAssetInfo;
    // counter for total supported assets(used as index)
    uint256 public supportedAssets;
    
    function initialize(address _eons) external initializer {
        supportedAssets = 0;
        __Ownable_init();
    }

    function setRouterAddress(address _router) external onlyOwner {
        router = IEonsAaveRouter(_router);
    }

    function setControllerAddress(address _controller) external onlyOwner {
        controller = IiEonsController(_controller);
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    // @dev
    // add support for a new coin or token.  _asset is the coin or token's contract
    // address, and _eTokenAddress is the eToken address created for that asset, and
    // _aTokenAddress is the AAVE token address created for that asset
    function addAsset(address _asset, address _eTokenAddress, address _aTokenAddress) external onlyOwner {
        // increment supported assets first
        supportedAssets ++;
        // assign values to AssetInfo and save to supportedAssets index of assetInfo
        assetInfo[supportedAssets] = AssetInfo({eToken: _eTokenAddress, aToken: _aTokenAddress});
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
    function editAsset(uint256 index, address _asset, address _eTokenAddress, address _aTokenAddress) external onlyOwner {
        // assign values to AssetInfo and save to supportedAssets index of assetInfo
        assetInfo[index] = AssetInfo({eToken: _eTokenAddress, aToken: _aTokenAddress});
        // map the native asset's address to the assetInfo index for ease of search
        nativeAssetInfo[_asset] = index;
        // map the asset's aToken address to the assetInfo index for ease of search
        aTokenAssetInfo[_aTokenAddress] = index;
    }

    // @dev
    // web3 frontend interface must first approve their asset to be transfered by
    // the AAVE router contract, otherwise it will revert
    function deposit(address _asset, uint256 _amount) external {

        // Search the assetInfo mapping for a token at the index found by passing
        // nativeAssetInfo[_asset] as an argument
        AssetInfo memory assetTokens = assetInfo[nativeAssetInfo[_asset]];

        // just your basic security checks
        require(assetTokens.aToken != address(0), "That coin or token is not supported(yet!).");
        require(_amount > 0, "You can't deposit nothing.");

        // send transaction to take dev fee, call must be made from vault
        (uint256 devFee, address contTreasury) = router.updateComission(assetTokens.aToken, assetTokens.eToken);
        IAToken(assetTokens.aToken).transfer(address(contTreasury), devFee);

        // call deposit() on router
        router.deposit(_asset, _amount, msg.sender);

        // mint eTokens to msg.sender - amount isn't really critical here
        IeaEons(assetTokens.eToken).mint(msg.sender, _amount);

        emit Deposit(msg.sender, _asset, _amount);
    }

    // @dev
    // web3 frontend call must be made with the native asset's address as the _asset
    // argument.  This is the asset that will be returned to msg.sender
    function withdraw(uint _amount, address _asset) external {
        // Search the assetInfo mapping for a token at the index found by passing
        // nativeAssetInfo[_asset] as an argument
        AssetInfo memory assetTokens = assetInfo[nativeAssetInfo[_asset]];
        // just your basic security checks
        require(assetTokens.aToken != address(0), "That coin or token is not supported(yet!).");
        require(_amount > 0 && _amount <= IeaEons(assetTokens.eToken).balanceOf(msg.sender), "You can't withdraw nothing.");

        // send transaction to take dev fee, call must be made from vault
        (uint256 devFee, address contTreasury) = router.updateComission(assetTokens.aToken, assetTokens.eToken);
        IAToken(assetTokens.aToken).transfer(address(contTreasury), devFee);

        // transfer aTokens to router
        IAToken(assetTokens.aToken).transfer(address(router), _amount);
        // burn eTokens
        IeaEons(assetTokens.eToken).burn(msg.sender, _amount);
        // call withdraw() on router
        router.withdraw(_asset ,_amount, assetTokens.aToken, msg.sender);

        emit Withdraw(msg.sender, _asset, _amount);
    }
}