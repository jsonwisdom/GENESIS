#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

MANIFEST="MANIFEST.INTEGRITY.json"

fail_manifest() {
  echo "MANIFEST_HASH_MISMATCH"
  exit 30
}

fail_spec() {
  echo "SPEC_HASH_MISMATCH"
  exit 31
}

[[ -f "$MANIFEST" ]] || fail_manifest

python3 - "$MANIFEST" <<'PY' || exit $?
import hashlib
import json
import pathlib
import sys

MANIFEST_EXIT = 30
SPEC_EXIT = 31
manifest_path = pathlib.Path(sys.argv[1])

try:
    raw = manifest_path.read_bytes()
    manifest = json.loads(raw.decode("utf-8"))
except Exception:
    print("MANIFEST_HASH_MISMATCH")
    raise SystemExit(MANIFEST_EXIT)

required_keys = {
    "FORMAT",
    "MANIFEST_SHA256",
    "REQUIRED_RULE",
    "SPEC_PATH",
    "SPEC_SHA256",
}

if set(manifest) != required_keys:
    print("MANIFEST_HASH_MISMATCH")
    raise SystemExit(MANIFEST_EXIT)

if manifest.get("FORMAT") != "GENESIS_MANIFEST_INTEGRITY_V1":
    print("MANIFEST_HASH_MISMATCH")
    raise SystemExit(MANIFEST_EXIT)

stored_manifest_hash = manifest.get("MANIFEST_SHA256")
if not isinstance(stored_manifest_hash, str) or len(stored_manifest_hash) != 64:
    print("MANIFEST_HASH_MISMATCH")
    raise SystemExit(MANIFEST_EXIT)

hash_view = dict(manifest)
hash_view["MANIFEST_SHA256"] = None
canonical = (
    json.dumps(
        hash_view,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )
    + "\n"
).encode("utf-8")
computed_manifest_hash = hashlib.sha256(canonical).hexdigest()

if computed_manifest_hash != stored_manifest_hash:
    print("MANIFEST_HASH_MISMATCH")
    raise SystemExit(MANIFEST_EXIT)

spec_path_value = manifest.get("SPEC_PATH")
required_rule = manifest.get("REQUIRED_RULE")
stored_spec_hash = manifest.get("SPEC_SHA256")

if not all(isinstance(v, str) and v for v in (spec_path_value, required_rule, stored_spec_hash)):
    print("SPEC_HASH_MISMATCH")
    raise SystemExit(SPEC_EXIT)

spec_path = pathlib.Path(spec_path_value)
try:
    spec_bytes = spec_path.read_bytes()
except OSError:
    print("SPEC_HASH_MISMATCH")
    raise SystemExit(SPEC_EXIT)

if required_rule.encode("utf-8") not in spec_bytes:
    print("REQUIRED_RULE_MISSING")
    raise SystemExit(SPEC_EXIT)

computed_spec_hash = hashlib.sha256(spec_bytes).hexdigest()
if computed_spec_hash != stored_spec_hash:
    print("SPEC_HASH_MISMATCH")
    raise SystemExit(SPEC_EXIT)

print(f"MANIFEST_SHA256={computed_manifest_hash}")
print(f"SPEC_SHA256={computed_spec_hash}")
print(f"REQUIRED_RULE={required_rule}")
print("INTEGRITY_OK")
PY
