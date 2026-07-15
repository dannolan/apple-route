# Releasing apple-route

This is the maintainer runbook for publishing a tagged release and updating `dannolan/tap/apple-route`.

## 1. Prepare the version

Update the version in:

- `Sources/AppleRoute/AppleRoute.swift`
- `Formula/apple-route.rb`

Point the formula URL at the intended tag. Leave its checksum for the post-tag update.

Run the complete local checks:

```sh
swift test
swift build -c release
./Scripts/smoke-test.sh
HOMEBREW_NO_AUTO_UPDATE=1 brew style Formula/apple-route.rb
```

Commit and push the version change before tagging.

## 2. Publish the GitHub release

Replace `VERSION` with a value such as `0.2.0`:

```sh
export VERSION=0.2.0
gh release create "v$VERSION" \
  --repo dannolan/apple-route \
  --target main \
  --title "apple-route $VERSION" \
  --generate-notes
```

Never move a published tag. GitHub-generated archive checksums depend on it remaining immutable.

## 3. Calculate the source checksum

```sh
curl -fsSL \
  "https://github.com/dannolan/apple-route/archive/refs/tags/v$VERSION.tar.gz" \
  -o "apple-route-$VERSION.tar.gz"
shasum -a 256 "apple-route-$VERSION.tar.gz"
```

Put that SHA-256 into `Formula/apple-route.rb`, commit it, and push `main`.

## 4. Update the tap

Clone the tap with GitHub CLI and copy the finished formula:

```sh
gh repo clone dannolan/homebrew-tap
cp Formula/apple-route.rb homebrew-tap/Formula/apple-route.rb
cd homebrew-tap
brew style Formula/apple-route.rb
git add Formula/apple-route.rb
git commit -m "Update apple-route $VERSION"
git push origin main
```

## 5. Verify the public tap

```sh
brew update
brew upgrade dannolan/tap/apple-route
brew test dannolan/tap/apple-route
brew audit --strict dannolan/tap/apple-route
apple-route --version
```

Run the live smoke suite against the installed binary from the source checkout:

```sh
APPLE_ROUTE_BIN="$(brew --prefix apple-route)/bin/apple-route" \
  ./Scripts/smoke-test.sh
```

Confirm the release and formula are public:

```sh
gh release view "v$VERSION" --repo dannolan/apple-route
gh api repos/dannolan/homebrew-tap/contents/Formula/apple-route.rb \
  --jq '.html_url'
```
