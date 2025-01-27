// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {IBabushkaTokenLogic} from "@babushka/interfaces/IBabushkaTokenLogic.sol";

interface IBabushkaMintErrors {
    error LogicAlreadyExists(IBabushkaTokenLogic logic);
    error LogicIndexOutOfRange(uint256 logicIndex);
}

interface IBabushkaMint is IBabushkaMintErrors {}
