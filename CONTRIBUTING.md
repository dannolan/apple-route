# Contributing

`apple-route` is intentionally small. Keep changes native, headless, and easy to understand.

## Requirements

- macOS 13 or newer
- Xcode 15 or newer
- Swift Package Manager
- `jq` for the live smoke test

## Build and test

```sh
swift build
swift test
swift build -c release
```

Unit tests must stay deterministic and must not call live Apple services.

Run the opt-in live checks before publishing routing changes:

```sh
./Scripts/smoke-test.sh
```

The smoke script searches for Sydney Opera House, calculates a walking route and ETA, and validates every JSON response with `jq`.

## Project shape

- `Commands/` owns CLI parsing and command orchestration.
- `MapKit/` owns live place resolution and directions calls.
- `Models/` owns the Codable JSON contract.
- `Output/` owns human and JSON rendering.
- `Support/` contains small parsers, formatters, and errors.

Avoid abstraction layers unless they make testing materially easier. Keep diagnostics on stderr and preserve JSON-only stdout whenever `--json` is present.

For publishing, see [docs/releasing.md](docs/releasing.md).
