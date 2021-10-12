// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';


import '../../peripheries/interfaces/ILendingPool.sol';
import '../../peripheries/interfaces/IeEons.sol';
import '../../peripheries/interfaces/IEonsAaveRouter.sol';

  // Vault core functionality:
  // -store account's aToken values/hold actual aTokens here
  // -mint EaToken to account address for each deposit
  // Deposit flow:
  //    -before deposit, approve transfer to router
  //    -call deposit function in router
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
    IeEons public eons;

    mapping(uint256 => uint256) public userCountInPool; // pid => user holder count
    
    function initialize(address _eons, address _dev, address _router) external initializer {
        eons = IeEons(_eons);
        router = IEonsAaveRouter(_router);
        __Ownable_init();
    }

    function setRouterAddress(address _router) external onlyOwner {
        router = IEonsAaveRouter(_router);
    }


    function add() external onlyOwner {

    }

    // @dev
    // web3 frontend interface must first approve their asset to be transfered by
    // the AAVE router contract, otherwise it will revert
    function deposit(address _asset, uint256 _amount) external {

        require(_amount > 0, "You can't deposit nothing.");

        router.deposit(_asset, _amount, msg.sender);

        updateEmissionDistribution();

        eons.mint(msg.sender, _amount);

        emit Deposit(msg.sender, _asset, _amount);
    }


    function withdraw(uint _amount, address _asset) external {

        require(_amount > 0, "You can't withdraw nothing.");

        updateEmissionDistribution();

        // transfer aTokens to router

        // burn eTokens

        router.withdraw(_amount, msg.sender);

        emit Withdraw(msg.sender, _asset, _amount);
    }

    // Likely replaced by call to outside contract for calculations
    function updateEmissionDistribution() public {

    }
}