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

contract Eonsv1Router is Ownable {
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
    ) public onlyOwner {
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

    function addLiquidityETHOnly(address payable to)
        public
        payable
    {
        // Store deposited eth in hardAlqo
        hardAlqo[msg.sender] = hardAlqo[msg.sender].add(msg.value);

        uint256 buyAmount = msg.value.div(2);
        require(buyAmount > 0, 'Insufficient ETH amount');

        _WETH.deposit{value: msg.value}();

        (uint256 reserveWeth, uint256 reserveAlqo) = getPairReserves();
        uint256 outAlqo = UniswapV2Library.getAmountOut(
            buyAmount,
            reserveWeth,
            reserveAlqo
        );

        _WETH.transfer(_eonsWETHPair, buyAmount);

        (address token0, address token1) = UniswapV2Library.sortTokens(
            address(_WETH),
            _alqoToken
        );

        IUniswapV2Pair(_eonsWETHPair).swap(
            _alqoToken == token0 ? outAlqo : 0,
            _alqoToken == token1 ? outAlqo : 0,
            address(this),
            ''
        );

        _addLiquidity(outAlqo, buyAmount, to);

        _feeApprover.sync();
    }

    function _addLiquidity(
        uint256 alqoAmount,
        uint256 wethAmount,
        address payable to
    ) internal {
        (uint256 wethReserve, uint256 alqoReserve) = getPairReserves();

        // Get the amount of ALQO token representing equivalent value to weth amount
        uint256 optimalAlqoAmount = UniswapV2Library.quote(
            wethAmount,
            wethReserve,
            alqoReserve
        );

        uint256 optimalWETHAmount;

        if (optimalAlqoAmount > alqoAmount) {
            optimalWETHAmount = UniswapV2Library.quote(
                alqoAmount,
                alqoReserve,
                wethReserve
            );
            optimalAlqoAmount = alqoAmount;
        } else optimalWETHAmount = wethAmount;

        assert(_WETH.transfer(_eonsWETHPair, optimalWETHAmount));
        assert(
            IERC20(_alqoToken).transfer(_eonsWETHPair, optimalAlqoAmount)
        );

        IUniswapV2Pair(_eonsWETHPair).mint(address(this));
        _eonsVault.depositFor(
            to,
            0,
            IUniswapV2Pair(_eonsWETHPair).balanceOf(address(this))
        );

        //refund dust
        if (alqoAmount > optimalAlqoAmount)
            IERC20(_alqoToken).transfer(
                to,
                alqoAmount.sub(optimalAlqoAmount)
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
        (uint256 reserveWeth, uint256 reserveAlqo) = getPairReserves();
        uint256 outHal9k = UniswapV2Library.getAmountOut(
            ethAmt.div(2),
            reserveWeth,
            reserveAlqo
        );
        uint256 _totalSupply = IUniswapV2Pair(_eonsWETHPair).totalSupply();

        (address token0, ) = UniswapV2Library.sortTokens(
            address(_WETH),
            _alqoToken
        );
        (uint256 amount0, uint256 amount1) = token0 == _alqoToken
            ? (outAlqo, ethAmt.div(2))
            : (ethAmt.div(2), outAlqo);
        (uint256 _reserve0, uint256 _reserve1) = token0 == _alqoToken
            ? (reserveAlqo, reserveWeth)
            : (reserveWeth, reserveAlqo);
            
        liquidity = Math.min(
            amount0.mul(_totalSupply) / _reserve0,
            amount1.mul(_totalSupply) / _reserve1
        );
    }

    function getPairReserves()
        internal
        view
        returns (uint256 wethReserves, uint256 alqoReserves)
    {
        (address token0, ) = UniswapV2Library.sortTokens(
            address(_WETH),
            _alqoToken
        );
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_eonsWETHPair)
            .getReserves();
        (wethReserves, alqoReserves) = token0 == _alqoToken
            ? (reserve1, reserve0)
            : (reserve0, reserve1);
    }
}
