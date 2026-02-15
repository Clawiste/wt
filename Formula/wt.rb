class Wt < Formula
  desc "Interactive git worktree manager"
  homepage "https://github.com/Clawiste/wt"
  url "https://github.com/Clawiste/wt/archive/refs/tags/v1.0.0.tar.gz"
  sha256 ""
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
