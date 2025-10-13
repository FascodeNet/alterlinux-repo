#!/usr/bin/env bash

set -eEuo pipefail

cd "$(dirname "$0")"

if ! which ayaka >/dev/null 2>&1; then
	echo "Please install ayaka-bin from AUR." >&2
	exit 1
fi
