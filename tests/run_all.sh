#!/usr/bin/env bash
set -e
shopt -s nullglob
cd "$(dirname "$0")/.."
for f in tests/test_*.lua; do
  echo "== $f =="
  lua "$f"
done
