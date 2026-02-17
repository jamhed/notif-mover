cask "notif-mover" do
  version "1.4.0"
  sha256 "af48973497c01e8625442aadc74d01c7409a61d5d6a36c8f0af5d2c5033875d3"

  url "https://github.com/jamhed/notif-mover/releases/download/v#{version}/NotifMover.app.tar.gz"
  name "NotifMover"
  desc "Move macOS 26 (Tahoe) notifications to bottom-right corner"
  homepage "https://github.com/jamhed/notif-mover"

  depends_on macos: ">= :sonoma"

  app "NotifMover.app"

  livecheck do
    url "https://github.com/jamhed/notif-mover/releases/latest"
    strategy :github_latest
  end
end
