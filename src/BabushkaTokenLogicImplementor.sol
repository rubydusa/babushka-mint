// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {WithWrappedToken} from "@babushka/WithWrappedToken.sol";

abstract contract BabushkaTokenLogicImplementor is WithWrappedToken {
    uint256[1000] __gap;
}
