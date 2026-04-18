// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

import {SimpleHook} from "../../src/SimpleHook.sol";
import {BaseScript} from "./BaseScript.sol";

/// @notice Shared helpers for the local demo pool scripts.
abstract contract DemoScriptBase is BaseScript {
    using PoolIdLibrary for PoolKey;
    using stdJson for string;

    uint24 internal constant DEFAULT_FEE = 3000;
    int24 internal constant DEFAULT_TICK_SPACING = 60;
    int24 internal constant DEFAULT_TICK_LOWER = -120;
    int24 internal constant DEFAULT_TICK_UPPER = 120;
    uint160 internal constant DEFAULT_SQRT_PRICE_X96 = 79228162514264337593543950336;

    struct DemoState {
        address poolManager;
        address hook;
        address token0;
        address token1;
        address liquidityRouter;
        address swapRouter;
        uint24 fee;
        int24 tickSpacing;
        int24 tickLower;
        int24 tickUpper;
        uint160 sqrtPriceX96;
        bytes32 poolId;
    }

    function _hookAddress() internal view returns (address hookAddress) {
        hookAddress = vm.envOr("HOOK_ADDRESS", address(0));
        if (hookAddress != address(0)) return hookAddress;

        string memory broadcastPath = _latestHookBroadcastPath();
        require(vm.exists(broadcastPath), "DemoScriptBase: missing latest hook broadcast");

        string memory json = vm.readFile(broadcastPath);
        hookAddress = json.readAddress(".transactions[0].contractAddress");
        require(hookAddress != address(0), "DemoScriptBase: hook address not found");
    }

    function _latestHookBroadcastPath() internal view returns (string memory) {
        string memory chainId = vm.toString(block.chainid);
        string memory newPath = string.concat("broadcast/01_DeploySimpleHook.s.sol/", chainId, "/run-latest.json");

        if (vm.exists(newPath)) return newPath;

        return string.concat("broadcast/DeploySimpleHook.s.sol/", chainId, "/run-latest.json");
    }

    function _statePath() internal view returns (string memory) {
        return string.concat("deployments/", vm.toString(block.chainid), "/demo-pool.json");
    }

    function _stateDirectory() internal view returns (string memory) {
        return string.concat("deployments/", vm.toString(block.chainid));
    }

    function _ensureStateDirectory() internal {
        vm.createDir(_stateDirectory(), true);
    }

    function _saveState(DemoState memory state) internal {
        _ensureStateDirectory();

        string memory jsonKey = "demoPool";
        jsonKey.serialize("poolManager", state.poolManager);
        jsonKey.serialize("hook", state.hook);
        jsonKey.serialize("token0", state.token0);
        jsonKey.serialize("token1", state.token1);
        jsonKey.serialize("liquidityRouter", state.liquidityRouter);
        jsonKey.serialize("swapRouter", state.swapRouter);
        jsonKey.serialize("fee", uint256(state.fee));
        jsonKey.serialize("tickSpacing", int256(state.tickSpacing));
        jsonKey.serialize("tickLower", int256(state.tickLower));
        jsonKey.serialize("tickUpper", int256(state.tickUpper));
        jsonKey.serialize("sqrtPriceX96", uint256(state.sqrtPriceX96));
        string memory finalJson = jsonKey.serialize("poolId", state.poolId);
        finalJson.write(_statePath());
    }

    function _loadState() internal view returns (DemoState memory state) {
        string memory statePath = _statePath();
        require(vm.exists(statePath), "DemoScriptBase: missing demo pool state");

        string memory json = vm.readFile(statePath);
        state.poolManager = json.readAddress(".poolManager");
        state.hook = json.readAddress(".hook");
        state.token0 = json.readAddress(".token0");
        state.token1 = json.readAddress(".token1");
        state.liquidityRouter = json.readAddress(".liquidityRouter");
        state.swapRouter = json.readAddress(".swapRouter");
        state.fee = uint24(json.readUint(".fee"));
        state.tickSpacing = int24(json.readInt(".tickSpacing"));
        state.tickLower = int24(json.readInt(".tickLower"));
        state.tickUpper = int24(json.readInt(".tickUpper"));
        state.sqrtPriceX96 = uint160(json.readUint(".sqrtPriceX96"));
        state.poolId = json.readBytes32(".poolId");

        require(state.poolManager == address(poolManager), "DemoScriptBase: POOL_MANAGER mismatch");
    }

    function _poolKey(DemoState memory state) internal pure returns (PoolKey memory) {
        return PoolKey({
            currency0: Currency.wrap(state.token0),
            currency1: Currency.wrap(state.token1),
            fee: state.fee,
            tickSpacing: state.tickSpacing,
            hooks: IHooks(state.hook)
        });
    }

    function _poolId(DemoState memory state) internal pure returns (PoolId) {
        return _poolKey(state).toId();
    }

    function _deployer() internal view returns (address) {
        return vm.addr(deployerPrivateKey);
    }

    function _requireContract(address target, string memory label) internal view {
        require(target != address(0), "DemoScriptBase: zero address");
        require(target.code.length > 0, string.concat("DemoScriptBase: missing code for ", label));
    }

    function _logStateSummary(DemoState memory state) internal view {
        console2.log("state file", _statePath());
        console2.log("pool manager", state.poolManager);
        console2.log("hook", state.hook);
        console2.log("token0", state.token0);
        console2.log("token1", state.token1);
        console2.log("liquidity router", state.liquidityRouter);
        console2.log("swap router", state.swapRouter);
        console2.log("pool id");
        console2.logBytes32(state.poolId);
    }

    function _verifyHook(address hookAddress) internal view {
        _requireContract(hookAddress, "hook");
        require(
            SimpleHook(hookAddress).poolManager() == IPoolManager(poolManager), "DemoScriptBase: wrong hook manager"
        );
    }
}
