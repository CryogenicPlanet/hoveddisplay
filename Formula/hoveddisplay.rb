class Hoveddisplay < Formula
  desc "macOS command-line utility to configure main display"
  homepage "https://github.com/CryogenicPlanet/hoveddisplay"
  url "https://github.com/CryogenicPlanet/hoveddisplay/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "2a577a6d75b9efb840751e16d7e4534e6df28361c67ffcb0970e3f2e74c8bfe6"
  license "MIT"

  depends_on xcode: [">= 11.2", :build]
  depends_on macos: [
    :catalina,
    :big_sur,
  ]

  def install
    cd "src-swift"
    system "swift", "build", "--disable-sandbox", "--configuration", "release"
    bin.install ".build/release/hoveddisplay"
  end

  test do
    system "hoveddisplay", "list"
  end
end
