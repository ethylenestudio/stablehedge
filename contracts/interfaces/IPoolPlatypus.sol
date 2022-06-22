// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPoolPlatypus {
    function deposit(
        address token,
        uint256 amount,
        address to,
        uint256 deadline
    ) external returns (uint256 liquidity);
}
