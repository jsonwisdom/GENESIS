// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceTypes} from "../../contracts/types/GovernanceTypes.sol";
import {PolicyValidation} from "../../contracts/libraries/PolicyValidation.sol";
import {StatefulPolicySchedulerModel} from "../../contracts/models/StatefulPolicySchedulerModel.sol";

interface VmPolicyScheduler {
    function warp(uint256 newTimestamp) external;
}

contract StatefulPolicySchedulerModelTest {
    VmPolicyScheduler private constant vm =
        VmPolicyScheduler(address(uint160(uint256(keccak256("hevm cheat code")))));

    uint48 private constant MIN_DELAY = 172800;
    uint48 private constant LIFETIME = 86400;
    bytes private constant CALL_DATA = hex"12345678aabbccdd";

    StatefulPolicySchedulerModel private scheduler;

    function setUp() public {
        scheduler = new StatefulPolicySchedulerModel(address(this), MIN_DELAY);
    }

    function test_validPolicyExecutesStateOnlyAtMaturity() external {
        bytes32 id = _schedule(1);
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);

        scheduler.executeValidated(id, _validCheck(), CALL_DATA, false, true);

        _requireState(id, GovernanceTypes.OperationState.EXECUTED, true);
    }

    function test_validPolicyExecutesFromExplicitExecutableState() external {
        bytes32 id = _schedule(2);
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);
        scheduler.markExecutable(id);

        scheduler.executeValidated(id, _validCheck(), CALL_DATA, false, true);

        _requireState(id, GovernanceTypes.OperationState.EXECUTED, true);
    }

    function test_roleTargetSelectorIntersectionFailurePreservesState() external {
        bytes32 id = _schedule(3);
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);

        PolicyValidation.CapabilityCheck memory check = _validCheck();
        check.hasRole = false;
        _expectRejectedAndUnchanged(id, check, CALL_DATA, false, true);

        check = _validCheck();
        check.targetAllowed = false;
        _expectRejectedAndUnchanged(id, check, CALL_DATA, false, true);

        check = _validCheck();
        check.selectorAllowed = false;
        _expectRejectedAndUnchanged(id, check, CALL_DATA, false, true);
    }

    function test_pausedSystemRejectsAndPreservesState() external {
        bytes32 id = _schedule(4);
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);

        _expectRejectedAndUnchanged(id, _validCheck(), CALL_DATA, true, true);
    }

    function test_velocityFailureRejectsAndPreservesState() external {
        bytes32 id = _schedule(5);
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);

        _expectRejectedAndUnchanged(id, _validCheck(), CALL_DATA, false, false);
    }

    function test_calldataMismatchRejectsAndPreservesState() external {
        bytes32 id = _schedule(6);
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);

        _expectRejectedAndUnchanged(id, _validCheck(), hex"deadbeef", false, true);
    }

    function test_earlyAndExpiredExecutionRejectWithoutConsumption() external {
        bytes32 earlyId = _schedule(7);
        StatefulPolicySchedulerModel.Record memory earlyRecord = scheduler.getRecord(earlyId);
        vm.warp(earlyRecord.executableAt - 1);
        _expectRejectedAndUnchanged(earlyId, _validCheck(), CALL_DATA, false, true);

        bytes32 expiredId = _schedule(8);
        StatefulPolicySchedulerModel.Record memory expiredRecord = scheduler.getRecord(expiredId);
        vm.warp(uint256(expiredRecord.expiresAt) + 1);
        _expectRejectedAndUnchanged(expiredId, _validCheck(), CALL_DATA, false, true);
    }

    function test_executionConsumesOnceAndRejectsReplay() external {
        bytes32 id = _schedule(9);
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);
        scheduler.executeValidated(id, _validCheck(), CALL_DATA, false, true);

        (bool replayOk,) = address(scheduler).call(
            abi.encodeCall(scheduler.executeValidated, (id, _validCheck(), CALL_DATA, false, true))
        );
        require(!replayOk, "REPLAY_ALLOWED");
        _requireState(id, GovernanceTypes.OperationState.EXECUTED, true);
    }

    function test_delayReductionCannotRetroactivelyMatureOperation() external {
        StatefulPolicySchedulerModel delayed =
            new StatefulPolicySchedulerModel(address(this), uint48(MIN_DELAY + 86400));
        GovernanceTypes.Operation memory op = _baseOperation(address(delayed), 10);
        bytes32 id = delayed.schedule(op, LIFETIME);
        StatefulPolicySchedulerModel.Record memory beforeRecord = delayed.getRecord(id);

        delayed.setExecutionDelay(MIN_DELAY);
        StatefulPolicySchedulerModel.Record memory afterRecord = delayed.getRecord(id);
        require(afterRecord.executableAt == beforeRecord.executableAt, "RETROACTIVE_MATURITY");
        require(afterRecord.delayAtSchedule == beforeRecord.delayAtSchedule, "DELAY_SNAPSHOT_CHANGED");

        vm.warp(uint256(beforeRecord.executableAt) - 1);
        (bool ok,) = address(delayed).call(
            abi.encodeCall(delayed.executeValidated, (id, _validCheck(), CALL_DATA, false, true))
        );
        require(!ok, "EARLY_AFTER_REDUCTION");
        StatefulPolicySchedulerModel.Record memory finalRecord = delayed.getRecord(id);
        require(finalRecord.state == GovernanceTypes.OperationState.SCHEDULED, "STATE_CHANGED");
        require(!delayed.consumed(id), "CONSUMED");
    }

    function _schedule(uint256 nonce) private returns (bytes32) {
        return scheduler.schedule(_baseOperation(address(scheduler), nonce), LIFETIME);
    }

    function _baseOperation(
        address module,
        uint256 nonce
    ) private view returns (GovernanceTypes.Operation memory op) {
        op = GovernanceTypes.Operation({
            chainId: block.chainid,
            safe: address(0x1111),
            module: module,
            schemaVersion: keccak256("GATE-3D-2E"),
            role: keccak256("REGISTRY_OPERATOR"),
            actor: address(this),
            target: address(0x2222),
            value: 0,
            calldataHash: keccak256(CALL_DATA),
            nonce: nonce,
            executableAt: 0,
            expiresAt: 0
        });
    }

    function _validCheck() private pure returns (PolicyValidation.CapabilityCheck memory check) {
        check = PolicyValidation.CapabilityCheck({
            hasRole: true,
            targetAllowed: true,
            selectorAllowed: true,
            valueAllowed: true,
            policyPresent: true,
            policyWellFormed: true,
            callType: PolicyValidation.CallType.CALL,
            executionDelayConfig: 0,
            executableAt: 0,
            expiresAt: 0,
            scheduledCalldataHash: bytes32(0)
        });
    }

    function _expectRejectedAndUnchanged(
        bytes32 id,
        PolicyValidation.CapabilityCheck memory check,
        bytes memory callData,
        bool paused,
        bool velocityPasses
    ) private {
        StatefulPolicySchedulerModel.Record memory beforeRecord = scheduler.getRecord(id);
        (bool ok,) = address(scheduler).call(
            abi.encodeCall(scheduler.executeValidated, (id, check, callData, paused, velocityPasses))
        );
        require(!ok, "EXPECTED_REJECTION");

        StatefulPolicySchedulerModel.Record memory afterRecord = scheduler.getRecord(id);
        require(afterRecord.state == beforeRecord.state, "STATE_CHANGED");
        require(afterRecord.executableAt == beforeRecord.executableAt, "TIME_CHANGED");
        require(afterRecord.expiresAt == beforeRecord.expiresAt, "EXPIRY_CHANGED");
        require(afterRecord.delayAtSchedule == beforeRecord.delayAtSchedule, "DELAY_CHANGED");
        require(afterRecord.value == beforeRecord.value, "VALUE_CHANGED");
        require(afterRecord.calldataHash == beforeRecord.calldataHash, "HASH_CHANGED");
        require(!scheduler.consumed(id), "CONSUMED_ON_REJECT");
    }

    function _requireState(
        bytes32 id,
        GovernanceTypes.OperationState expected,
        bool expectedConsumed
    ) private view {
        StatefulPolicySchedulerModel.Record memory record = scheduler.getRecord(id);
        require(record.state == expected, "STATE");
        require(scheduler.consumed(id) == expectedConsumed, "CONSUMED");
    }
}
