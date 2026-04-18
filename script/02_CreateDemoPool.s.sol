// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {DemoScriptBase} from "./base/DemoScriptBase.sol";

/// @notice Creates a demo ERC20/ERC20 pool wired to the latest deployed SimpleHook.
contract CreateDemoPoolScript is DemoScriptBase {
    using PoolIdLibrary for PoolKey;

    uint256 internal constant INITIAL_MINT = 1_000_000 ether;

    function run() public {
        address hookAddress = _hookAddress();
        _verifyHook(hookAddress);

        DemoState memory state;
        state.poolManager = address(poolManager);
        state.hook = hookAddress;
        state.fee = uint24(vm.envOr("POOL_FEE", uint256(DEFAULT_FEE)));
        state.tickSpacing = int24(vm.envOr("TICK_SPACING", int256(DEFAULT_TICK_SPACING)));
        state.tickLower = DEFAULT_TICK_LOWER;
        state.tickUpper = DEFAULT_TICK_UPPER;
        state.sqrtPriceX96 = uint160(vm.envOr("SQRT_PRICE_X96", uint256(DEFAULT_SQRT_PRICE_X96)));

        vm.startBroadcast(deployerPrivateKey);

        MockERC20 tokenA = new MockERC20("Demo Token A", "DTA", 18);
        MockERC20 tokenB = new MockERC20("Demo Token B", "DTB", 18);
        PoolModifyLiquidityTest liquidityRouter = new PoolModifyLiquidityTest(poolManager);
        PoolSwapTest swapRouter = new PoolSwapTest(poolManager);

        tokenA.mint(_deployer(), INITIAL_MINT);
        tokenB.mint(_deployer(), INITIAL_MINT);

        tokenA.approve(address(liquidityRouter), type(uint256).max);
        tokenA.approve(address(swapRouter), type(uint256).max);
        tokenB.approve(address(liquidityRouter), type(uint256).max);
        tokenB.approve(address(swapRouter), type(uint256).max);

        (state.token0, state.token1) =
            address(tokenA) < address(tokenB) ? (address(tokenA), address(tokenB)) : (address(tokenB), address(tokenA));
        state.liquidityRouter = address(liquidityRouter);
        state.swapRouter = address(swapRouter);
        state.poolId = PoolId.unwrap(_poolKey(state).toId());

        poolManager.initialize(_poolKey(state), state.sqrtPriceX96);

        vm.stopBroadcast();

        _saveState(state);

        console2.log("demo pool created");
        _logStateSummary(state);
    }
}
