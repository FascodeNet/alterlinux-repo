#!/usr/bin/env bash
set -euo pipefail

plan=${1:?Usage: build-matrix.sh plan.json}
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

# Parse metadata as data; never source PKGBUILD or .SRCINFO.
read_package() {
  local dir=$1 repo=$2
  [[ -f "$dir/PKGBUILD" && -f "$dir/.SRCINFO" ]] || return 1
  awk -F '=' '
    { key=$1; value=$2; gsub(/^[ \t]+|[ \t\r]+$/, "", key); gsub(/^[ \t]+|[ \t\r]+$/, "", value) }
    key == "pkgbase" || key == "pkgname" || key == "arch" { print key "\t" value }
  ' "$dir/.SRCINFO" | jq -Rn --arg repo "$repo" --arg dir "$dir" '
    [inputs | split("\t")] as $fields |
    [$fields[] | select(.[0] == "pkgbase") | .[1]] as $bases |
    [$fields[] | select(.[0] == "pkgname") | .[1]] as $names |
    if ($bases | length) != 1 or ($names | length) == 0 then
      error("Invalid package metadata: " + $dir)
    else {repo:$repo, base:$bases[0], names:($bases + $names),
      arches:[$fields[] | select(.[0] == "arch") | .[1]]} end
  ' >>"$workdir/packages.jsonl"
}

visit() {
  local dir=$1 repo=$2 child
  if [[ -f "$dir/PKGBUILD" && -f "$dir/.SRCINFO" ]]; then
    read_package "$dir" "$repo"
    return
  fi
  for child in "$dir"/*; do
    [[ -d "$child" ]] || continue
    if [[ -L "$child" ]]; then
      if [[ -f "$child/PKGBUILD" && -f "$child/.SRCINFO" ]]; then
        read_package "$child" "$repo"
      fi
    else
      visit "$child" "$repo"
    fi
  done
}

if [[ -n ${IN_PACKAGES:-} ]]; then
  : >"$workdir/packages.jsonl"
  jq -r '.repos[].dir' .ayakarc.json >"$workdir/repos"
  while IFS= read -r dir; do
    repo=$(jq -er '.name' "$dir/repo.json")
    visit "$dir" "$repo"
  done <"$workdir/repos"
  jq --slurpfile packages "$workdir/packages.jsonl" --arg input "$IN_PACKAGES" '
    ($input | [scan("[^\\s]+") ] | unique) as $names |
    [.build_matrix.include[] as $job |
      [$packages[] |
        select(.repo == $job.repo) |
        select((.arches | length) == 0 or (.arches | index("any")) != null or (.arches | index($job.arch)) != null) |
        select(any(.names[]; . as $name | $names | index($name)))
      ] as $selected |
      select(($selected | length) > 0) |
      {job:($job + {pkgs:([$selected[].base] | unique | join(" "))}), names:[$selected[].names[]]}
    ] as $jobs |
    ($names - [$jobs[].names[]]) as $missing |
    if ($missing | length) > 0 then
      error("Packages missing or unsupported on configured architectures: " + ($missing | join(" ")))
    else .build_matrix.include = [$jobs[].job] | .any_build = (($jobs | length) > 0) end
  ' "$plan" >"$workdir/plan.json"
  plan=$workdir/plan.json
fi

jq -r 'to_entries[] | select(.key == "build_matrix" or .key == "prune_matrix" or .key == "bumps" or .key == "any_build") | "\(.key)=\(.value | tojson)"' "$plan"
