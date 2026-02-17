# notif-mover

Moves macOS notification banners from the top-right corner to the bottom-right.

Built for **macOS 26 (Tahoe)** where Apple changed the notification AX hierarchy, breaking existing tools like [PingPlace](https://github.com/NotWadeGrimridge/PingPlace).

## How it works

On macOS 26, notifications live inside a full-screen `AXSystemDialog` window. Inner notification elements can't be repositioned. This tool listens for `AXLayoutChanged` events and shifts the parent window so the notification appears at the bottom-right of the screen.

~80 lines of Swift. No dependencies.

## Install

### Homebrew

```
brew tap jamhed/notif-mover
brew install --cask notif-mover
```

### From source

```
make install
```

Then grant accessibility permission to **NotifMover** in:

**System Settings > Privacy & Security > Accessibility**

Start the daemon:

```
launchctl load ~/Library/LaunchAgents/com.local.notif-mover.plist
```

## Uninstall

### Homebrew

```
brew uninstall notif-mover
```

### From source

```
make uninstall
```

## Requirements

- macOS 26 (Tahoe)
- Accessibility permission
