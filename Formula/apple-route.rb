class AppleRoute < Formula
  desc "Native Apple MapKit place search, routes, and ETAs from Terminal"
  homepage "https://github.com/dannolan/apple-route"
  url "https://github.com/dannolan/apple-route/archive/refs/tags/v0.1.0.tar.gz"
  # Replace this all-zero placeholder with the release tarball's SHA-256.
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"
  head "https://github.com/dannolan/apple-route.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/apple-route"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/apple-route --version") unless build.head?
    assert_match "USAGE: apple-route search", shell_output("#{bin}/apple-route search --help")
    assert_match "Expected coordinates", shell_output("#{bin}/apple-route search coffee --near invalid 2>&1", 2)
  end
end
