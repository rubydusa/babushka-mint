// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// SHOULD NOT READ INTERNAL ERC20 DATA
// SHOULD IMPLEMENT ITS OWN STORAGE
interface IBabushkaTokenLogic {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external returns (uint256 returnAmount);
}

interface IBabushkaTokenErrors {
    error MintError(bytes revertdata);
    error BurnError(bytes revertdata);
}

interface IBabushkaToken is IERC20Metadata, IBabushkaTokenErrors {}

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

abstract contract BabushkaTokenLogicImplementor is WithWrappedToken {
    uint256[1000] __gap;
}

interface IBabushkaTokenRunnerErrors {
    error NotOwner(address caller, address owner);
    error RunReverted(bytes revertData);
}
interface IBabushkaTokenRunner is IBabushkaTokenRunnerErrors {}

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

contract BabushkaToken is ERC20, ReentrancyGuard, IBabushkaToken {
    using SafeERC20 for IERC20;

    IERC20 private immutable wrappedToken;
    BabushkaTokenRunner private immutable runner;

    constructor(
        string memory _name,
        string memory _symbol,
        IERC20 _wrappedToken,
        IBabushkaTokenLogic _logic
    ) ERC20(_name, _symbol) {
        wrappedToken = _wrappedToken;
        runner = new BabushkaTokenRunner(_wrappedToken, _logic);
    }

    function mint(uint256 amount) external nonReentrant {
        wrappedToken.safeTransferFrom(msg.sender, address(runner), amount);
        runner.run(abi.encodeCall(IBabushkaTokenLogic.deposit, (amount)));
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external nonReentrant {
        _burn(msg.sender, amount);
        bytes memory returnData = runner.run(abi.encodeCall(IBabushkaTokenLogic.withdraw, (amount)));
        uint256 received = abi.decode(returnData, (uint256));
        wrappedToken.safeTransferFrom(address(runner), msg.sender, received);
    }
}

interface IBabushkaMintErrors {
    error LogicAlreadyExists(IBabushkaTokenLogic logic);
    error LogicIndexOutOfRange(uint256 logicIndex);
}

interface IBabushkaMint is IBabushkaMintErrors { }

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
