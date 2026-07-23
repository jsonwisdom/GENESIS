#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/receipts/first-verify.log"
mkdir -p "$ROOT/receipts"

fail() {
  printf 'FAIL_CLOSED: %s\n' "$1" | tee "$OUT"
  exit 1
}

cd "$ROOT"
git diff --quiet || fail "working tree dirty"

COMMIT_SHA="$(git rev-parse HEAD)"
SCRIPT_SHA256="$(sha256sum scripts/verify-package.sh | cut -d' ' -f1)"

CID_FILE="$ROOT/package/cid.txt"
MANIFEST="$ROOT/manifest.json"
CHECKSUMS="$ROOT/package/checksums.sha256"
PACKAGE="$ROOT/package/XFA26_Generational_Court_Fees.zip"
ZORA_RECEIPT="$ROOT/receipts/zora-coin.json"
GENESIS_EAS="$ROOT/eas/attestations/baby-gray-genesis.json"
WITNESS_EAS="$ROOT/eas/attestations/witness-claim.json"

for file in "$CID_FILE" "$MANIFEST" "$CHECKSUMS" "$PACKAGE" "$ZORA_RECEIPT" "$GENESIS_EAS" "$WITNESS_EAS"; do
  [[ -f "$file" ]] || fail "missing ${file#$ROOT/}"
done

CID="$(tr -d '[:space:]' < "$CID_FILE")"
[[ "$CID" =~ ^bafy[a-z2-7]+$ ]] || fail "invalid CID format"
grep -Fq "$CID" "$MANIFEST" || fail "manifest does not bind declared CID"

sha256sum --check "$CHECKSUMS" || fail "checksum verification failed"

GENESIS_UID="0xec9a29523f3ed0aac4e199ea6e34d07bf0ce015220678edde71444ff0230f1c8"
WITNESS_UID="0x51b2e15b67a54d0600721dc7e2980d5c6a81e443746b77b179e87f1632ed75f9"
SCHEMA_GENESIS="0x0fffbc9973d10dbd45c605272968227933d6ea9af9f5d2d45c03dd8e0c1e4b2d"
SCHEMA_WITNESS="0x5e9141f023269a24ef29eb14428376cd0fa7687b384b6c0ac1cd0847240ea384"

grep -Fq "$GENESIS_UID" "$GENESIS_EAS" || fail "genesis UID mismatch"
grep -Fq "$SCHEMA_GENESIS" "$GENESIS_EAS" || fail "genesis schema mismatch"
grep -Fq "$WITNESS_UID" "$WITNESS_EAS" || fail "witness UID mismatch"
grep -Fq "$SCHEMA_WITNESS" "$WITNESS_EAS" || fail "witness schema mismatch"
grep -Fq '"referenced_attestation": null' "$WITNESS_EAS" || fail "witness reference state not explicitly recorded"

grep -Fq '0x14a6f025031d401062289dc18c6c95e81220ca69' "$ZORA_RECEIPT" || fail "Zora contract binding missing"
grep -Fq '"chain_id": 8453' "$ZORA_RECEIPT" || fail "Base chain binding missing"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

IPFS_METHOD="gateway"
if command -v ipfs >/dev/null 2>&1 && ipfs cat "$CID" > "$TMP" 2>/dev/null; then
  IPFS_METHOD="local"
else
  curl --fail --silent --show-error --location --max-time 60 \
    "https://ipfs.io/ipfs/$CID" --output "$TMP" || fail "CID retrieval failed"
fi

[[ -s "$TMP" ]] || fail "retrieved CID content is empty"

{
  echo "VERIFY_PACKAGE_V1"
  echo "STATUS=PASS"
  echo "SOURCE_COMMIT=$COMMIT_SHA"
  echo "SCRIPT_SHA256=$SCRIPT_SHA256"
  echo "RUNNER_HOST=$(hostname)"
  echo "CID=$CID"
  echo "IPFS_METHOD=$IPFS_METHOD"
  echo "RETRIEVAL_STATUS=OBSERVED"
  echo "PACKAGE_VERIFICATION=PASS"
  echo "LOCAL_EAS_BIND=PASS"
  echo "GENESIS_EAS_UID=$GENESIS_UID"
  echo "WITNESS_EAS_UID=$WITNESS_UID"
  echo "GENESIS_SCHEMA_UID=$SCHEMA_GENESIS"
  echo "WITNESS_SCHEMA_UID=$SCHEMA_WITNESS"
  echo "WITNESS_REFUID_BOUND=false"
  echo "EAS_RECEIPT_STATUS=LOCAL_FIELDS_MATCHED"
  echo "ONCHAIN_EAS_REPLAY=UNOBSERVED"
  echo "ZORA_PACKAGE_BINDING=UNOBSERVED"
  echo "AUTHORITY=false"
  echo "OBSERVED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} | tee "$OUT"
