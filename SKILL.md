---
name: apple-route
description: Search Apple Maps places and calculate native MapKit routes and ETAs from macOS Terminal with stable JSON. Use when an agent needs current place details, coordinates, travel distance, directions, or arrival-aware journey timing on macOS.
---

# Apple Route

Use the installed `apple-route` executable for live place and routing questions. Prefer `--json` so results remain machine-readable.

## Quick start

```sh
apple-route search "Sydney Opera House" --limit 3 --json

apple-route route \
  --from "Sydney Town Hall" \
  --to "Sydney Opera House" \
  --mode walking \
  --json

apple-route eta \
  --from=-33.8732,151.2065 \
  --to=-33.8568,151.2153 \
  --mode walking \
  --json
```

## Workflow

1. Confirm the origin, destination, travel mode, and any timing constraint.
2. Search first when a place is ambiguous; add `--near=latitude,longitude` or city/country context.
3. Pass either a natural-language place/address or `latitude,longitude` to `--from` and `--to`.
4. Use exactly one of `--depart <ISO-8601>` or `--arrive <ISO-8601>` when timing matters.
5. Parse stdout as JSON. Treat stderr as diagnostics or a structured JSON error envelope.
6. Check the process exit code before relying on output.

Supported modes are `driving`, `walking`, `transit`, and `cycling`. Add `--alternatives` to `route` when useful.

## Output contract

Every JSON response has `schemaVersion: 1` and a command-specific envelope:

- `search`: inspect `.results[]`.
- `route`: inspect `.origin`, `.destination`, and `.routes[]`.
- `eta`: inspect `.origin`, `.destination`, and `.eta`.

Exit codes are `2` invalid arguments, `3` place not found, `4` ambiguous place, `5` route unavailable, `6` MapKit/network failure, and `7` unsupported mode.

On macOS runtimes where MapKit only provides transit ETA data, `route --mode transit` returns a clearly labelled `Transit ETA` route with an advisory notice and no invented steps.

## Guardrails

- Do not treat MapKit results as static; queries require network access and may be throttled.
- Do not silently choose an unrelated result. Refine the query or use coordinates.
- Preserve the returned resolved origin and destination in downstream reasoning.
- Do not infer missing phone numbers, URLs, notices, steps, or categories.
