// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {Deployers} from "./Deployers.sol";

contract BaseTest is Deployers {
    function deployArtifactsAndLabel() internal {
        deployArtifacts();

        vm.label(address(poolManager), "V4PoolManager");
        vm.label(address(swapRouter), "V4SwapRouter");
        vm.label(address(modifyLiquidityRouter), "V4LiquidityRouter");
    }

    function deployLabeledCurrencyPair() internal returns (Currency currency0, Currency currency1) {
        (currency0, currency1) = super.deployCurrencyPair();

        vm.label(Currency.unwrap(currency0), "Currency0");
        vm.label(Currency.unwrap(currency1), "Currency1");
    }
}
