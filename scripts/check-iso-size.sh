#!/usr/bin/env bash
set -euo pipefail

hard_limit=8000000000
warn_limit=7400000000

iso="${1:-}"

if [ -z "$iso" ] || [ ! -f "$iso" ]; then
  echo "usage: check-iso-size.sh <iso>" >&2
  exit 2
fi

size="$(stat -c %s "$iso")"
echo "$iso: $size bytes"

if [ "$size" -gt "$hard_limit" ]; then
  echo "error: ISO exceeds the 8 GB hard limit" >&2
  exit 1
fi

if [ "$size" -gt "$warn_limit" ]; then
  echo "warning: ISO exceeds 7.4 GB; an 8 GB USB may not fit it" >&2
fi
