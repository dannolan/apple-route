# 🗺️ apple-route

Apple Maps from your terminal.

`apple-route` is a small, hackable, macOS-only CLI over Apple's native MapKit. Search for places, calculate routes, get ETAs, and hand clean JSON to shell scripts or LLM agents.

No API keys. No backend. No account. No hosted service. Just one Swift executable talking to the MapKit already on your Mac. ✨

This is an experimental developer tool, not a production routing platform. That's the point.

## 🍺 Install

```sh
brew tap dannolan/tap
brew install apple-route
```

Then give it a spin:

```sh
apple-route route \
  --from "Sydney Town Hall" \
  --to "Sydney Opera House" \
  --mode walking
```

## Why this exists

Apple's native place and routing data is excellent, but it normally lives behind a GUI. I wanted the useful bits in Terminal—something a human can poke at, a shell script can compose, and an agent can call without standing up another service.

So this stays deliberately boring:

- 🧭 Native `MKLocalSearch` and `MKDirections`
- 🤖 Stable Codable JSON for agents and scripts
- 🔐 No credentials, JWTs, databases, daemons, or telemetry
- 🔧 Compact Swift you can actually read and hack on
- 🍎 macOS only, unapologetically

## ✅ Requirements

- macOS 13 or newer
- Network access for live MapKit requests

## 🔎 Search

```sh
apple-route search "Art Gallery of NSW"
apple-route search "coffee" --near=-33.8688,151.2093
apple-route search "Sydney Airport" --limit 5 --json
```

Search results include names, formatted addresses where available, coordinates, phone numbers, URLs, and point-of-interest categories.

## 🚗 Routes

Inputs can be natural-language places/addresses or `latitude,longitude` coordinates.

```sh
apple-route route \
  --from "Sydney Airport" \
  --to "Art Gallery of NSW" \
  --mode driving

apple-route route \
  --from=-33.9399,151.1753 \
  --to=-33.8688,151.2093 \
  --mode transit \
  --arrive "2026-07-18T10:00:00+10:00" \
  --alternatives \
  --json
```

Modes are `driving`, `walking`, `transit`, and `cycling`. Cycling requires a supported macOS SDK/runtime and route coverage. `--depart` and `--arrive` accept ISO-8601 timestamps and are mutually exclusive. Use `--near=latitude,longitude` to bias natural-language endpoint resolution.

## ⏱️ ETA

```sh
apple-route eta \
  --from "Sydney Town Hall" \
  --to "Sydney Opera House" \
  --mode walking \
  --json
```

## 🤖 JSON and agent use

With `--json`, stdout is JSON. Full stop. Diagnostics and structured error envelopes go to stderr, so piping into `jq` won't become a small personal tragedy. The schema starts at version 1.

```json
{
  "schemaVersion": 1,
  "command": "search",
  "results": [
    {
      "name": "Sydney Opera House",
      "address": "Bennelong Point, Sydney NSW 2000, Australia",
      "latitude": -33.8568,
      "longitude": 151.2153
    }
  ]
}
```

Optional values may be omitted by Swift's default `Codable` encoding when MapKit does not provide them.

An LLM agent can request an arrival-aware public transport route and parse it directly:

```sh
apple-route route \
  --from "Hotel name, Melbourne" \
  --to "Dinner reservation address" \
  --mode transit \
  --arrive "2026-08-12T19:00:00+10:00" \
  --json
```

For shell automation:

```sh
apple-route eta --from "$ORIGIN" --to "$DESTINATION" --mode walking --json \
  | jq -r '.eta.expectedTravelTimeSeconds'
```

Exit codes are stable: `2` invalid arguments, `3` place not found, `4` ambiguous place, `5` route unavailable, `6` network/MapKit failure, and `7` unsupported transport mode.

## 🧯 Troubleshooting and limitations

- **Missing route:** MapKit may not offer the requested mode between those points. Try explicit coordinates, a different mode, or omit a future departure/arrival time.
- **Ambiguous place:** Add city/state/country context or use `--near`. The resolver refuses obviously unrelated top results instead of silently choosing one.
- **Unsupported cycling:** Cycling needs macOS 11+ and local MapKit cycling coverage. A supported runtime can still return no cycling route.
- **Network failure:** MapKit is an online Apple service. Check connectivity and retry; errors go to stderr and exit with code 6.
- **Throttling:** Apple does not publish a command-line quota for native MapKit. Treat it as an interactive API, avoid high-volume parallel requests, cache results where appropriate, and expect requests to be throttled or fail transiently.
- **Transit:** The macOS MapKit SDK exposes transit through `calculateETA()` but may not return detailed routes from `calculate()`. When transit ETA data exists but detailed directions do not, `route` returns one clearly identified `Transit ETA` result with an advisory notice and no steps or alternatives. Coverage and schedule horizons vary by region.
- **Output:** Names, instructions, units, and notices can be localized by the current macOS environment.

This project uses Apple's native frameworks only. There is no server API, authentication, database, daemon, telemetry, or cloud component hiding around the corner.

`apple-route` is an independent project and is not affiliated with or endorsed by Apple Inc. Apple, Apple Maps, MapKit, and macOS are trademarks of Apple Inc.

## 📄 License

MIT. See [LICENSE](LICENSE).
