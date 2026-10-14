#!/usr/bin/env bash
set -euo pipefail
# This fork has no upstream credentials, appcast or hosted release pipeline.
echo "Use scripts/reload.sh --tag <tag> --release --build-only to verify the local distribution." >&2
exit 2
