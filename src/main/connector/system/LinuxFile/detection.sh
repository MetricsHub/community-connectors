#!/usr/bin/env bash

# detection.sh
# Usage example:
#   bash detection.sh "/opt/metricshub/logs/*,/opt/metricshub/lib/config/metricshub.yaml"

input=${1:-}
[ -z "$input" ] && exit 0

# Use an associative array to avoid duplicates
declare -A seen

# Split on commas into an array of patterns
IFS=',' read -r -a patterns <<< "$input"

for raw_pattern in "${patterns[@]}"; do
  # Trim spaces around the pattern
  pattern=$(echo "$raw_pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$pattern" ] && continue

  # Ask bash: "what files match this glob?"
  # compgen -G prints each match on its own line
  mapfile -t matches < <(compgen -G "$pattern" || true)

  # If no matches and the pattern is an existing regular file, keep it
  if [ "${#matches[@]}" -eq 0 ] && [ -f "$pattern" ]; then
    matches=("$pattern")
  fi

  # For each match: keep only existing regular files, no duplicates
  for path in "${matches[@]}"; do
    if [ -f "$path" ] && [ -z "${seen["$path"]+x}" ]; then
      echo "$path"
      seen["$path"]=1
    fi
  done
done
