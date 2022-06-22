// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakePlatypus {
    function deposit(uint256 _pid, uint256 _amount)
        external
        returns (uint256, uint256);
}
