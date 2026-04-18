// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";

import {SimpleHook} from "../src/SimpleHook.sol";
import {DemoScriptBase} from "./base/DemoScriptBase.sol";

/// @notice Reads the current hook state for the saved demo pool.
contract ReadHookInfoScript is DemoScriptBase {
    function run() public view {
        DemoState memory state = _loadState();
        _verifyHook(state.hook);

        SimpleHook hook = SimpleHook(state.hook);
        bytes32 expectedPoolId = PoolId.unwrap(_poolId(state));
        require(expectedPoolId == state.poolId, "ReadHookInfoScript: pool id mismatch");

        console2.log("hook info");
        console2.log("hook", state.hook);
        console2.log("pool manager", address(hook.poolManager()));
        console2.log("pool id");
        console2.logBytes32(state.poolId);
        console2.log("swap count", hook.swapCount(_poolId(state)));
        console2.log("last router", hook.lastRouter(_poolId(state)));
        console2.log("token0", state.token0);
        console2.log("token1", state.token1);
    }
}
