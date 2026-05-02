// cmux-scratch — quake-style toggle for a floating Ghostty scratchpad.
//
// Subcommand:
//   toggle  — spawn if missing, else park/summon via AX setPosition
//
// Ghostty is made fully-floating in AeroSpace via an on-window-detected
// rule matching app-id com.mitchellh.ghostty. AS therefore leaves its
// geometry alone once we set it. Park teleports to the bottom-right
// corner (AX clamps to a 1x2px sliver there); summon restores the last
// visible position from a state file.

import Cocoa
import ApplicationServices

// MARK: - Config

let sentinel     = "»scratch«"
let ghosttyApp   = "com.mitchellh.ghostty"
let ghosttyBundle = "/Applications/Ghostty.app"
let widthRatio:  CGFloat = 0.60
let heightRatio: CGFloat = 0.75
let positionStateFile = (ProcessInfo.processInfo.environment["TMPDIR"] ?? "/tmp")
    .appending("cmux-scratch-pos")

// MARK: - AX helpers

func scratchWindow() -> AXUIElement? {
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: ghosttyApp) {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &raw) == .success,
              let windows = raw as? [AXUIElement] else { continue }
        for w in windows {
            var titleRaw: CFTypeRef?
            guard AXUIElementCopyAttributeValue(w, kAXTitleAttribute as CFString, &titleRaw) == .success,
                  let title = titleRaw as? String else { continue }
            if title.contains(sentinel) { return w }
        }
    }
    return nil
}

func getPosition(_ w: AXUIElement) -> CGPoint? {
    var raw: CFTypeRef?
    guard AXUIElementCopyAttributeValue(w, kAXPositionAttribute as CFString, &raw) == .success,
          let v = raw, CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
    var p = CGPoint.zero
    guard AXValueGetValue(v as! AXValue, .cgPoint, &p) else { return nil }
    return p
}

func setPosition(_ w: AXUIElement, _ p: CGPoint) {
    var pt = p
    if let v = AXValueCreate(.cgPoint, &pt) {
        AXUIElementSetAttributeValue(w, kAXPositionAttribute as CFString, v)
    }
}

func setSize(_ w: AXUIElement, _ s: CGSize) {
    var sz = s
    if let v = AXValueCreate(.cgSize, &sz) {
        AXUIElementSetAttributeValue(w, kAXSizeAttribute as CFString, v)
    }
}

func raiseWindow(_ w: AXUIElement) {
    AXUIElementPerformAction(w, kAXRaiseAction as CFString)
}

// MARK: - Geometry

func centerRect() -> (CGPoint, CGSize)? {
    guard let screen = NSScreen.main else { return nil }
    let f = screen.visibleFrame
    let w = f.width  * widthRatio
    let h = f.height * heightRatio
    // visibleFrame is in Cocoa coords (bottom-left origin). Convert to AX.
    let totalHeight = screen.frame.height
    let axY = totalHeight - f.origin.y - f.height + (f.height - h) / 2
    let axX = f.origin.x + (f.width - w) / 2
    return (CGPoint(x: axX, y: axY), CGSize(width: w, height: h))
}

func parkPoint() -> CGPoint {
    guard let screen = NSScreen.main else { return CGPoint(x: 99_999, y: 99_999) }
    let f = screen.frame
    return CGPoint(x: f.width - 1, y: f.height - 1)
}

// MARK: - Spawn

func spawn() {
    // Use `open -na` to launch a fresh Ghostty instance with a known window
    // title. The AeroSpace on-window-detected rule floats all Ghostty
    // windows, so this one will be untiled from the start.
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = ["-na", ghosttyBundle, "--args", "--title=\(sentinel)"]
    do { try p.run() } catch {
        FileHandle.standardError.write(
            "failed to launch Ghostty: \(error)\n".data(using: .utf8)!)
        exit(1)
    }
    p.waitUntilExit()

    // Poll for the AX window to appear
    var ax: AXUIElement?
    for _ in 0..<40 {  // up to 2s
        if let found = scratchWindow() { ax = found; break }
        usleep(50_000)
    }
    guard let axWindow = ax else {
        FileHandle.standardError.write(
            "timed out waiting for Ghostty scratch window\n".data(using: .utf8)!)
        exit(1)
    }

    // Center and raise
    if let (pos, size) = centerRect() {
        setSize(axWindow, size)
        setPosition(axWindow, pos)
    }
    raiseWindow(axWindow)
    try? FileManager.default.removeItem(atPath: positionStateFile)
}

// MARK: - Toggle
//
// Decide based on actual position vs park corner, not just state file.
// After AeroSpace reshuffles (workspace switches, restart, etc.) the window
// may end up at a new position. Treat anything near the park corner as
// "parked"; anything else as "visible → re-park on this press".

func toggle() {
    guard let ax = scratchWindow() else {
        spawn()
        return
    }

    let park = parkPoint()
    let currentPos = getPosition(ax) ?? park
    // macOS AX clamps our park target (screen-bottom-right) by the window
    // height/width, so the actual on-screen position can be ~30-40px off
    // from our target. Use a generous threshold.
    let isAtParkCorner = abs(currentPos.x - park.x) < 100
        && abs(currentPos.y - park.y) < 100

    if isAtParkCorner && FileManager.default.fileExists(atPath: positionStateFile) {
        // Parked → summon: restore saved position
        if let data = try? String(contentsOfFile: positionStateFile, encoding: .utf8) {
            let parts = data.trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: " ")
            if parts.count == 2,
               let x = Double(parts[0]), let y = Double(parts[1]) {
                setPosition(ax, CGPoint(x: x, y: y))
            } else if let (pos, _) = centerRect() {
                setPosition(ax, pos)
            }
        }
        raiseWindow(ax)
        try? FileManager.default.removeItem(atPath: positionStateFile)
    } else {
        // Visible → park: save current position, teleport to park corner
        let line = "\(Int(currentPos.x)) \(Int(currentPos.y))\n"
        try? line.write(toFile: positionStateFile, atomically: true, encoding: .utf8)
        setPosition(ax, park)
    }
}

// MARK: - Entry

let args = CommandLine.arguments
let sub = args.count > 1 ? args[1] : ""
switch sub {
case "toggle": toggle()
case "spawn":  spawn()
default:
    FileHandle.standardError.write("usage: cmux-scratch {toggle|spawn}\n".data(using: .utf8)!)
    exit(2)
}
