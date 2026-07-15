---
name: apple-route
description: Search Apple Maps places and calculate native MapKit driving, walking, cycling, and public transport routes or ETAs with stable JSON. Use when an agent needs current place details, coordinates, travel distance, directions, or departure and arrival timing on macOS.
---

# Apple Route

Use `apple-route` for live place and routing questions on macOS. It talks directly to native MapKit: no API key, account, or backend. Prefer `--json` so results remain machine-readable.

## Readiness

Check the executable before starting:

```sh
command -v apple-route && apple-route --version
```

If it is missing, ask before installing, then use the public Homebrew tap:

```sh
brew tap dannolan/tap
brew install apple-route
```

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

apple-route route \
  --from "Hotel name, Melbourne" \
  --to "Dinner reservation address" \
  --mode transit \
  --arrive "2026-08-12T19:00:00+10:00" \
  --json
```

## Pick the command

- Use `search` to resolve a place, address, or category.
- Use `route` when distance, travel time, notices, steps, or alternatives matter.
- Use `eta` when the journey duration and expected departure/arrival are enough.

## Workflow

1. Confirm the origin, destination, travel mode, and any timing constraint.
2. Search first when a place is ambiguous; add `--near=latitude,longitude` or city/country context.
3. Pass either a natural-language place/address or `latitude,longitude` to `--from` and `--to`.
4. Use exactly one of `--depart <ISO-8601>` or `--arrive <ISO-8601>` when timing matters.
5. Parse stdout as JSON. Treat stderr as diagnostics or a structured JSON error envelope.
6. Check the process exit code before relying on output.

Supported modes are `driving`, `walking`, `transit` (public transport), and `cycling`. Add `--alternatives` to `route` when useful.

## Output contract

Every JSON response has `schemaVersion: 1` and a command-specific envelope:

- `search`: inspect `.results[]`.
- `route`: inspect `.origin`, `.destination`, and `.routes[]`.
- `eta`: inspect `.origin`, `.destination`, and `.eta`.

Exit codes are `2` invalid arguments, `3` place not found, `4` ambiguous place, `5` route unavailable, `6` MapKit/network failure, and `7` unsupported mode.

On macOS runtimes where MapKit only provides transit ETA data, `route --mode transit` returns a clearly labelled `Transit ETA` route with an advisory notice and no invented steps.

## Guardrails

- Do not treat MapKit results as static; queries require network access and may be throttled.
- Do not install or upgrade the executable without user authorization.
- Do not silently choose an unrelated result. Refine the query or use coordinates.
- Preserve the returned resolved origin and destination in downstream reasoning.
- Do not infer missing phone numbers, URLs, notices, steps, or categories.
