// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../interfaces/IFeeApprover.sol';
import '../interfaces/IEonsUniVault.sol';
import '../libraries/Math.sol';
import '../libraries/UniswapV2Library.sol';

contract EonsUniswapRouter is OwnableUpgradeable {
	mapping(address => uint256) public hardEons;

	address public _eonsToken;
	address public _eonsWETHPair;
	IFeeApprover public _feeApprover;
	IEonsUniVault public _eonsUniVault;
	IWETH public _WETH;
	address public _uniV2Factory;
	uint private _uniLpIncome;

	event FeeApproverChanged(address indexed newAddress, address indexed oldAddress);

	function initialize(address eonsToken, address WETH, address uniV2Factory, address feeApprover, address eonsUniVault) external initializer {
		_eonsToken = eonsToken;
		_WETH = IWETH(WETH);
		_uniV2Factory = uniV2Factory;
		_feeApprover = IFeeApprover(feeApprover);
		_eonsWETHPair = IUniswapV2Factory(_uniV2Factory).getPair(
				WETH,
				_eonsToken
		);
		_eonsUniVault = IEonsUniVault(eonsUniVault);
		// IUniswapV2Pair(_eonsWETHPair).approve(
		// 		address(_eonsUniVault),
		// 		uint256(-1)
		// );
	}

	function refreshApproval() external {
		IUniswapV2Pair(_eonsWETHPair).approve(
				address(_eonsUniVault),
				type(uint256).max
		);
	}

	fallback() external payable {
		if (msg.sender != address(_WETH)) {
			addLiquidityETHOnly(payable(msg.sender));
		}
	}

	function getLpAmount() external onlyOwner returns(uint amount) {
		_uniLpIncome = IUniswapV2Pair(_eonsWETHPair).balanceOf(address(this));
		return _uniLpIncome;
	}

	function getTotalSupplyOfUniLp() external view returns(uint amount) {
		return IUniswapV2Pair(_eonsWETHPair).totalSupply();
	}

	function addLiquidity(address payable to, uint256 eonsAmount) external payable {
		(uint256 reserveWeth, uint256 reserveEons) = getPairReserves();
		uint256 outEons = UniswapV2Library.getAmountOut(
			msg.value,
			reserveWeth,
			reserveEons
		);
		require(outEons <= eonsAmount, 'Invalid eons token amount');

		_WETH.deposit{value: msg.value}();

		_WETH.transfer(_eonsWETHPair, msg.value);
		(address token0, address token1) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);

		IUniswapV2Pair(_eonsWETHPair).swap(
			_eonsToken == token0 ? outEons : 0,
			_eonsToken == token1 ? outEons : 0,
			address(this),
			''
		);
		_addLiquidity(eonsAmount, msg.value, to);

		_feeApprover.sync();
	}

	function addLiquidityETHOnly(address payable to)
		public
		payable
	{
			// Store deposited eth in hardEons
		hardEons[msg.sender] = hardEons[msg.sender] + msg.value;

		uint256 buyAmount = msg.value/2;
		require(buyAmount > 0, 'Insufficient ETH amount');

		_WETH.deposit{value: msg.value}();

		(uint256 reserveWeth, uint256 reserveEons) = getPairReserves();
		uint256 outEons = UniswapV2Library.getAmountOut(
			buyAmount,
			reserveWeth,
			reserveEons
		);

		_WETH.transfer(_eonsWETHPair, buyAmount);

		(address token0, address token1) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);

		IUniswapV2Pair(_eonsWETHPair).swap(
			_eonsToken == token0 ? outEons : 0,
			_eonsToken == token1 ? outEons : 0,
			address(this),
			''
		);

		_addLiquidity(outEons, buyAmount, to);

		_feeApprover.sync();
	}

	    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to
    ) public virtual returns (uint amountA, uint amountB) {
        IUniswapV2Pair(_eonsWETHPair).transferFrom(msg.sender, _eonsWETHPair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(_eonsWETHPair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to
    ) external virtual returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            address(_WETH),
            liquidity,
            address(this)
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        _WETH.withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

	function _addLiquidity(
		uint256 eonsAmount,
		uint256 wethAmount,
		address payable to
	) internal {
		(uint256 wethReserve, uint256 eonsReserve) = getPairReserves();

			// Get the amount of ALQO token representing equivalent value to weth amount
		uint256 optimalEonsAmount = UniswapV2Library.quote(
			wethAmount,
			wethReserve,
			eonsReserve
		);

		uint256 optimalWETHAmount;

		if (optimalEonsAmount > eonsAmount) {
			optimalWETHAmount = UniswapV2Library.quote(
				eonsAmount,
				eonsReserve,
				wethReserve
			);
			optimalEonsAmount = eonsAmount;
		} else optimalWETHAmount = wethAmount;

		assert(_WETH.transfer(_eonsWETHPair, optimalWETHAmount));
		assert(
			IERC20(_eonsToken).transfer(_eonsWETHPair, optimalEonsAmount)
		);

		uint lp = IUniswapV2Pair(_eonsWETHPair).mint(address(this));

		_eonsUniVault.depositFor(to, 0, lp);

		//refund dust
		if (eonsAmount > optimalEonsAmount)
			IERC20(_eonsToken).transfer(
				to,
				eonsAmount-optimalEonsAmount
			);

		if (wethAmount > optimalWETHAmount) {
			uint256 withdrawAmount = wethAmount-optimalWETHAmount;
			_WETH.withdraw(withdrawAmount);
			to.transfer(withdrawAmount);
		}
	}

	function changeFeeApprover(address feeApprover) external onlyOwner {
		address oldAddress = address(_feeApprover);
		_feeApprover = IFeeApprover(feeApprover);

		emit FeeApproverChanged(feeApprover, oldAddress);
	}

	function getLPTokenPerEthUnit(uint256 ethAmt)
		external
		view
		returns (uint256 liquidity)
	{
		(uint256 reserveWeth, uint256 reserveEons) = getPairReserves();
		uint256 outEons = UniswapV2Library.getAmountOut(
			ethAmt/2,
			reserveWeth,
			reserveEons
		);
		uint256 _totalSupply = IUniswapV2Pair(_eonsWETHPair).totalSupply();

		(address token0, ) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);
		(uint256 amount0, uint256 amount1) = token0 == _eonsToken
			? (outEons, ethAmt/2)
			: (ethAmt/2, outEons);
		(uint256 _reserve0, uint256 _reserve1) = token0 == _eonsToken
			? (reserveEons, reserveWeth)
			: (reserveWeth, reserveEons);
				
		liquidity = Math.min(
			amount0*_totalSupply / _reserve0,
			amount1*_totalSupply / _reserve1
		);
	}

	function getPairReserves()
		internal
		view
		returns (uint256 wethReserves, uint256 eonsReserves)
	{
		(address token0, ) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);
		(uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_eonsWETHPair)
			.getReserves();
		(wethReserves, eonsReserves) = token0 == _eonsToken
			? (reserve1, reserve0)
			: (reserve0, reserve1);
	}
}
