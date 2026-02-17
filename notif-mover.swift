import ApplicationServices
import Cocoa

let ncBundleID = "com.apple.notificationcenterui"
var cachedListY: CGFloat?       // notification list Y offset within the window (at origin)
var debounceItem: DispatchWorkItem?

func findElement(root: AXUIElement, targetSubroles: [String]) -> AXUIElement? {
    var subroleRef: AnyObject?
    if AXUIElementCopyAttributeValue(root, kAXSubroleAttribute as CFString, &subroleRef) == .success,
       let subrole = subroleRef as? String, targetSubroles.contains(subrole) {
        return root
    }
    var childrenRef: AnyObject?
    if AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
       let children = childrenRef as? [AXUIElement] {
        for child in children {
            if let found = findElement(root: child, targetSubroles: targetSubroles) { return found }
        }
    }
    return nil
}

func findElementByID(root: AXUIElement, identifier: String) -> AXUIElement? {
    var idRef: AnyObject?
    if AXUIElementCopyAttributeValue(root, kAXIdentifierAttribute as CFString, &idRef) == .success,
       let id = idRef as? String, id == identifier {
        return root
    }
    var childrenRef: AnyObject?
    if AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef) == .success,
       let children = childrenRef as? [AXUIElement] {
        for child in children {
            if let found = findElementByID(root: child, identifier: identifier) { return found }
        }
    }
    return nil
}

func getPosition(of element: AXUIElement) -> CGPoint? {
    var ref: AnyObject?
    guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &ref) == .success,
          let val = ref else { return nil }
    var pos = CGPoint.zero
    AXValueGetValue(val as! AXValue, .cgPoint, &pos)
    return pos
}

func getSize(of element: AXUIElement) -> CGSize? {
    var ref: AnyObject?
    guard AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &ref) == .success,
          let val = ref else { return nil }
    var size = CGSize.zero
    AXValueGetValue(val as! AXValue, .cgSize, &size)
    return size
}

func setPosition(_ element: AXUIElement, x: CGFloat, y: CGFloat) {
    var point = CGPoint(x: x, y: y)
    let value = AXValueCreate(.cgPoint, &point)!
    AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
}

func moveNotifications() {
    guard let ncApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == ncBundleID }) else { return }
    let app = AXUIElementCreateApplication(ncApp.processIdentifier)
    var windowsRef: AnyObject?
    guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef) == .success,
          let windows = windowsRef as? [AXUIElement] else { return }

    guard let screen = NSScreen.main else { return }

    for win in windows {
        var subroleRef: AnyObject?
        AXUIElementCopyAttributeValue(win, kAXSubroleAttribute as CFString, &subroleRef)
        guard (subroleRef as? String) == "AXSystemDialog" else { continue }

        guard let listItems = findElementByID(root: win, identifier: "AXNotificationListItems"),
              let listSize = getSize(of: listItems) else { continue }

        // Skip if no visible notifications
        guard listSize.height > 0 else { continue }

        // Cache the list Y offset (only reset window when we don't have it yet)
        if cachedListY == nil {
            setPosition(win, x: 0, y: 0)
            usleep(50_000)
            guard let listPos = getPosition(of: listItems) else { continue }
            cachedListY = listPos.y
        }

        let dockHeight = screen.visibleFrame.origin.y
        let targetY = screen.frame.height - cachedListY! - listSize.height - dockHeight - 80

        // Only move if not already at target (prevents blink during interaction)
        if let winPos = getPosition(of: win), abs(winPos.y - targetY) > 5 {
            setPosition(win, x: 0, y: targetY)
        }
    }
}

func observerCallback(observer: AXObserver, element: AXUIElement, notification: CFString, context: UnsafeMutableRawPointer?) {
    debounceItem?.cancel()
    let item = DispatchWorkItem { moveNotifications() }
    debounceItem = item
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: item)
}

// Setup
let app = NSApplication.shared

guard AXIsProcessTrusted() else {
    print("Error: accessibility permission required")
    exit(1)
}

guard let ncApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == ncBundleID }) else {
    print("Error: Notification Center not running")
    exit(1)
}

// Menu bar icon
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
if let button = statusItem.button {
    if let img = NSImage(systemSymbolName: "bell.and.waves.left.and.right", accessibilityDescription: "NotifMover") {
        img.isTemplate = true
        button.image = img
    } else {
        button.title = "NM"
    }
}
let menu = NSMenu()
menu.addItem(NSMenuItem(title: "NotifMover — bottom-right", action: nil, keyEquivalent: ""))
menu.addItem(NSMenuItem.separator())
menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
statusItem.menu = menu

// AX observer
let pid = ncApp.processIdentifier
let axApp = AXUIElementCreateApplication(pid)
var observer: AXObserver?
AXObserverCreate(pid, observerCallback, &observer)
AXObserverAddNotification(observer!, axApp, kAXLayoutChangedNotification as CFString, nil)
AXObserverAddNotification(observer!, axApp, kAXWindowCreatedNotification as CFString, nil)
CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer!), .defaultMode)

moveNotifications()
app.run()
