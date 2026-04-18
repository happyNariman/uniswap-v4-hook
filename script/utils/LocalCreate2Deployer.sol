// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Minimal CREATE2 factory for local chains that do not expose the canonical deployer.
contract LocalCreate2Deployer {
    error Create2DeploymentFailed();

    function deploy(bytes32 salt, bytes memory initCode) external returns (address deployed) {
        assembly ("memory-safe") {
            deployed := create2(0, add(initCode, 0x20), mload(initCode), salt)
        }

        if (deployed == address(0)) revert Create2DeploymentFailed();
    }
}
