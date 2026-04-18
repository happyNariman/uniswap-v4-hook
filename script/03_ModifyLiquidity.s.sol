// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

import {IERC20Minimal} from "@uniswap/v4-core/src/interfaces/external/IERC20Minimal.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";

import {DemoScriptBase} from "./base/DemoScriptBase.sol";

/// @notice Adds or removes liquidity on the saved demo pool.
contract ModifyLiquidityScript is DemoScriptBase {
    function run() public {
        DemoState memory state = _loadState();
        _verifyHook(state.hook);
        _requireContract(state.token0, "token0");
        _requireContract(state.token1, "token1");
        _requireContract(state.liquidityRouter, "liquidity router");

        int256 liquidityDeltaRaw = vm.envOr("LIQUIDITY_DELTA", int256(1e18));
        require(liquidityDeltaRaw != 0, "ModifyLiquidityScript: zero liquidity delta");
        require(
            liquidityDeltaRaw >= type(int128).min && liquidityDeltaRaw <= type(int128).max,
            "ModifyLiquidityScript: delta too large"
        );

        int24 tickLower = int24(vm.envOr("TICK_LOWER", int256(state.tickLower)));
        int24 tickUpper = int24(vm.envOr("TICK_UPPER", int256(state.tickUpper)));

        IERC20Minimal token0 = IERC20Minimal(state.token0);
        IERC20Minimal token1 = IERC20Minimal(state.token1);
        PoolModifyLiquidityTest liquidityRouter = PoolModifyLiquidityTest(payable(state.liquidityRouter));

        vm.startBroadcast(deployerPrivateKey);

        token0.approve(state.liquidityRouter, type(uint256).max);
        token1.approve(state.liquidityRouter, type(uint256).max);

        liquidityRouter.modifyLiquidity(
            _poolKey(state),
            ModifyLiquidityParams({
                tickLower: tickLower, tickUpper: tickUpper, liquidityDelta: int128(liquidityDeltaRaw), salt: 0
            }),
            bytes("")
        );

        vm.stopBroadcast();

        state.tickLower = tickLower;
        state.tickUpper = tickUpper;
        _saveState(state);

        console2.log("liquidity updated");
        console2.log("liquidity delta");
        console2.logInt(liquidityDeltaRaw);
        _logStateSummary(state);
    }
}
