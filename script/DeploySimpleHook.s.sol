// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {SimpleHook} from "../src/SimpleHook.sol";
import {BaseScript} from "./base/BaseScript.sol";

/// @notice Mines a valid hook address and deploys the teaching hook with CREATE2.
contract DeploySimpleHookScript is BaseScript {
    function run() public {
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(poolManager);

        (address expectedHookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_FACTORY, flags, type(SimpleHook).creationCode, constructorArgs);

        vm.startBroadcast();
        SimpleHook hook = new SimpleHook{salt: salt}(poolManager);
        vm.stopBroadcast();

        require(address(hook) == expectedHookAddress, "DeploySimpleHookScript: hook address mismatch");
    }
}
