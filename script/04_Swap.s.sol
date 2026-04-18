// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {IERC20Minimal} from "@uniswap/v4-core/src/interfaces/external/IERC20Minimal.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {DemoScriptBase} from "./base/DemoScriptBase.sol";

/// @notice Executes a simple exact-input swap on the saved demo pool.
contract SwapScript is DemoScriptBase {
    function run() public {
        DemoState memory state = _loadState();
        _verifyHook(state.hook);
        _requireContract(state.token0, "token0");
        _requireContract(state.token1, "token1");
        _requireContract(state.swapRouter, "swap router");

        bool zeroForOne = vm.envOr("ZERO_FOR_ONE", true);
        uint256 swapAmount = vm.envOr("SWAP_AMOUNT", uint256(1e18));
        require(swapAmount > 0, "SwapScript: zero swap amount");
        require(swapAmount <= uint256(type(int256).max), "SwapScript: amount too large");

        address inputToken = zeroForOne ? state.token0 : state.token1;
        IERC20Minimal inputErc20 = IERC20Minimal(inputToken);
        PoolSwapTest swapRouter = PoolSwapTest(payable(state.swapRouter));

        vm.startBroadcast(deployerPrivateKey);

        inputErc20.approve(state.swapRouter, type(uint256).max);

        swapRouter.swap(
            _poolKey(state),
            SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: -int256(swapAmount),
                sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
            }),
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            bytes("")
        );

        vm.stopBroadcast();

        console2.log("swap executed");
        console2.log("zeroForOne", zeroForOne);
        console2.log("amount in", swapAmount);
        _logStateSummary(state);
    }
}
