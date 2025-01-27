// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {BabushkaToken} from "@babushka/BabushkaToken.sol";
import {IBabushkaToken} from "@babushka/interfaces/IBabushkaToken.sol";
import {IBabushkaTokenLogic} from "@babushka/interfaces/IBabushkaTokenLogic.sol";
import {IBabushkaMint} from "@babushka/interfaces/IBabushkaMint.sol";

contract BabushkaMint is IBabushkaMint {
    using Strings for uint256;
    
    IBabushkaTokenLogic[] private logics;
    mapping(IBabushkaTokenLogic => bool) private logicExists;
    mapping(IBabushkaToken => uint256) private tokenChildren;
    mapping(IBabushkaToken => bytes) private pathByBabushkaToken;

    function addLogic(IBabushkaTokenLogic logic) external returns (uint256 logicIndex) {
        require(!logicExists[logic], LogicAlreadyExists(logic));
        logics.push(logic);
        logicExists[logic] = true;
        logicIndex = logics.length - 1;
    }

    // note: parent might be a regular erc20
    function createBabushkaToken(IBabushkaToken parent, uint256 logicIndex) external returns (IBabushkaToken result) {
        require(logicIndex < logics.length, LogicIndexOutOfRange(logicIndex));
        IBabushkaTokenLogic logic = logics[logicIndex];
        bytes memory path = pathByBabushkaToken[parent];

        IBabushkaToken[] memory newPath;
        string memory symbol;

        if (path.length == 0) {
            newPath = new IBabushkaToken[](1);
            newPath[0] = parent;

        } else {
            IBabushkaToken[] memory previousPathAddresses = abi.decode(path, (IBabushkaToken[]));
            uint256 previousLength = previousPathAddresses.length;
            newPath = new IBabushkaToken[](previousLength + 1);
            assembly {
                mcopy(
                    add(newPath, 0x20), 
                    add(previousPathAddresses, 0x20), 
                    mul(mload(previousPathAddresses), 0x20)
                )
            }
            newPath[previousLength] = parent;
        }
        uint256 derivedFromRootIndex = ++tokenChildren[newPath[0]];
        // example:
        // babWETH1x2
        // the first babushka token derived from WETH, wrapped twice
        symbol = string.concat(
            "bab",
            newPath[0].symbol(),
            derivedFromRootIndex.toString(),
            "x",
            newPath.length.toString()
        );

        result = new BabushkaToken(
            string.concat("Babushka Token: ", symbol),
            symbol,
            IERC20(parent),
            logic
        );

        pathByBabushkaToken[result] = abi.encode(newPath);
    }

    function mintFromRoot(IBabushkaToken root) external {
        // TODO:
    }

    function burnToRoot(IBabushkaToken leaf) external {
        // TODO:
    }
}
