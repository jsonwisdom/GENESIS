// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovernanceTypes} from "../../contracts/types/GovernanceTypes.sol";
import {OperationId} from "../../contracts/libraries/OperationId.sol";

contract OperationIdTest {
    function _base() internal pure returns (GovernanceTypes.Operation memory op) {
        op = GovernanceTypes.Operation({
            chainId: 8453,
            safe: address(0x1111111111111111111111111111111111111111),
            module: address(0x2222222222222222222222222222222222222222),
            schemaVersion: keccak256("GATE-3D-2B-v1"),
            role: keccak256("REGISTRY_OPERATOR"),
            actor: address(0x3333333333333333333333333333333333333333),
            target: address(0x4444444444444444444444444444444444444444),
            value: 0,
            calldataHash: keccak256(hex"12345678"),
            nonce: 7,
            executableAt: 1_800_000_000,
            expiresAt: 1_800_086_400
        });
    }

    function _assertChanged(
        GovernanceTypes.Operation memory changed,
        bytes32 baseline,
        string memory reason
    ) internal pure {
        require(OperationId.compute(changed) != baseline, reason);
    }

    function test_knownVectorMatchesExplicitAbiEncoding() external pure {
        GovernanceTypes.Operation memory op = _base();
        bytes32 expected = keccak256(
            abi.encode(
                uint256(8453),
                address(0x1111111111111111111111111111111111111111),
                address(0x2222222222222222222222222222222222222222),
                keccak256("GATE-3D-2B-v1"),
                keccak256("REGISTRY_OPERATOR"),
                address(0x3333333333333333333333333333333333333333),
                address(0x4444444444444444444444444444444444444444),
                uint256(0),
                keccak256(hex"12345678"),
                uint256(7),
                uint48(1_800_000_000),
                uint48(1_800_086_400)
            )
        );
        require(OperationId.compute(op) == expected, "KNOWN_VECTOR");
    }

    function test_domainSeparationFieldsChangeId() external pure {
        GovernanceTypes.Operation memory op = _base();
        bytes32 baseline = OperationId.compute(op);

        GovernanceTypes.Operation memory changed = _base();
        changed.chainId = 84532;
        _assertChanged(changed, baseline, "CHAIN_ID");

        changed = _base();
        changed.safe = address(0x5555555555555555555555555555555555555555);
        _assertChanged(changed, baseline, "SAFE");

        changed = _base();
        changed.module = address(0x6666666666666666666666666666666666666666);
        _assertChanged(changed, baseline, "MODULE");

        changed = _base();
        changed.schemaVersion = keccak256("GATE-3D-2B-v2");
        _assertChanged(changed, baseline, "SCHEMA");
    }

    function test_payloadFieldsChangeId() external pure {
        GovernanceTypes.Operation memory op = _base();
        bytes32 baseline = OperationId.compute(op);
        GovernanceTypes.Operation memory changed;

        changed = _base(); changed.role = keccak256("EMERGENCY_PAUSER"); _assertChanged(changed, baseline, "ROLE");
        changed = _base(); changed.actor = address(0x7777777777777777777777777777777777777777); _assertChanged(changed, baseline, "ACTOR");
        changed = _base(); changed.target = address(0x8888888888888888888888888888888888888888); _assertChanged(changed, baseline, "TARGET");
        changed = _base(); changed.value = 1; _assertChanged(changed, baseline, "VALUE");
        changed = _base(); changed.calldataHash = keccak256(hex"87654321"); _assertChanged(changed, baseline, "CALLDATA");
        changed = _base(); changed.nonce = 8; _assertChanged(changed, baseline, "NONCE");
        changed = _base(); changed.executableAt += 1; _assertChanged(changed, baseline, "EXECUTABLE_AT");
        changed = _base(); changed.expiresAt += 1; _assertChanged(changed, baseline, "EXPIRES_AT");
    }

    function test_crossChainReplayProducesDifferentId() external pure {
        GovernanceTypes.Operation memory baseOp = _base();
        GovernanceTypes.Operation memory replay = _base();
        replay.chainId = 1;
        require(OperationId.compute(baseOp) != OperationId.compute(replay), "CROSS_CHAIN_REPLAY");
    }

    function test_nonceUniqueness() external pure {
        GovernanceTypes.Operation memory first = _base();
        GovernanceTypes.Operation memory second = _base();
        second.nonce = first.nonce + 1;
        require(OperationId.compute(first) != OperationId.compute(second), "NONCE_REUSE");
    }
}
