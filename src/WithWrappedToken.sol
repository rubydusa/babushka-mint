// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract WithWrappedToken {
    // bytes32(uint256(keccak256("babushka.wrappedToken")) - 1);
    bytes32 internal constant _WRAPPED_TOKEN_SLOT = 0x46603e38c214c4e82c847c6de0b40d6688a8b07e09019e0173cee29b8dfca96a;

    // SHOULD be called only by runner
    function __setWrappedToken(IERC20 wrappedToken) internal {
        assembly {
            sstore(_WRAPPED_TOKEN_SLOT, wrappedToken)
        }
    }

    function _getWrappedToken() internal view returns (IERC20 wrappedToken) {
        assembly {
            wrappedToken := sload(_WRAPPED_TOKEN_SLOT)
        }
    }
}
