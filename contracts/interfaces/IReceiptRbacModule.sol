// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceTypes} from "../types/GovernanceTypes.sol";

interface IReceiptRbacModule {
    function EXECUTION_DELAY_MIN() external pure returns (uint48);
    function computeOperationId(GovernanceTypes.Operation calldata op) external pure returns (bytes32);
    function operationState(bytes32 operationId) external view returns (GovernanceTypes.OperationState);
}
