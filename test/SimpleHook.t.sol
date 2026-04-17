// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";

import {EasyPosm} from "./utils/libraries/EasyPosm.sol";
import {BaseTest} from "./utils/BaseTest.sol";
import {SimpleHook} from "../src/SimpleHook.sol";

contract SimpleHookTest is BaseTest {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    Currency currency0;
    Currency currency1;
    PoolKey poolKey;
    PoolId poolId;
    SimpleHook hook;

    function setUp() public {
        deployArtifactsAndLabel();

        (currency0, currency1) = deployCurrencyPair();

        address flags = address(uint160(Hooks.AFTER_SWAP_FLAG) ^ (0x4444 << 144));
        bytes memory constructorArgs = abi.encode(poolManager);
        deployCodeTo("SimpleHook.sol:SimpleHook", constructorArgs, flags);
        hook = SimpleHook(flags);

        poolKey = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
        poolId = poolKey.toId();
        poolManager.initialize(poolKey, Constants.SQRT_PRICE_1_1);

        int24 tickLower = TickMath.minUsableTick(poolKey.tickSpacing);
        int24 tickUpper = TickMath.maxUsableTick(poolKey.tickSpacing);
        uint128 liquidityAmount = 100e18;

        (uint256 amount0Max, uint256 amount1Max) = LiquidityAmounts.getAmountsForLiquidity(
            Constants.SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidityAmount
        );

        positionManager.mint(
            poolKey,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Max + 1,
            amount1Max + 1,
            address(this),
            block.timestamp,
            Constants.ZERO_BYTES
        );
    }

    function testAfterSwapTracksPoolAndRouter() public {
        assertEq(hook.swapCount(poolId), 0);
        assertEq(hook.lastRouter(poolId), address(0));

        uint256 amountIn = 1e18;
        BalanceDelta swapDelta = swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: Constants.ZERO_BYTES,
            receiver: address(this),
            deadline: block.timestamp + 1
        });

        assertEq(int256(swapDelta.amount0()), -int256(amountIn));
        assertEq(hook.swapCount(poolId), 1);
        assertEq(hook.lastRouter(poolId), address(swapRouter));
    }
}
