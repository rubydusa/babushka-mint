// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {BabushkaTokenRunner} from "@babushka/BabushkaTokenRunner.sol";
import {IBabushkaToken} from "@babushka/interfaces/IBabushkaToken.sol";
import {IBabushkaTokenLogic} from "@babushka/interfaces/IBabushkaTokenLogic.sol";

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
