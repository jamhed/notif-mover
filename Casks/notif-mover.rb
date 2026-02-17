cask "notif-mover" do
  version "1.4.1"
  sha256 "b99987dafd9b45fd02dc1963967f88b732404a0ce91e5de13ef40ef442b4bbe6"

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
