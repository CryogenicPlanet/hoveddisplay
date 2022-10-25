class Hoveddisplay < Formula
  desc "macOS command-line utility to configure main display"
  homepage "https://github.com/CryogenicPlanet/hoveddisplay"
  url "https://github.com/CryogenicPlanet/hoveddisplay/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "da0a5d73cc9c704c9e7ba9ee512fba5f8d3136979f2560ad25438608b84bbe27"
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
