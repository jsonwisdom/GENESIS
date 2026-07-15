// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceTypes} from "../types/GovernanceTypes.sol";
import {OperationId} from "../libraries/OperationId.sol";

/// @notice Gate 3D.2D scheduler model only. It performs no external calls.
contract OperationSchedulerModel {
    uint48 public constant EXECUTION_DELAY_MIN = 172800;

    error Unauthorized();
    error InvalidDelay();
    error InvalidDomain();
    error InvalidLifetime();
    error InvalidState();
    error TooEarly();
    error Expired();
    error NotExpired();
    error OperationAlreadyKnown();

    struct Record {
        bool exists;
        GovernanceTypes.OperationState state;
        uint48 executableAt;
        uint48 expiresAt;
    }

    address public immutable controller;
    uint48 public executionDelayConfig;

    mapping(bytes32 operationId => Record) private _records;
    mapping(bytes32 operationId => bool) public consumed;

    event OperationScheduled(bytes32 indexed operationId, uint48 executableAt, uint48 expiresAt);
    event OperationMatured(bytes32 indexed operationId);
    event OperationCancelled(bytes32 indexed operationId);
    event OperationExpired(bytes32 indexed operationId);
    event OperationConsumed(bytes32 indexed operationId);
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
        op.executableAt = uint48(block.timestamp) + executionDelayConfig;
        op.expiresAt = op.executableAt + lifetimeAfterMaturity;
        operationId = OperationId.compute(op);

        if (_records[operationId].exists || consumed[operationId]) revert OperationAlreadyKnown();

        _records[operationId] = Record({
            exists: true,
            state: GovernanceTypes.OperationState.SCHEDULED,
            executableAt: op.executableAt,
            expiresAt: op.expiresAt
        });

        emit OperationScheduled(operationId, op.executableAt, op.expiresAt);
    }

    function mature(bytes32 operationId) external {
        Record storage record = _requireActive(operationId);
        if (record.state != GovernanceTypes.OperationState.SCHEDULED) revert InvalidState();
        if (block.timestamp < record.executableAt) revert TooEarly();
        if (block.timestamp > record.expiresAt) revert Expired();
        record.state = GovernanceTypes.OperationState.EXECUTABLE;
        emit OperationMatured(operationId);
    }

    function cancel(bytes32 operationId) external onlyController {
        Record storage record = _requireActive(operationId);
        if (
            record.state != GovernanceTypes.OperationState.SCHEDULED &&
            record.state != GovernanceTypes.OperationState.EXECUTABLE
        ) revert InvalidState();
        record.state = GovernanceTypes.OperationState.CANCELLED;
        consumed[operationId] = true;
        emit OperationCancelled(operationId);
    }

    function expire(bytes32 operationId) external {
        Record storage record = _requireActive(operationId);
        if (
            record.state != GovernanceTypes.OperationState.SCHEDULED &&
            record.state != GovernanceTypes.OperationState.EXECUTABLE
        ) revert InvalidState();
        if (block.timestamp <= record.expiresAt) revert NotExpired();
        record.state = GovernanceTypes.OperationState.EXPIRED;
        consumed[operationId] = true;
        emit OperationExpired(operationId);
    }

    /// @notice Marks an executable operation consumed without performing any external call.
    function consume(bytes32 operationId) external onlyController {
        Record storage record = _requireActive(operationId);
        if (record.state != GovernanceTypes.OperationState.EXECUTABLE) revert InvalidState();
        if (block.timestamp > record.expiresAt) revert Expired();
        record.state = GovernanceTypes.OperationState.EXECUTED;
        consumed[operationId] = true;
        emit OperationConsumed(operationId);
    }

    function getRecord(bytes32 operationId) external view returns (Record memory) {
        return _records[operationId];
    }

    function _requireActive(bytes32 operationId) private view returns (Record storage record) {
        record = _records[operationId];
        if (!record.exists || consumed[operationId]) revert InvalidState();
    }
}
