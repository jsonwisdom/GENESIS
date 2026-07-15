// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceTypes} from "../types/GovernanceTypes.sol";
import {OperationId} from "../libraries/OperationId.sol";
import {PolicyValidation} from "../libraries/PolicyValidation.sol";

/// @notice Gate 3D.2E stateful policy integration model.
/// @dev Performs no external calls and moves no assets.
contract StatefulPolicySchedulerModel {
    uint48 public constant EXECUTION_DELAY_MIN = 172800;

    error Unauthorized();
    error InvalidDelay();
    error InvalidDomain();
    error InvalidLifetime();
    error InvalidState();
    error OperationAlreadyKnown();
    error PolicyRejected();
    error SystemPaused();
    error VelocityRejected();

    struct Record {
        bool exists;
        GovernanceTypes.OperationState state;
        uint48 executableAt;
        uint48 expiresAt;
        uint48 delayAtSchedule;
        uint256 value;
        bytes32 calldataHash;
    }

    address public immutable controller;
    uint48 public executionDelayConfig;

    mapping(bytes32 operationId => Record) private _records;
    mapping(bytes32 operationId => bool) public consumed;

    event OperationScheduled(bytes32 indexed operationId, uint48 executableAt, uint48 expiresAt);
    event OperationExecuted(bytes32 indexed operationId);
    event ExecutionRejected(bytes32 indexed operationId, bytes32 indexed reason);
    event ExecutionDelayChanged(uint48 previousDelay, uint48 newDelay);

    modifier onlyController() {
        if (msg.sender != controller) revert Unauthorized();
        _;
    }

    constructor(address controller_, uint48 initialDelay) {
        if (controller_ == address(0)) revert Unauthorized();
        if (initialDelay < EXECUTION_DELAY_MIN) revert InvalidDelay();
        controller = controller_;
        executionDelayConfig = initialDelay;
    }

    function setExecutionDelay(uint48 newDelay) external onlyController {
        if (newDelay < EXECUTION_DELAY_MIN) revert InvalidDelay();
        uint48 previous = executionDelayConfig;
        executionDelayConfig = newDelay;
        emit ExecutionDelayChanged(previous, newDelay);
    }

    function schedule(
        GovernanceTypes.Operation calldata input,
        uint48 lifetimeAfterMaturity
    ) external onlyController returns (bytes32 operationId) {
        if (input.chainId != block.chainid || input.module != address(this)) revert InvalidDomain();
        if (input.executableAt != 0 || input.expiresAt != 0) revert InvalidState();
        if (lifetimeAfterMaturity == 0) revert InvalidLifetime();

        GovernanceTypes.Operation memory op = input;
        uint48 delayAtSchedule = executionDelayConfig;
        op.executableAt = uint48(block.timestamp) + delayAtSchedule;
        op.expiresAt = op.executableAt + lifetimeAfterMaturity;
        operationId = OperationId.compute(op);

        if (_records[operationId].exists || consumed[operationId]) revert OperationAlreadyKnown();

        _records[operationId] = Record({
            exists: true,
            state: GovernanceTypes.OperationState.SCHEDULED,
            executableAt: op.executableAt,
            expiresAt: op.expiresAt,
            delayAtSchedule: delayAtSchedule,
            value: op.value,
            calldataHash: op.calldataHash
        });

        emit OperationScheduled(operationId, op.executableAt, op.expiresAt);
    }

    /// @notice Validates policy and consumes state without any external execution.
    function executeValidated(
        bytes32 operationId,
        PolicyValidation.CapabilityCheck calldata suppliedCheck,
        bytes calldata callData,
        bool paused,
        bool velocityPasses
    ) external onlyController {
        Record storage record = _requireActive(operationId);
        if (
            record.state != GovernanceTypes.OperationState.SCHEDULED &&
            record.state != GovernanceTypes.OperationState.EXECUTABLE
        ) revert InvalidState();

        if (paused) {
            emit ExecutionRejected(operationId, keccak256("PAUSED"));
            revert SystemPaused();
        }
        if (!velocityPasses) {
            emit ExecutionRejected(operationId, keccak256("VELOCITY"));
            revert VelocityRejected();
        }

        PolicyValidation.CapabilityCheck memory check = suppliedCheck;
        check.executionDelayConfig = record.delayAtSchedule;
        check.executableAt = record.executableAt;
        check.expiresAt = record.expiresAt;
        check.scheduledCalldataHash = record.calldataHash;

        bool valid = PolicyValidation.validate(check, record.value, callData, uint48(block.timestamp));
        if (!valid) {
            emit ExecutionRejected(operationId, keccak256("POLICY"));
            revert PolicyRejected();
        }

        record.state = GovernanceTypes.OperationState.EXECUTED;
        consumed[operationId] = true;
        emit OperationExecuted(operationId);
    }

    function markExecutable(bytes32 operationId) external {
        Record storage record = _requireActive(operationId);
        if (record.state != GovernanceTypes.OperationState.SCHEDULED) revert InvalidState();
        if (block.timestamp < record.executableAt || block.timestamp > record.expiresAt) revert InvalidState();
        record.state = GovernanceTypes.OperationState.EXECUTABLE;
    }

    function getRecord(bytes32 operationId) external view returns (Record memory) {
        return _records[operationId];
    }

    function _requireActive(bytes32 operationId) private view returns (Record storage record) {
        record = _records[operationId];
        if (!record.exists || consumed[operationId]) revert InvalidState();
    }
}
