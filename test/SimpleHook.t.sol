// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

import {BaseTest} from "./utils/BaseTest.sol";
import {SimpleHook} from "../src/SimpleHook.sol";

contract SimpleHookTest is BaseTest {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    PoolKey poolKey;
    PoolId poolId;
    SimpleHook hook;

    function setUp() public {
        deployArtifactsAndLabel();

        deployLabeledCurrencyPair();

        address flags = address(uint160(Hooks.AFTER_SWAP_FLAG) ^ (0x4444 << 144));
        bytes memory constructorArgs = abi.encode(poolManager);
        deployCodeTo("SimpleHook.sol:SimpleHook", constructorArgs, flags);
        hook = SimpleHook(flags);

        (poolKey, poolId) = initPoolAndAddLiquidity(currency0, currency1, IHooks(hook), 3000, Constants.SQRT_PRICE_1_1);
    }

    function testAfterSwapTracksPoolAndRouter() public {
        assertEq(hook.swapCount(poolId), 0);
        assertEq(hook.lastRouter(poolId), address(0));

        uint256 amountIn = 1e18;
        BalanceDelta swapDelta = swap(poolKey, true, -int256(amountIn), Constants.ZERO_BYTES);

        assertLt(swapDelta.amount0(), 0);
        assertGt(swapDelta.amount1(), 0);
        assertEq(hook.swapCount(poolId), 1);
        assertEq(hook.lastRouter(poolId), address(swapRouter));
    }
}
