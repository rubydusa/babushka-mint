// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

interface IBabushkaTokenLogic {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external returns (uint256 returnAmount);
}
