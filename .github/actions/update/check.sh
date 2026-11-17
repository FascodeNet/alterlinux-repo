#!/usr/bin/env bash
set -euo pipefail

for attempt in 1 2 3; do
  status=0
  ayaka ci nvcheck --format json >nvcheck.jsonl || status=$?
  cat nvcheck.jsonl
  if ! jq -es 'any(.[]; .status? | strings | startswith("error: fetch latest"))' nvcheck.jsonl >/dev/null; then
    break
  fi
  if (( attempt < 3 )); then
    echo "::warning::Upstream fetch failed; retrying ($attempt/3)"
    sleep 5
  fi
done

jq -es '
  all(.[];
    type == "object" and
    (.repo | type == "string") and
    (.pkgbase | type == "string") and
    (.current | type == "string") and
    (.latest | type == "string") and
    (.method == "nvbump" or .method == "pull") and
    (.status == "up-to-date" or .status == "OUTDATED")
  )
' nvcheck.jsonl >/dev/null || {
  echo "::error::Upstream checks returned invalid results or a package check failed"
  exit 1
}

jq -c 'select(.status == "OUTDATED")' nvcheck.jsonl >outdated.jsonl
count=$(wc -l <outdated.jsonl)
if (( status != 0 && (status != 1 || count == 0) )); then
  echo "::error::ayaka ci nvcheck failed with exit code $status"
  exit 1
fi
printf 'count=%d\n' "$count" >>"$GITHUB_OUTPUT"
