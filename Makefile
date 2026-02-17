INSTALL_DIR = $(HOME)/Applications/NotifMover.app
BUNDLE_DIR = NotifMover.app

all: build

build:
	@mkdir -p $(BUNDLE_DIR)/Contents/MacOS
	@cp Info.plist $(BUNDLE_DIR)/Contents/Info.plist
	swiftc notif-mover.swift -o $(BUNDLE_DIR)/Contents/MacOS/NotifMover-x86_64 -O -target x86_64-apple-macos14.0
	swiftc notif-mover.swift -o $(BUNDLE_DIR)/Contents/MacOS/NotifMover-arm64 -O -target arm64-apple-macos14.0
	lipo -create -output $(BUNDLE_DIR)/Contents/MacOS/NotifMover $(BUNDLE_DIR)/Contents/MacOS/NotifMover-x86_64 $(BUNDLE_DIR)/Contents/MacOS/NotifMover-arm64
	@rm $(BUNDLE_DIR)/Contents/MacOS/NotifMover-x86_64 $(BUNDLE_DIR)/Contents/MacOS/NotifMover-arm64
	codesign -fvs - $(BUNDLE_DIR)

install: build
	@mkdir -p $(HOME)/Applications
	rm -rf $(INSTALL_DIR)
	cp -R $(BUNDLE_DIR) $(INSTALL_DIR)
	@cp com.local.notif-mover.plist $(HOME)/Library/LaunchAgents/
	@sed -i '' 's|HOMEDIR|$(HOME)|g' $(HOME)/Library/LaunchAgents/com.local.notif-mover.plist
	@echo "Installed. Grant accessibility permission to NotifMover, then run:"
	@echo "  launchctl load ~/Library/LaunchAgents/com.local.notif-mover.plist"

uninstall:
	launchctl unload $(HOME)/Library/LaunchAgents/com.local.notif-mover.plist 2>/dev/null || true
	rm -f $(HOME)/Library/LaunchAgents/com.local.notif-mover.plist
	rm -rf $(INSTALL_DIR)

clean:
	rm -rf $(BUNDLE_DIR)

.PHONY: all build install uninstall clean
