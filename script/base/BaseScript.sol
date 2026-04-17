// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {Deployers} from "test/utils/Deployers.sol";

/// @notice Shared setup for local Uniswap v4 scripts.
contract BaseScript is Script, Deployers {
    constructor() {
        deployArtifacts();
    }

    function _etch(address target, bytes memory bytecode) internal override {
        if (block.chainid == 31337) {
            vm.rpc("anvil_setCode", string.concat('["', vm.toString(target), '",', '"', vm.toString(bytecode), '"]'));
        } else {
            revert("Unsupported etch on this network");
        }
    }
}
