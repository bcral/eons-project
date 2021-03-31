// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IFeeApprover {
    function check(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setPaused(bool _pause) external;

    function setFeeMultiplier(uint256 _feeMultiplier) external;

    function feePercentX100() external view returns (uint256);

    function setTokenUniswapPair(address _tokenUniswapPair) external;

    function setEonsVaultAddress(address _EonsVaultAddress) external;

    function sync() external;

    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (uint256 transferToAmount, uint256 transferToFeeBearerAmount);
}
