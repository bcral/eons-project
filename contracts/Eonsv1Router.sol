// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@uniswap/v2-core/contracts/libraries/UniswapV2Library.sol';
import '@uniswap/v2-core/contracts/libraries/Math.sol';
import '@uniswap/v2-core/contracts/interfaces/IWETH.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import './interfaces/IFeeApprover.sol';
import './EonsVault.sol';

contract Eonsv1Router is OwnableUpgradeSafe {
    using SafeMath for uint256;
    mapping(address => uint256) public hardAlqo;

    address public _alqoToken;
    address public _eonsWETHPair;
    IFeeApprover public _feeApprover;
    EonsVault public _eonsVault;
    IWETH public _WETH;
    address public _uniV2Factory;

    function initialize(
        address alqoToken,
        address WETH,
        address uniV2Factory,
        address feeApprover,
        address eonsVault
    ) public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        _alqoToken = alqoToken;
        _WETH = IWETH(WETH);
        _uniV2Factory = uniV2Factory;
        _feeApprover = IFeeApprover(feeApprover);
        _eonsWETHPair = IUniswapV2Factory(_uniV2Factory).getPair(
            WETH,
            _alqoToken
        );
        _eonsVault = EonsVault(eonsVault);
        refreshApproval();
    }

    function refreshApproval() public {
        IUniswapV2Pair(_eonsWETHPair).approve(
            address(_eonsVault),
            uint256(-1)
        );
    }

    event FeeApproverChanged(
        address indexed newAddress,
        address indexed oldAddress
    );

    fallback() external payable {
        if (msg.sender != address(_WETH)) {
            addLiquidityETHOnly(msg.sender, false);
        }
    }

    function addLiquidityETHOnly(address payable to, bool autoStake)
        public
        payable
    {
        // Store deposited eth in hardAlqo
        hardAlqo[msg.sender] = hardAlqo[msg.sender].add(msg.value);

        uint256 buyAmount = msg.value.div(2);
        require(buyAmount > 0, 'Insufficient ETH amount');

        _WETH.deposit{value: msg.value}();

        (uint256 reserveWeth, uint256 reserveHal9k) = getPairReserves();
        uint256 outHal9k = UniswapV2Library.getAmountOut(
            buyAmount,
            reserveWeth,
            reserveHal9k
        );

        _WETH.transfer(_eonsWETHPair, buyAmount);

        (address token0, address token1) = UniswapV2Library.sortTokens(
            address(_WETH),
            _alqoToken
        );

        IUniswapV2Pair(_eonsWETHPair).swap(
            _alqoToken == token0 ? outHal9k : 0,
            _alqoToken == token1 ? outHal9k : 0,
            address(this),
            ''
        );

        _addLiquidity(outHal9k, buyAmount, to, autoStake);

        _feeApprover.sync();
    }

    function _addLiquidity(
        uint256 hal9kAmount,
        uint256 wethAmount,
        address payable to,
        bool autoStake
    ) internal {
        (uint256 wethReserve, uint256 hal9kReserve) = getPairReserves();

        // Get the amount of Hal9K token representing equivalent value to weth amount
        uint256 optimalHal9kAmount = UniswapV2Library.quote(
            wethAmount,
            wethReserve,
            hal9kReserve
        );

        uint256 optimalWETHAmount;

        if (optimalHal9kAmount > hal9kAmount) {
            optimalWETHAmount = UniswapV2Library.quote(
                hal9kAmount,
                hal9kReserve,
                wethReserve
            );
            optimalHal9kAmount = hal9kAmount;
        } else optimalWETHAmount = wethAmount;

        assert(_WETH.transfer(_eonsWETHPair, optimalWETHAmount));
        assert(
            IERC20(_alqoToken).transfer(_eonsWETHPair, optimalHal9kAmount)
        );

        if (autoStake) {
            IUniswapV2Pair(_eonsWETHPair).mint(address(this));
            _eonsVault.depositFor(
                to,
                0,
                IUniswapV2Pair(_eonsWETHPair).balanceOf(address(this))
            );
        } else IUniswapV2Pair(_eonsWETHPair).mint(to);

        //refund dust
        if (hal9kAmount > optimalHal9kAmount)
            IERC20(_alqoToken).transfer(
                to,
                hal9kAmount.sub(optimalHal9kAmount)
            );

        if (wethAmount > optimalWETHAmount) {
            uint256 withdrawAmount = wethAmount.sub(optimalWETHAmount);
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
        public
        view
        returns (uint256 liquidity)
    {
        (uint256 reserveWeth, uint256 reserveHal9k) = getPairReserves();
        uint256 outHal9k = UniswapV2Library.getAmountOut(
            ethAmt.div(2),
            reserveWeth,
            reserveHal9k
        );
        uint256 _totalSupply = IUniswapV2Pair(_eonsWETHPair).totalSupply();

        (address token0, ) = UniswapV2Library.sortTokens(
            address(_WETH),
            _alqoToken
        );
        (uint256 amount0, uint256 amount1) = token0 == _alqoToken
            ? (outHal9k, ethAmt.div(2))
            : (ethAmt.div(2), outHal9k);
        (uint256 _reserve0, uint256 _reserve1) = token0 == _alqoToken
            ? (reserveHal9k, reserveWeth)
            : (reserveWeth, reserveHal9k);
            
        liquidity = Math.min(
            amount0.mul(_totalSupply) / _reserve0,
            amount1.mul(_totalSupply) / _reserve1
        );
    }

    function getPairReserves()
        internal
        view
        returns (uint256 wethReserves, uint256 hal9kReserves)
    {
        (address token0, ) = UniswapV2Library.sortTokens(
            address(_WETH),
            _alqoToken
        );
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_eonsWETHPair)
            .getReserves();
        (wethReserves, hal9kReserves) = token0 == _alqoToken
            ? (reserve1, reserve0)
            : (reserve0, reserve1);
    }
}
