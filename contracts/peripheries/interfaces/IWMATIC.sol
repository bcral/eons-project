// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IWMATIC {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function withdraw(uint) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address user) external returns (uint);
}