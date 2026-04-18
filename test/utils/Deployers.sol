// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Deployers as V4CoreDeployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

/// @notice Thin local wrapper around the official Uniswap v4 test deployers.
abstract contract Deployers is V4CoreDeployers {
    IPoolManager internal poolManager;

    function deployArtifacts() internal {
        deployFreshManagerAndRouters();
        poolManager = manager;
    }

    function deployCurrencyPair() internal virtual returns (Currency currency0, Currency currency1) {
        return deployMintAndApprove2Currencies();
    }
}
