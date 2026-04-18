// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

/// @notice Shared setup for local Uniswap v4 scripts.
contract BaseScript is Script {
    IPoolManager internal immutable poolManager;
    uint256 internal immutable deployerPrivateKey;

    constructor() {
        poolManager = IPoolManager(vm.envAddress("POOL_MANAGER"));
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    }
}
