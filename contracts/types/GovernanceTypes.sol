// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library GovernanceTypes {
    uint48 internal constant EXECUTION_DELAY_MIN = 172800;
    bytes32 internal constant ROOT_GUARDIAN = keccak256("ROOT_GUARDIAN");
    bytes32 internal constant EMERGENCY_PAUSER = keccak256("EMERGENCY_PAUSER");
    bytes32 internal constant REGISTRY_OPERATOR = keccak256("REGISTRY_OPERATOR");

    enum OperationState {
        PROPOSED,
        SCHEDULED,
        EXECUTABLE,
        EXECUTED,
        CANCELLED,
        EXPIRED
    }

    struct Operation {
        uint256 chainId;
        address safe;
        address module;
        bytes32 schemaVersion;
        bytes32 role;
        address actor;
        address target;
        uint256 value;
        bytes32 calldataHash;
        uint256 nonce;
        uint48 executableAt;
        uint48 expiresAt;
    }
}
