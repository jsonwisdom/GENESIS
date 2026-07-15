// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceTypes} from "../types/GovernanceTypes.sol";

library OperationId {
    function compute(GovernanceTypes.Operation memory op) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                op.chainId,
                op.safe,
                op.module,
                op.schemaVersion,
                op.role,
                op.actor,
                op.target,
                op.value,
                op.calldataHash,
                op.nonce,
                op.executableAt,
                op.expiresAt
            )
        );
    }
}
