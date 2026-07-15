// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PolicyValidation} from "../../contracts/libraries/PolicyValidation.sol";

contract PolicyValidationTest {
    bytes internal constant CALLDATA = hex"12345678";
    uint48 internal constant NOW_TS = 1_000_000;

    function _valid() internal pure returns (PolicyValidation.CapabilityCheck memory check) {
        check = PolicyValidation.CapabilityCheck({
            hasRole: true,
            targetAllowed: true,
            selectorAllowed: true,
            nonZeroValueAllowed: false,
            policyPresent: true,
            policyWellFormed: true,
            callType: PolicyValidation.CallType.CALL,
            executionDelayConfig: 172800,
            executableAt: NOW_TS,
            expiresAt: NOW_TS + 1000,
            scheduledCalldataHash: keccak256(CALLDATA)
        });
    }

    function test_validPolicyPasses() external pure {
        require(PolicyValidation.validate(_valid(), 0, CALLDATA, NOW_TS), "VALID_REJECTED");
    }

    function test_defaultDenyMissingOrMalformedPolicy() external pure {
        PolicyValidation.CapabilityCheck memory check = _valid();
        check.policyPresent = false;
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "MISSING_ALLOWED");
        check = _valid();
        check.policyWellFormed = false;
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "MALFORMED_ALLOWED");
    }

    function test_roleTargetSelectorIntersectionRequired() external pure {
        PolicyValidation.CapabilityCheck memory check = _valid();
        check.hasRole = false;
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "ROLE_BYPASS");
        check = _valid();
        check.targetAllowed = false;
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "TARGET_BYPASS");
        check = _valid();
        check.selectorAllowed = false;
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "SELECTOR_BYPASS");
    }

    function test_zeroValueDefaultAndExplicitNonzeroAuthorization() external pure {
        PolicyValidation.CapabilityCheck memory check = _valid();
        require(!PolicyValidation.validate(check, 1, CALLDATA, NOW_TS), "VALUE_BYPASS");
        check.nonZeroValueAllowed = true;
        require(PolicyValidation.validate(check, 1, CALLDATA, NOW_TS), "EXPLICIT_VALUE_REJECTED");
    }

    function test_delegatecallRejected() external pure {
        PolicyValidation.CapabilityCheck memory check = _valid();
        check.callType = PolicyValidation.CallType.DELEGATECALL;
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "DELEGATECALL_ALLOWED");
    }

    function test_delayFloorAndMaturity() external pure {
        PolicyValidation.CapabilityCheck memory check = _valid();
        check.executionDelayConfig = 172799;
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "LOW_DELAY_ALLOWED");
        check = _valid();
        require(!PolicyValidation.validate(check, 0, CALLDATA, NOW_TS - 1), "EARLY_EXECUTION_ALLOWED");
        require(PolicyValidation.validate(check, 0, CALLDATA, NOW_TS), "MATURITY_REJECTED");
    }

    function test_expiryBoundary() external pure {
        PolicyValidation.CapabilityCheck memory check = _valid();
        require(PolicyValidation.validate(check, 0, CALLDATA, check.expiresAt), "AT_EXPIRY_REJECTED");
        require(!PolicyValidation.validate(check, 0, CALLDATA, check.expiresAt + 1), "POST_EXPIRY_ALLOWED");
    }

    function test_calldataHashMustMatch() external pure {
        PolicyValidation.CapabilityCheck memory check = _valid();
        require(!PolicyValidation.validate(check, 0, hex"deadbeef", NOW_TS), "HASH_MISMATCH_ALLOWED");
    }
}
