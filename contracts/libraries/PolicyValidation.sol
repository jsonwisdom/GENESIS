// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PolicyValidation {
    uint48 internal constant EXECUTION_DELAY_MIN = 172800;

    enum CallType {
        CALL,
        DELEGATECALL
    }

    struct CapabilityCheck {
        bool hasRole;
        bool targetAllowed;
        bool selectorAllowed;
        bool valueAllowed;
        bool policyPresent;
        bool policyWellFormed;
        CallType callType;
        uint48 executionDelayConfig;
        uint48 executableAt;
        uint48 expiresAt;
        bytes32 scheduledCalldataHash;
    }

    function validate(
        CapabilityCheck memory check,
        uint256 value,
        bytes memory callData,
        uint48 currentTime
    ) internal pure returns (bool) {
        if (!check.policyPresent || !check.policyWellFormed) return false;
        if (!check.hasRole || !check.targetAllowed || !check.selectorAllowed) return false;
        if (!check.valueAllowed || value != 0) return false;
        if (check.callType != CallType.CALL) return false;
        if (check.executionDelayConfig < EXECUTION_DELAY_MIN) return false;
        if (currentTime < check.executableAt) return false;
        if (currentTime > check.expiresAt) return false;
        if (keccak256(callData) != check.scheduledCalldataHash) return false;
        return true;
    }
}
