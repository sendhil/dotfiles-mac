// cmux-scratch — quake-style toggle for a floating Ghostty scratchpad.
//
// Visibility is driven by AeroSpace workspace membership, not by window
// position. Park = move scratch window to a dedicated `Floating` workspace.
// Summon = move it to the current workspace + recenter. AeroSpace's own
// per-workspace hiding does the visual work, so switching workspaces and
// coming back no longer leaves the window in a random spot.

import Cocoa
import ApplicationServices

// MARK: - Config

let sentinel       = "»scratch«"
let ghosttyApp     = "com.mitchellh.ghostty"
let ghosttyBundle  = "/Applications/Ghostty.app"
let parkingWs      = "Floating"
let aerospaceBin   = "/opt/homebrew/bin/aerospace"
let widthRatio:  CGFloat = 0.60
let heightRatio: CGFloat = 0.75

// MARK: - Shell

struct AerospaceWindow {
    let id: Int
    let workspace: String
}

@discardableResult
func runAerospace(_ args: [String]) -> (status: Int32, stdout: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: aerospaceBin)
    p.arguments = args
    let out = Pipe()
    p.standardOutput = out
    p.standardError = Pipe()
    do { try p.run() } catch { return (-1, "") }
    p.waitUntilExit()
    let data = out.fileHandleForReading.readDataToEndOfFile()
    return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

// MARK: - AeroSpace state

func findScratch() -> AerospaceWindow? {
    let (status, stdout) = runAerospace([
        "list-windows", "--all",
        "--format", "%{window-id}%{app-bundle-id}%{workspace}%{window-title}",
        "--json",
    ])
    guard status == 0,
          let data = stdout.data(using: .utf8),
          let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return nil }

    for entry in arr {
        guard let appId = entry["app-bundle-id"] as? String, appId == ghosttyApp,
              let title = entry["window-title"] as? String, title.contains(sentinel),
              let wid   = entry["window-id"] as? Int,
              let ws    = entry["workspace"] as? String
        else { continue }
        return AerospaceWindow(id: wid, workspace: ws)
    }
    return nil
}

func focusedWorkspace() -> String? {
    let (status, stdout) = runAerospace(["list-workspaces", "--focused"])
    guard status == 0 else { return nil }
    let trimmed = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

// MARK: - AX helpers

func scratchAXWindow() -> AXUIElement? {
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
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: ghosttyApp) {
        app.activate()
    }
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

// MARK: - Actions

func centerAndRaise(_ ax: AXUIElement) {
    if let (pos, size) = centerRect() {
        setSize(ax, size)
        setPosition(ax, pos)
    }
    raiseWindow(ax)
}

func park(windowId: Int) {
    runAerospace(["move-node-to-workspace", "--window-id", "\(windowId)", parkingWs])
}

func summon(windowId: Int, focusedWs: String, ax: AXUIElement?) {
    runAerospace(["move-node-to-workspace", "--window-id", "\(windowId)", focusedWs])
    if let ax = ax { centerAndRaise(ax) }
}

func spawn(focusedWs: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = ["-na", ghosttyBundle, "--args", "--title=\(sentinel)"]
    do { try p.run() } catch {
        FileHandle.standardError.write(
            "failed to launch Ghostty: \(error)\n".data(using: .utf8)!)
        exit(1)
    }
    p.waitUntilExit()

    // Poll for the AX window (up to ~2s).
    var ax: AXUIElement?
    for _ in 0..<40 {
        if let found = scratchAXWindow() { ax = found; break }
        usleep(50_000)
    }
    guard let axWindow = ax else {
        FileHandle.standardError.write(
            "timed out waiting for Ghostty scratch window\n".data(using: .utf8)!)
        exit(1)
    }

    // Poll briefly for AeroSpace to see the new window so we can move it to
    // the focused workspace (on-window-detected may drop it elsewhere).
    for _ in 0..<20 {
        if let info = findScratch() {
            if info.workspace != focusedWs {
                runAerospace(["move-node-to-workspace",
                              "--window-id", "\(info.id)", focusedWs])
            }
            break
        }
        usleep(50_000)
    }

    centerAndRaise(axWindow)
}

// MARK: - Toggle

func toggle() {
    let info = findScratch()
    let ax = scratchAXWindow()

    // MISSING: nothing in AS and/or nothing in AX -> spawn a fresh window.
    guard let info = info, ax != nil else {
        let fws = focusedWorkspace() ?? "1"
        spawn(focusedWs: fws)
        return
    }

    if info.workspace == parkingWs {
        // HIDDEN -> summon (need focused ws to know destination)
        guard let fws = focusedWorkspace() else { exit(1) }
        summon(windowId: info.id, focusedWs: fws, ax: ax)
    } else {
        // VISIBLE (on any non-parking workspace) -> park
        park(windowId: info.id)
    }
}

// MARK: - Entry

let args = CommandLine.arguments
let sub = args.count > 1 ? args[1] : ""
switch sub {
case "toggle": toggle()
case "spawn":  spawn(focusedWs: focusedWorkspace() ?? "1")
default:
    FileHandle.standardError.write("usage: cmux-scratch {toggle|spawn}\n".data(using: .utf8)!)
    exit(2)
}
