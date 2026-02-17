import ApplicationServices
import Cocoa

let ncBundleID = "com.apple.notificationcenterui"

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

    let alertSubroles = ["AXNotificationCenterAlertStack", "AXNotificationCenterBannerStack",
                          "AXNotificationCenterBanner", "AXNotificationCenterAlert"]

    for win in windows {
        var subroleRef: AnyObject?
        AXUIElementCopyAttributeValue(win, kAXSubroleAttribute as CFString, &subroleRef)
        guard (subroleRef as? String) == "AXSystemDialog" else { continue }

        guard let notif = findElement(root: win, targetSubroles: alertSubroles),
              let notifPos = getPosition(of: notif),
              let notifSize = getSize(of: notif) else { continue }

        let targetY = screen.frame.height - notifPos.y - notifSize.height - 50
        if let winPos = getPosition(of: win), abs(winPos.y - targetY) > 5 {
            setPosition(win, x: 0, y: targetY)
        }
    }
}

func observerCallback(observer: AXObserver, element: AXUIElement, notification: CFString, context: UnsafeMutableRawPointer?) {
    moveNotifications()
}

// Setup
guard AXIsProcessTrusted() else {
    print("Error: accessibility permission required")
    exit(1)
}

guard let ncApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == ncBundleID }) else {
    print("Error: Notification Center not running")
    exit(1)
}

let pid = ncApp.processIdentifier
let app = AXUIElementCreateApplication(pid)
var observer: AXObserver?
AXObserverCreate(pid, observerCallback, &observer)
AXObserverAddNotification(observer!, app, kAXLayoutChangedNotification as CFString, nil)
AXObserverAddNotification(observer!, app, kAXWindowCreatedNotification as CFString, nil)
CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer!), .defaultMode)

print("notif-mover: running (notifications → bottom-right)")
moveNotifications()
CFRunLoopRun()
