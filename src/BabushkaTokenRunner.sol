// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBabushkaTokenLogic} from "@babushka/interfaces/IBabushkaTokenLogic.sol";
import {IBabushkaTokenRunner} from "@babushka/interfaces/IBabushkaTokenRunner.sol";
import {WithWrappedToken} from "@babushka/WithWrappedToken.sol";

// this runner exists so the logic contract can't meddle with ERC20 storage variables
// when called with delegate call

// using WithWrappedToken so BabushkaTokenLogic implementors can easily accesss the token for which they were deployed
contract BabushkaTokenRunner is WithWrappedToken, IBabushkaTokenRunner {
    address private immutable owner;
    IBabushkaTokenLogic private immutable logic;

    constructor (
        IERC20 _wrappedToken,
        IBabushkaTokenLogic _logic
    ) {
        owner = msg.sender;
        logic = _logic;
        __setWrappedToken(_wrappedToken);
        _wrappedToken.approve(owner, type(uint256).max);
    }

    function run(bytes calldata _calldata) external returns (bytes memory returnData) {
        require(msg.sender == owner, NotOwner(msg.sender, owner));
        bool success;
        (success, returnData) = address(logic).delegatecall(_calldata);
        require(success, RunReverted(returnData));
    }
}
