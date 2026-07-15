#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${APPLE_ROUTE_BIN:-$ROOT/.build/release/apple-route}"

if [[ ! -x "$BIN" ]]; then
  swift build -c release --package-path "$ROOT"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$BIN" search "Sydney Opera House" --limit 1 --json > "$tmp/search.json"
jq -e '.schemaVersion == 1 and .command == "search" and (.results | length) >= 1' "$tmp/search.json" >/dev/null

"$BIN" route \
  --from "Sydney Town Hall" \
  --to "Sydney Opera House" \
  --mode walking \
  --json > "$tmp/route.json"
jq -e '.schemaVersion == 1 and .command == "route" and (.routes | length) >= 1' "$tmp/route.json" >/dev/null

"$BIN" eta \
  --from "Sydney Town Hall" \
  --to "Sydney Opera House" \
  --mode walking \
  --json > "$tmp/eta.json"
jq -e '.schemaVersion == 1 and .command == "eta" and .eta.expectedTravelTimeSeconds > 0' "$tmp/eta.json" >/dev/null

echo "Live MapKit smoke tests passed; all JSON parsed with jq."
