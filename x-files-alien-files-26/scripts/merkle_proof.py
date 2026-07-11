#!/usr/bin/env python3
import argparse
import hashlib
import json
from pathlib import Path

def sha256(data: bytes) -> bytes:
    return hashlib.sha256(data).digest()

def leaf_hash(path: Path) -> bytes:
    return sha256(path.read_bytes())

def build_tree(leaves):
    if not leaves:
        raise ValueError("no leaves")
    levels = [leaves]
    while len(levels[-1]) > 1:
        current = levels[-1]
        nxt = []
        for i in range(0, len(current), 2):
            left = current[i]
            right = current[i + 1] if i + 1 < len(current) else left
            nxt.append(sha256(left + right))
        levels.append(nxt)
    return levels

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--files", nargs="+", required=True)
    p.add_argument("--root-output", required=True)
    args = p.parse_args()

    paths = [Path(x) for x in args.files]
    for path in paths:
        if not path.is_file():
            raise SystemExit(f"missing file: {path}")

    leaves = [leaf_hash(path) for path in paths]
    tree = build_tree(leaves)
    root = tree[-1][0].hex()

    Path(args.root_output).write_text(root + "\n", encoding="utf-8")

    receipt = {
        "algorithm": "sha256",
        "leaf_order": [str(p) for p in paths],
        "leaf_hashes": [h.hex() for h in leaves],
        "merkle_root": root,
        "odd_node_rule": "duplicate_last",
        "authority": False
    }
    Path("receipts/merkle_proof.json").write_text(
        json.dumps(receipt, indent=2) + "\n",
        encoding="utf-8"
    )

    print(f"MERKLE_ROOT=0x{root}")

if __name__ == "__main__":
    main()
