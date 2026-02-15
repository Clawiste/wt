class Wt < Formula
  desc "Interactive git worktree manager"
  homepage "https://github.com/Clawiste/wt"
  url "https://github.com/Clawiste/wt/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "6fd7ce94cc31427deb5b30e96b1c3e385a6e683aa92d5fab9c4d1627bab929fb"
  license "MIT"

  depends_on xcode: ["15.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/wt"
  end

  test do
    assert_match "USAGE: wt", shell_output("#{bin}/wt --help")
  end
end
