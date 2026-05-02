// cmux-scratch — quake-style toggle for a floating cmux scratchpad window.
//
// Subcommands:
//   toggle  auto-detects: spawn if missing, summon if on another workspace,
//           park if on the current workspace.
//   spawn   always create a fresh scratch window.
//
// Visibility model: workspace-based. The scratch window lives either on the
// user's current AeroSpace workspace (VISIBLE) or on a dedicated parking
// workspace `Floating` (HIDDEN). AeroSpace's hide-on-non-focused-workspace
// behavior does the visual hiding. No state files, no position-based state.

import Cocoa
import ApplicationServices

// MARK: - Config

let sentinel     = "»scratch«"
let cmuxApp      = "com.cmuxterm.app"
let parkingWs    = "Floating"
let widthRatio:  CGFloat = 0.60
let heightRatio: CGFloat = 0.75
let cmuxBin = ProcessInfo.processInfo.environment["CMUX_BUNDLED_CLI_PATH"]
    ?? "/Applications/cmux.app/Contents/Resources/bin/cmux"
let aerospaceBin = "/opt/homebrew/bin/aerospace"
let spawnLockFile = (ProcessInfo.processInfo.environment["TMPDIR"] ?? "/tmp")
    .appending("cmux-scratch-spawning.lock")

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

func setMinimized(_ w: AXUIElement, _ v: Bool) {
    AXUIElementSetAttributeValue(w, kAXMinimizedAttribute as CFString, v as CFTypeRef)
}

func raiseWindow(_ w: AXUIElement) {
    AXUIElementPerformAction(w, kAXRaiseAction as CFString)
}

// MARK: - Shell out

@discardableResult
func shell(_ args: [String]) -> (status: Int32, stdout: String, stderr: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: args[0])
    p.arguments = Array(args.dropFirst())
    // cmux CLI needs CMUX_SOCKET. AeroSpace's exec env doesn't include it,
    // so inject the canonical path when it's missing.
    var env = ProcessInfo.processInfo.environment
    if env["CMUX_SOCKET"] == nil {
        let home = env["HOME"] ?? NSHomeDirectory()
        env["CMUX_SOCKET"] = "\(home)/Library/Application Support/cmux/cmux.sock"
    }
    p.environment = env
    let out = Pipe()
    let err = Pipe()
    p.standardOutput = out
    p.standardError = err
    do { try p.run() } catch { return (-1, "", "") }
    p.waitUntilExit()
    let oData = out.fileHandleForReading.readDataToEndOfFile()
    let eData = err.fileHandleForReading.readDataToEndOfFile()
    return (p.terminationStatus,
            (String(data: oData, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            (String(data: eData, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
}

// MARK: - AeroSpace queries

// Single query that returns (scratchWid, scratchWorkspace)? for the scratch window.
func queryScratch() -> (wid: Int, workspace: String)? {
    let r = shell([aerospaceBin, "list-windows", "--all",
                   "--format", "%{window-id} %{app-bundle-id} %{workspace} %{window-title}",
                   "--json"])
    guard let data = r.stdout.data(using: .utf8),
          let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        return nil
    }
    for entry in arr {
        guard (entry["app-bundle-id"] as? String) == cmuxApp else { continue }
        let title = (entry["window-title"] as? String) ?? ""
        guard title.contains(sentinel) else { continue }
        guard let wid = entry["window-id"] as? Int,
              let ws = entry["workspace"] as? String else { continue }
        return (wid, ws)
    }
    return nil
}

func focusedWorkspace() -> String {
    return shell([aerospaceBin, "list-workspaces", "--focused"]).stdout
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

func park(wid: Int) {
    _ = shell([aerospaceBin, "move-node-to-workspace",
               "--window-id", String(wid), parkingWs])
}

func summon(wid: Int, axWindow: AXUIElement, focusedWs: String) {
    _ = shell([aerospaceBin, "move-node-to-workspace",
               "--window-id", String(wid), focusedWs])
    // Ensure not minimized from an earlier session
    setMinimized(axWindow, false)
    if let (pos, size) = centerRect() {
        setSize(axWindow, size)
        setPosition(axWindow, pos)
    }
    raiseWindow(axWindow)
}

// Returns true if the PID in the lockfile is currently alive.
func isLockfileOwnerAlive() -> Bool {
    guard let contents = try? String(contentsOfFile: spawnLockFile, encoding: .utf8),
          let pid = pid_t(contents.trimmingCharacters(in: .whitespacesAndNewlines)) else {
        return false
    }
    return kill(pid, 0) == 0
}

func acquireSpawnLock() -> Bool {
    // Clean up stale lockfile (process died during spawn)
    if FileManager.default.fileExists(atPath: spawnLockFile), !isLockfileOwnerAlive() {
        try? FileManager.default.removeItem(atPath: spawnLockFile)
    }
    // Exclusive create
    let fd = open(spawnLockFile, O_CREAT | O_EXCL | O_WRONLY, 0o644)
    if fd < 0 { return false }
    let pid = "\(getpid())"
    _ = pid.withCString { write(fd, $0, strlen($0)) }
    close(fd)
    return true
}

func releaseSpawnLock() {
    try? FileManager.default.removeItem(atPath: spawnLockFile)
}

func spawn(focusedWs: String) {
    guard acquireSpawnLock() else {
        // Another spawn in progress; bail silently.
        return
    }
    defer { releaseSpawnLock() }

    // 1. Create new cmux window
    let r = shell([cmuxBin, "new-window"])
    let newWin = r.stdout
    guard newWin.hasPrefix("OK ") else {
        FileHandle.standardError.write(
            "cmux new-window failed: \(newWin) \(r.stderr)\n".data(using: .utf8)!)
        exit(1)
    }
    let winUuid = String(newWin.dropFirst(3))

    // 2. Find the new window's default workspace and rename it to SENTINEL
    let lsOut = shell([cmuxBin, "list-workspaces", "--window", winUuid,
                       "--id-format", "uuids"]).stdout
    guard let wsUuid = lsOut.split(separator: "\n").first
            .flatMap({ $0.split(separator: " ").dropFirst().first })
            .map(String.init) else {
        FileHandle.standardError.write(
            "failed to find workspace uuid in: \(lsOut)\n".data(using: .utf8)!)
        exit(1)
    }
    _ = shell([cmuxBin, "rename-workspace", "--workspace", wsUuid, sentinel])

    // 3. Poll for AX window to appear
    var ax: AXUIElement?
    for _ in 0..<20 {
        if let found = scratchWindow() { ax = found; break }
        usleep(50_000)
    }
    guard let axWindow = ax else {
        FileHandle.standardError.write(
            "timed out waiting for scratch AX window\n".data(using: .utf8)!)
        exit(1)
    }

    // 4. Find the AeroSpace window-id. Retry — AS may register the window
    //    a frame or two after AX does.
    var info: (wid: Int, workspace: String)? = nil
    for _ in 0..<10 {
        if let found = queryScratch() { info = found; break }
        usleep(50_000)
    }

    // 5. Explicitly mark floating (belt-and-suspenders; on-window-detected rule
    //    may race) and move to current workspace.
    if let info = info {
        _ = shell([aerospaceBin, "layout", "floating", "--window-id", String(info.wid)])
        _ = shell([aerospaceBin, "move-node-to-workspace",
                   "--window-id", String(info.wid), focusedWs])
    }

    // 6. Center and raise
    if let (pos, size) = centerRect() {
        setSize(axWindow, size)
        setPosition(axWindow, pos)
    }
    raiseWindow(axWindow)
}

// MARK: - Toggle
//
// Fast single-workspace toggle. No AeroSpace workspace moves. Park teleports
// the window to the bottom-right corner (AX clamps to {screenW-1, screenH-1},
// leaving a 1x2px sliver that's effectively invisible). Summon restores
// position from a state file. State file presence == parked.
//
// Constraint: the scratch window lives on whatever AeroSpace workspace it
// was spawned on. If you want it on a different workspace, close it and
// respawn there.

func parkPoint() -> CGPoint {
    guard let screen = NSScreen.main else { return CGPoint(x: 99_999, y: 99_999) }
    let f = screen.frame
    return CGPoint(x: f.width - 1, y: f.height - 1)
}

func getPosition(_ w: AXUIElement) -> CGPoint? {
    var raw: CFTypeRef?
    guard AXUIElementCopyAttributeValue(w, kAXPositionAttribute as CFString, &raw) == .success,
          let v = raw, CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
    var p = CGPoint.zero
    guard AXValueGetValue(v as! AXValue, .cgPoint, &p) else { return nil }
    return p
}

let positionStateFile = (ProcessInfo.processInfo.environment["TMPDIR"] ?? "/tmp")
    .appending("cmux-scratch-pos")

func toggle() {
    guard let ax = scratchWindow() else {
        // MISSING → spawn on current workspace
        let focusedWs = focusedWorkspace()
        spawn(focusedWs: focusedWs)
        return
    }

    if FileManager.default.fileExists(atPath: positionStateFile) {
        // Parked → summon: restore saved position
        if let data = try? String(contentsOfFile: positionStateFile, encoding: .utf8) {
            let parts = data.trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: " ")
            if parts.count == 2,
               let x = Double(parts[0]), let y = Double(parts[1]) {
                setPosition(ax, CGPoint(x: x, y: y))
            }
        }
        raiseWindow(ax)
        try? FileManager.default.removeItem(atPath: positionStateFile)
    } else {
        // Visible → park: save current position, teleport off-screen
        if let p = getPosition(ax) {
            let line = "\(Int(p.x)) \(Int(p.y))\n"
            try? line.write(toFile: positionStateFile, atomically: true, encoding: .utf8)
        }
        setPosition(ax, parkPoint())
    }
}

// MARK: - Entry

let args = CommandLine.arguments
let sub = args.count > 1 ? args[1] : ""
switch sub {
case "toggle": toggle()
case "spawn":
    let focusedWs = focusedWorkspace()
    spawn(focusedWs: focusedWs)
default:
    FileHandle.standardError.write("usage: cmux-scratch {toggle|spawn}\n".data(using: .utf8)!)
    exit(2)
}
