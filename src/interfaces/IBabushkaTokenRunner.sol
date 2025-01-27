// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25;

interface IBabushkaTokenRunnerErrors {
    error NotOwner(address caller, address owner);
    error RunReverted(bytes revertData);
}

interface IBabushkaTokenRunner is IBabushkaTokenRunnerErrors {}
