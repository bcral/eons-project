// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // for WETH
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "hardhat/console.sol";

contract FeeApprover is Ownable {

	// In this contract, e do calculate fee and the real amount to be sent to the recepient

	function initialize(address _EonsAddress, address _WETHAddress, address _uniswapFactory) public {
		eonsTokenAddress = _EonsAddress;
		WETHAddress = _WETHAddress;
		tokenUniswapPair = IUniswapV2Factory(_uniswapFactory).getPair(
			WETHAddress,
			eonsTokenAddress
		);
		feePercentX100 = 10;
		paused = true; // We start paused until sync post LGE happens.
	}

	address tokenUniswapPair;
	IUniswapV2Factory public uniswapFactory;
	address internal WETHAddress;
	address eonsTokenAddress;
	address eonsVaultAddress;
	uint8 public feePercentX100; // max 255 = 25.5% artificial clamp
	uint256 public lastTotalSupplyOfLPTokens;
	bool paused;

    // HAL9K token is pausable
	function setPaused(bool _pause) public onlyOwner {
		paused = _pause;
	}

	function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
		feePercentX100 = _feeMultiplier;
	}

	function setEonsVaultAddress(address _eonsVaultAddress) public onlyOwner {
		eonsVaultAddress = _eonsVaultAddress;
	}

	function sync() public {
		uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();
		lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
	}

	function calculateAmountsAfterFee(
		address sender,
		address recipient, // unusued maybe use din future
		uint256 amount
	)
		public
		returns (
				uint256 transferToAmount,
				uint256 transferToFeeDistributorAmount
		)
	{
		require(paused == false, "FEE APPROVER: Transfers Paused");
		uint256 _LPSupplyOfPairTotal = IERC20(tokenUniswapPair).totalSupply();

		if (sender == tokenUniswapPair)
			require(
				lastTotalSupplyOfLPTokens <= _LPSupplyOfPairTotal,
				"Liquidity withdrawals forbidden"
			);

		if (sender == eonsVaultAddress || sender == tokenUniswapPair) {
				// Dont have a fee when eonsvault is sending, or infinite loop
				// And when pair is sending ( buys are happening, no tax on it)
			transferToFeeDistributorAmount = 0;
			transferToAmount = amount;
		} else {
			transferToFeeDistributorAmount = amount*feePercentX100/1000;
			transferToAmount = amount-transferToFeeDistributorAmount;
		}

		lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
	}
}
