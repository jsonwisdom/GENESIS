// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PolicyModel} from "../helpers/PolicyModel.sol";

contract InvariantManifestTest {
    function test_manifestCoverageCounts() external pure {
        require(PolicyModel.INVARIANT_COUNT == 22, "INV_COUNT");
        require(PolicyModel.ADVERSARIAL_TEST_COUNT == 50, "ADV_COUNT");
        require(PolicyModel.PROPERTY_COUNT == 12, "PROP_COUNT");
    }

    function test_manifestIdentifierBoundaries() external pure {
        require(PolicyModel.invariantId(1) == keccak256("INV-001"), "INV_FIRST");
        require(PolicyModel.invariantId(22) == keccak256("INV-022"), "INV_LAST");
        require(PolicyModel.adversarialId(1) == keccak256("ADV-001"), "ADV_FIRST");
        require(PolicyModel.adversarialId(50) == keccak256("ADV-050"), "ADV_LAST");
        require(PolicyModel.propertyId(1) == keccak256("PROP-001"), "PROP_FIRST");
        require(PolicyModel.propertyId(12) == keccak256("PROP-012"), "PROP_LAST");
    }
}
