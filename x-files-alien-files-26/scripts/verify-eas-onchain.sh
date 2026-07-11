#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/receipts/eas-onchain-replay-0001.log"

fail() {
  printf 'FAIL_CLOSED: %s\n' "$1" | tee "$OUT"
  exit 1
}

: "${BASE_RPC_URL:?BASE_RPC_URL required}"
: "${EAS_CONTRACT:?EAS_CONTRACT required}"

command -v cast >/dev/null || fail "Foundry cast unavailable"

cd "$ROOT"
git diff --quiet || fail "working tree dirty"

COMMIT_SHA="$(git rev-parse HEAD)"
SCRIPT_SHA256="$(sha256sum scripts/verify-eas-onchain.sh | cut -d' ' -f1)"

GENESIS_UID="0xec9a29523f3ed0aac4e199ea6e34d07bf0ce015220678edde71444ff0230f1c8"
WITNESS_UID="0x51b2e15b67a54d0600721dc7e2980d5c6a81e443746b77b179e87f1632ed75f9"

query_uid() {
  cast call \
    "$EAS_CONTRACT" \
    "getAttestation(bytes32)((bytes32,bytes32,uint64,uint64,uint64,bytes32,address,address,bool,bytes))" \
    "$1" \
    --rpc-url "$BASE_RPC_URL"
}

GENESIS_RAW="$(query_uid "$GENESIS_UID")" || fail "genesis UID query failed"
WITNESS_RAW="$(query_uid "$WITNESS_UID")" || fail "witness UID query failed"

[[ -n "$GENESIS_RAW" ]] || fail "empty genesis response"
[[ -n "$WITNESS_RAW" ]] || fail "empty witness response"

{
  echo "ONCHAIN_EAS_REPLAY_V1"
  echo "STATUS=OBSERVED"
  echo "SOURCE_COMMIT=$COMMIT_SHA"
  echo "SCRIPT_SHA256=$SCRIPT_SHA256"
  echo "CHAIN_ID=8453"
  echo "EAS_CONTRACT=$EAS_CONTRACT"
  echo "GENESIS_UID=$GENESIS_UID"
  echo "WITNESS_UID=$WITNESS_UID"
  echo "GENESIS_RAW=$GENESIS_RAW"
  echo "WITNESS_RAW=$WITNESS_RAW"
  echo "RPC_QUERY=OBSERVED"
  echo "UID_RESPONSES=OBSERVED"
  echo "SCHEMA_MATCH=PENDING"
  echo "ATTESTER_MATCH=PENDING"
  echo "RECIPIENT_MATCH=PENDING"
  echo "REVOCATION_MATCH=PENDING"
  echo "PAYLOAD_DECODE_STATUS=UNVERIFIED"
  echo "FIELD_COMPARISON_STATUS=PENDING"
  echo "ONCHAIN_EAS_REPLAY_VERIFIED=false"
  echo "AUTHORITY=false"
  echo "OBSERVED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} | tee "$OUT"
