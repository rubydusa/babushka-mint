// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBabushkaTokenErrors {
    error MintError(bytes revertdata);

    error BurnError(bytes revertdata);
}

interface IBabushkaToken is IERC20Metadata, IBabushkaTokenErrors {}
