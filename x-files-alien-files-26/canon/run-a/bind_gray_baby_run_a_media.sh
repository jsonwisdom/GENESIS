#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="${1:-$HOME/GENESIS}"
BRANCH="xfa26-genesis-root"
RUN_ROOT="$REPO_ROOT/x-files-alien-files-26/canon/run-a"
MEDIA_DIR="$RUN_ROOT/media"
BUNDLE_B64="${2:-$RUN_ROOT/gray_baby_run_a_media.bundle.b64}"

mkdir -p "$RUN_ROOT" "$MEDIA_DIR" "$RUN_ROOT/receipts"

test -d "$REPO_ROOT/.git" || {
  echo "HALT: repository root missing: $REPO_ROOT" >&2
  exit 40
}

git -C "$REPO_ROOT" fetch origin "$BRANCH"
git -C "$REPO_ROOT" checkout "$BRANCH"
git -C "$REPO_ROOT" reset --hard "origin/$BRANCH"

if [[ ! -s "$BUNDLE_B64" ]]; then
  echo "HALT: encoded media bundle missing: $BUNDLE_B64" >&2
  echo "MEDIA_PRESENT=FALSE" >&2
  echo "RUN_A_REPOSITORY_BOUND=FALSE" >&2
  exit 41
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

base64 -d "$BUNDLE_B64" > "$TMP_DIR/run-a-media.tar"
tar -xf "$TMP_DIR/run-a-media.tar" -C "$MEDIA_DIR"

printf '%s  %s\n' \
'fdafe9d182a417e71e9285ef33c768b2cbc0339a98b428e8f41b02f06e52fc47' \
"$MEDIA_DIR/GB-006.png" \
'6c0a4b20139cec881bb9252d950d0fdaa72f8b1120882ea2716f8bdb7ba52d64' \
"$MEDIA_DIR/GB-007.png" \
'6e89f160bf30ed71dbc6329ba65a11443f5ffabd63a4a02f8b9e6308a364633d' \
"$MEDIA_DIR/GB-008.png" |
sha256sum --check --strict

test "$(wc -c < "$MEDIA_DIR/GB-006.png")" -eq 2418781
test "$(wc -c < "$MEDIA_DIR/GB-007.png")" -eq 2266034
test "$(wc -c < "$MEDIA_DIR/GB-008.png")" -eq 2528348

git -C "$REPO_ROOT" add \
  "$MEDIA_DIR/GB-006.png" \
  "$MEDIA_DIR/GB-007.png" \
  "$MEDIA_DIR/GB-008.png"

git -C "$REPO_ROOT" diff --cached --check

if git -C "$REPO_ROOT" diff --cached --quiet; then
  echo "NO_MEDIA_CHANGES=TRUE"
else
  git -C "$REPO_ROOT" commit -m "add Gray Baby Run A verified media"
  git -C "$REPO_ROOT" push origin "$BRANCH"
fi

git -C "$REPO_ROOT" fetch origin "$BRANCH"
LOCAL_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD)"
REMOTE_HEAD="$(git -C "$REPO_ROOT" rev-parse "origin/$BRANCH")"
test "$LOCAL_HEAD" = "$REMOTE_HEAD"

echo "LOCAL_HEAD=$LOCAL_HEAD"
echo "REMOTE_HEAD=$REMOTE_HEAD"
echo "ROOT_TO_ROOT=PASS"
echo "MEDIA_PRESENT=TRUE"
echo "MEDIA_HASH_BINDING=VERIFIED"
echo "RECEIPT_PROMOTION=PENDING"
echo "AUTHORITY=FALSE"
