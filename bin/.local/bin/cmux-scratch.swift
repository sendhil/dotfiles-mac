// cmux-scratch — quake-style toggle for a floating cmux scratchpad window.
//
// Subcommands:
//   toggle  auto-detects: spawn if missing, else park/summon
//   spawn   create a new scratch cmux window and center it
//
// Parking teleports the window off-screen within its current AeroSpace
// workspace; no workspace churn. Requires AeroSpace to have marked the
// window `layout floating` (done once on spawn).

import Cocoa
import ApplicationServices

// MARK: - Config

let sentinel = "»scratch«"
let cmuxApp  = "com.cmuxterm.app"
let stateFile = (ProcessInfo.processInfo.environment["TMPDIR"] ?? "/tmp")
    .appending("cmux-scratch-pos")
let offscreenX: CGFloat = -10_000  // macOS AX clamps to -(width-1); that's fine
let widthRatio:  CGFloat = 0.60
let heightRatio: CGFloat = 0.75
let cmuxBin = ProcessInfo.processInfo.environment["CMUX_BUNDLED_CLI_PATH"]
    ?? "/Applications/cmux.app/Contents/Resources/bin/cmux"

// MARK: - AX helpers

func scratchWindow() -> AXUIElement? {
    for app in NSRunningApplication.runningApplications(withBundleIdentifier: cmuxApp) {
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

// MARK: - Shell out

@discardableResult
func shell(_ args: [String]) -> (status: Int32, stdout: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: args[0])
    p.arguments = Array(args.dropFirst())
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = Pipe()
    do { try p.run() } catch { return (-1, "") }
    p.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let out = String(data: data, encoding: .utf8) ?? ""
    return (p.terminationStatus, out.trimmingCharacters(in: .whitespacesAndNewlines))
}

// MARK: - Actions

func centerRect() -> (CGPoint, CGSize)? {
    guard let screen = NSScreen.main else { return nil }
    let f = screen.visibleFrame
    let w = f.width  * widthRatio
    let h = f.height * heightRatio
    // NSScreen uses Cocoa (bottom-left origin) but AX uses top-left origin.
    // visibleFrame is in Cocoa coords. Convert y to AX (top-left) coords.
    let totalHeight = screen.frame.height
    let axY = totalHeight - f.origin.y - f.height + (f.height - h) / 2
    let axX = f.origin.x + (f.width - w) / 2
    return (CGPoint(x: axX, y: axY), CGSize(width: w, height: h))
}

func spawn() {
    // Remove any stale state
    try? FileManager.default.removeItem(atPath: stateFile)

    // 1. Create new window
    let newWin = shell([cmuxBin, "new-window"]).stdout
    guard newWin.hasPrefix("OK ") else {
        FileHandle.standardError.write("cmux new-window failed: \(newWin)\n".data(using: .utf8)!)
        exit(1)
    }
    let winUuid = String(newWin.dropFirst(3))

    // 2. Find its default workspace and rename to the sentinel
    let lsOut = shell([cmuxBin, "list-workspaces", "--window", winUuid, "--id-format", "uuids"]).stdout
    guard let wsUuid = lsOut.split(separator: "\n").first
        .flatMap({ $0.split(separator: " ").dropFirst().first })
        .map(String.init) else {
        FileHandle.standardError.write("failed to find workspace uuid in: \(lsOut)\n".data(using: .utf8)!)
        exit(1)
    }
    _ = shell([cmuxBin, "rename-workspace", "--workspace", wsUuid, sentinel])

    // 3. Poll for AX window, mark it floating in AeroSpace, center it
    var w: AXUIElement?
    for _ in 0..<20 {
        if let found = scratchWindow() { w = found; break }
        usleep(50_000)  // 50ms
    }
    guard let ax = w else {
        FileHandle.standardError.write("timed out waiting for scratch AX window\n".data(using: .utf8)!)
        exit(1)
    }

    // Find aerospace window id to mark it floating
    let asJson = shell(["/opt/homebrew/bin/aerospace", "list-windows", "--all",
                         "--format", "%{window-id} %{app-bundle-id} %{window-title}", "--json"]).stdout
    if let data = asJson.data(using: .utf8),
       let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
       let entry = arr.first(where: { ($0["app-bundle-id"] as? String) == cmuxApp
                                     && (($0["window-title"] as? String) ?? "").contains(sentinel) }),
       let wid = entry["window-id"] as? Int {
        _ = shell(["/opt/homebrew/bin/aerospace", "layout", "floating", "--window-id", String(wid)])
    }

    if let (pos, size) = centerRect() {
        setSize(ax, size)
        setPosition(ax, pos)
    }
    raiseWindow(ax)
}

func toggle() {
    guard let w = scratchWindow() else {
        spawn()
        return
    }
    if FileManager.default.fileExists(atPath: stateFile) {
        // Parked → summon
        guard let data = try? String(contentsOfFile: stateFile, encoding: .utf8) else {
            try? FileManager.default.removeItem(atPath: stateFile)
            return
        }
        let parts = data.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
        guard parts.count == 2,
              let x = Double(parts[0]), let y = Double(parts[1]) else {
            try? FileManager.default.removeItem(atPath: stateFile)
            return
        }
        setPosition(w, CGPoint(x: x, y: y))
        raiseWindow(w)
        try? FileManager.default.removeItem(atPath: stateFile)
    } else {
        // Visible → park
        guard let p = getPosition(w) else { return }
        let line = "\(Int(p.x)) \(Int(p.y))\n"
        try? line.write(toFile: stateFile, atomically: true, encoding: .utf8)
        setPosition(w, CGPoint(x: offscreenX, y: p.y))
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
