// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceTypes} from "../../contracts/types/GovernanceTypes.sol";
import {OperationId} from "../../contracts/libraries/OperationId.sol";
import {OperationSchedulerModel} from "../../contracts/models/OperationSchedulerModel.sol";

interface Vm {
    function warp(uint256 newTimestamp) external;
    function prank(address caller) external;
}

contract OperationSchedulerModelTest {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint48 private constant MIN_DELAY = 172800;
    uint48 private constant LIFETIME = 86400;

    OperationSchedulerModel private scheduler;

    function setUp() public {
        scheduler = new OperationSchedulerModel(address(this), MIN_DELAY);
    }

    function test_scheduleStoresDeterministicTimestampsAndId() external {
        GovernanceTypes.Operation memory op = _baseOperation(address(scheduler), 1);
        uint48 expectedExecutableAt = uint48(block.timestamp) + MIN_DELAY;
        uint48 expectedExpiresAt = expectedExecutableAt + LIFETIME;

        bytes32 id = scheduler.schedule(op, LIFETIME);

        op.executableAt = expectedExecutableAt;
        op.expiresAt = expectedExpiresAt;
        require(id == OperationId.compute(op), "ID_MISMATCH");

        OperationSchedulerModel.Record memory record = scheduler.getRecord(id);
        require(record.exists, "NOT_STORED");
        require(record.state == GovernanceTypes.OperationState.SCHEDULED, "NOT_SCHEDULED");
        require(record.executableAt == expectedExecutableAt, "EXECUTABLE_AT");
        require(record.expiresAt == expectedExpiresAt, "EXPIRES_AT");
        require(!scheduler.consumed(id), "EARLY_CONSUME");
    }

    function test_matureOnlyAtOrAfterExecutableAt() external {
        bytes32 id = scheduler.schedule(_baseOperation(address(scheduler), 2), LIFETIME);
        OperationSchedulerModel.Record memory beforeRecord = scheduler.getRecord(id);

        vm.warp(beforeRecord.executableAt - 1);
        (bool earlyOk,) = address(scheduler).call(abi.encodeCall(scheduler.mature, (id)));
        require(!earlyOk, "EARLY_MATURE_ALLOWED");
        _requireState(id, GovernanceTypes.OperationState.SCHEDULED, false);

        vm.warp(beforeRecord.executableAt);
        scheduler.mature(id);
        _requireState(id, GovernanceTypes.OperationState.EXECUTABLE, false);
    }

    function test_cancelConsumesAndRejectsReplayOrReuse() external {
        GovernanceTypes.Operation memory op = _baseOperation(address(scheduler), 3);
        bytes32 id = scheduler.schedule(op, LIFETIME);

        scheduler.cancel(id);
        _requireState(id, GovernanceTypes.OperationState.CANCELLED, true);

        (bool replayOk,) = address(scheduler).call(abi.encodeCall(scheduler.cancel, (id)));
        require(!replayOk, "CANCEL_REPLAY_ALLOWED");

        (bool reuseOk,) = address(scheduler).call(
            abi.encodeCall(scheduler.schedule, (op, LIFETIME))
        );
        require(!reuseOk, "ID_REUSE_ALLOWED");
        _requireState(id, GovernanceTypes.OperationState.CANCELLED, true);
    }

    function test_expireAfterBoundaryConsumesOnce() external {
        bytes32 id = scheduler.schedule(_baseOperation(address(scheduler), 4), LIFETIME);
        OperationSchedulerModel.Record memory record = scheduler.getRecord(id);

        vm.warp(record.expiresAt);
        (bool boundaryOk,) = address(scheduler).call(abi.encodeCall(scheduler.expire, (id)));
        require(!boundaryOk, "EXPIRED_AT_BOUNDARY");
        _requireState(id, GovernanceTypes.OperationState.SCHEDULED, false);

        vm.warp(uint256(record.expiresAt) + 1);
        scheduler.expire(id);
        _requireState(id, GovernanceTypes.OperationState.EXPIRED, true);

        (bool replayOk,) = address(scheduler).call(abi.encodeCall(scheduler.expire, (id)));
        require(!replayOk, "EXPIRY_REPLAY_ALLOWED");
    }

    function test_consumeExecutableOperationOnceWithoutExternalCall() external {
        bytes32 id = scheduler.schedule(_baseOperation(address(scheduler), 5), LIFETIME);
        OperationSchedulerModel.Record memory record = scheduler.getRecord(id);
        vm.warp(record.executableAt);

        scheduler.mature(id);
        scheduler.consume(id);
        _requireState(id, GovernanceTypes.OperationState.EXECUTED, true);

        (bool replayOk,) = address(scheduler).call(abi.encodeCall(scheduler.consume, (id)));
        require(!replayOk, "EXECUTION_REPLAY_ALLOWED");
    }

    function test_delayReductionDoesNotChangeExistingExecutableAt() external {
        OperationSchedulerModel delayed = new OperationSchedulerModel(address(this), 259200);
        bytes32 id = delayed.schedule(_baseOperation(address(delayed), 6), LIFETIME);
        OperationSchedulerModel.Record memory beforeRecord = delayed.getRecord(id);

        delayed.setExecutionDelay(MIN_DELAY);
        OperationSchedulerModel.Record memory afterRecord = delayed.getRecord(id);

        require(delayed.executionDelayConfig() == MIN_DELAY, "ACTIVE_DELAY");
        require(afterRecord.executableAt == beforeRecord.executableAt, "RETROACTIVE_REDUCTION");
        require(afterRecord.expiresAt == beforeRecord.expiresAt, "RETROACTIVE_EXPIRY");
    }

    function test_rejectedUnauthorizedCancelHasNoSideEffects() external {
        bytes32 id = scheduler.schedule(_baseOperation(address(scheduler), 7), LIFETIME);
        OperationSchedulerModel.Record memory beforeRecord = scheduler.getRecord(id);

        vm.prank(address(0xBEEF));
        (bool ok,) = address(scheduler).call(abi.encodeCall(scheduler.cancel, (id)));
        require(!ok, "UNAUTHORIZED_CANCEL");

        OperationSchedulerModel.Record memory afterRecord = scheduler.getRecord(id);
        require(afterRecord.state == beforeRecord.state, "STATE_CHANGED");
        require(afterRecord.executableAt == beforeRecord.executableAt, "TIME_CHANGED");
        require(afterRecord.expiresAt == beforeRecord.expiresAt, "EXPIRY_CHANGED");
        require(!scheduler.consumed(id), "CONSUMED_ON_REJECT");
    }

    function test_scheduleRejectsWrongDomainWithoutState() external {
        GovernanceTypes.Operation memory op = _baseOperation(address(scheduler), 8);
        op.chainId = block.chainid + 1;

        (bool chainOk,) = address(scheduler).call(
            abi.encodeCall(scheduler.schedule, (op, LIFETIME))
        );
        require(!chainOk, "WRONG_CHAIN_ALLOWED");

        op.chainId = block.chainid;
        op.module = address(0xCAFE);
        (bool moduleOk,) = address(scheduler).call(
            abi.encodeCall(scheduler.schedule, (op, LIFETIME))
        );
        require(!moduleOk, "WRONG_MODULE_ALLOWED");
    }

    function _baseOperation(
        address module,
        uint256 nonce
    ) private view returns (GovernanceTypes.Operation memory op) {
        op = GovernanceTypes.Operation({
            chainId: block.chainid,
            safe: address(0x1111),
            module: module,
            schemaVersion: keccak256("GATE-3D-2D"),
            role: keccak256("REGISTRY_OPERATOR"),
            actor: address(this),
            target: address(0x2222),
            value: 0,
            calldataHash: keccak256(abi.encodePacked("appendReceipt", nonce)),
            nonce: nonce,
            executableAt: 0,
            expiresAt: 0
        });
    }

    function _requireState(
        bytes32 id,
        GovernanceTypes.OperationState expected,
        bool expectedConsumed
    ) private view {
        OperationSchedulerModel.Record memory record = scheduler.getRecord(id);
        require(record.state == expected, "STATE");
        require(scheduler.consumed(id) == expectedConsumed, "CONSUMED");
    }
}
