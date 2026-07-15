// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library PolicyModel {
    uint256 internal constant INVARIANT_COUNT = 22;
    uint256 internal constant ADVERSARIAL_TEST_COUNT = 50;
    uint256 internal constant PROPERTY_COUNT = 12;

    function invariantId(uint256 n) internal pure returns (bytes32) {
        require(n >= 1 && n <= INVARIANT_COUNT, "INV_RANGE");
        return keccak256(abi.encodePacked("INV-", _threeDigits(n)));
    }

    function adversarialId(uint256 n) internal pure returns (bytes32) {
        require(n >= 1 && n <= ADVERSARIAL_TEST_COUNT, "ADV_RANGE");
        return keccak256(abi.encodePacked("ADV-", _threeDigits(n)));
    }

    function propertyId(uint256 n) internal pure returns (bytes32) {
        require(n >= 1 && n <= PROPERTY_COUNT, "PROP_RANGE");
        return keccak256(abi.encodePacked("PROP-", _threeDigits(n)));
    }

    function _threeDigits(uint256 n) private pure returns (bytes3) {
        return bytes3(uint24((48 + (n / 100)) << 16 | (48 + ((n / 10) % 10)) << 8 | (48 + (n % 10))));
    }
}
