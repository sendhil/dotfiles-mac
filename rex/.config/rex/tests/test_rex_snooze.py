from __future__ import annotations

import base64
import os
import signal
import threading
import time
from datetime import datetime
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve().parents[3] / ".local" / "bin" / "rex-snooze"


def load_module():
    loader = SourceFileLoader("rex_snooze", str(SCRIPT_PATH))
    spec = spec_from_loader("rex_snooze", loader)
    assert spec and spec.loader
    mod = module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def decode_osc(seq: str) -> dict[str, str]:
    assert seq.startswith("\x1b]7501;") and seq.endswith("\x1b\\")
    body = seq[len("\x1b]7501;") : -len("\x1b\\")]
    pairs = {}
    for item in body.split(":"):
        k, v = item.split("=", 1)
        if k in ("msg", "title"):
            v = base64.b64decode(v).decode("utf-8")
        pairs[k] = v
    return pairs


def test_parse_spec_presets_and_custom_queries():
    mod = load_module()
    now = datetime(2026, 11, 11, 11, 30, 0)

    secs, label, note = mod.parse_spec("", "preset:30m", now=now)
    assert (secs, label, note) == (1800, "30m", "")

    secs, label, note = mod.parse_spec("check CI status", "preset:1h", now=now)
    assert (secs, label, note) == (3600, "1h", "check CI status")

    secs, label, note = mod.parse_spec("45m verify deploy", "preset:15m", now=now)
    assert (secs, label, note) == (2700, "45m", "verify deploy")

    secs, label, note = mod.parse_spec("1h30m", "preset:15m", now=now)
    assert (secs, label, note) == (5400, "1h30m", "")

    secs, label, note = mod.parse_spec("20 ping bob", "preset:15m", now=now)
    assert (secs, label, note) == (1200, "20m", "ping bob")

    secs, label, note = mod.parse_spec("morning standup", "preset:tomorrow", now=now)
    assert secs == int((datetime(2026, 11, 12, 9, 0, 0) - now).total_seconds())
    assert label == "tomorrow 9am"
    assert note == "morning standup"

    secs, label, note = mod.parse_spec("14:30", "preset:15m", now=now)
    assert (secs, label, note) == (3 * 3600, "14:30", "")
    secs, label, _ = mod.parse_spec("999999999d", "preset:15m", now=now)
    assert secs == 30 * 86400


def test_osc7501_silence_and_wakeup_sequences():
    mod = load_module()
    records = [
        {"state": "done", "app": "pi"},
        {"id": "pi.ask", "state": "blocked", "kind": "question", "app": "pi"},
    ]
    seqs = mod.build_silence_sequences(records, until_label="12:00", note="check PR")
    parsed = [decode_osc(s) for s in seqs]

    assert {"state": "idle", "app": "pi"} in parsed
    assert {"state": "clear", "id": "pi.ask"} in parsed
    snooze_rec = next(p for p in parsed if p.get("id") == "rex.snooze")
    assert snooze_rec["state"] == "idle"
    assert snooze_rec["app"] == "snooze"
    assert "12:00" in snooze_rec["msg"]
    assert "check PR" in snooze_rec["msg"]

    wake_seq = mod.build_wakeup_sequence(
        {"duration_str": "30m", "note": "check PR", "window_label": "expenses"}
    )
    wake = decode_osc(wake_seq)
    assert wake["state"] == "blocked"
    assert wake["kind"] == "question"
    assert wake["id"] == "rex.snooze"
    assert wake["app"] == "snooze"
    assert "check PR" in wake["msg"]


def test_daemon_tick_lifecycle_and_autoclear():
    mod = load_module()
    writes: list[tuple[str, str]] = []

    def writer(tty: str | None, data: str) -> bool:
        writes.append((tty or "", data))
        return True

    entries = {
        "block:1": {
            "block_id": "block:1",
            "session_id": "session:1",
            "window_id": "window:1",
            "session_label": "work",
            "window_label": "expenses",
            "program": "pi",
            "tty": "/dev/ttys099",
            "created_at": 1000.0,
            "due_at": 1060.0,
            "duration_str": "1m",
            "note": "review numbers",
            "state": "snoozed",
        }
    }

    views_focused = {
        "session:1": {
            "active_window_id": "window:1",
            "windows": [{"window_id": "window:1", "focused_block_id": "block:1", "layers": [{"blocks": [{"block_id": "block:1"}]}]}],
        }
    }
    mod.process_entries(
        entries,
        views=views_focused,
        tty_atimes={"/dev/ttys099": 500_000_000_000},
        now=1030.0,
        write_tty=writer,
    )
    assert entries["block:1"]["state"] == "snoozed"
    assert writes == []

    # At due_at while block IS currently focused: transitions to ringing and does NOT auto-clear yet
    mod.process_entries(
        entries,
        views=views_focused,
        tty_atimes={"/dev/ttys099": 500_000_000_000},
        now=1060.0,
        write_tty=writer,
    )
    assert entries["block:1"]["state"] == "ringing"
    assert entries["block:1"]["seen_unfocused"] is False
    assert len(writes) == 1
    assert decode_osc(writes[0][1])["state"] == "blocked"

    # Next tick while still focused and no new keystroke: stays ringing
    writes.clear()
    mod.process_entries(
        entries,
        views=views_focused,
        tty_atimes={"/dev/ttys099": 500_000_000_000},
        now=1061.0,
        write_tty=writer,
    )
    assert "block:1" in entries
    assert writes == []

    # User switches to another tab (unfocused), then switches back (focused): auto-clears
    views_other_tab = {
        "session:1": {
            "active_window_id": "window:2",
            "windows": [
                {"window_id": "window:1", "focused_block_id": "block:1", "layers": [{"blocks": [{"block_id": "block:1"}]}]},
                {"window_id": "window:2", "focused_block_id": "block:2", "layers": [{"blocks": [{"block_id": "block:2"}]}]},
            ],
        }
    }
    mod.process_entries(
        entries,
        views=views_other_tab,
        tty_atimes={"/dev/ttys099": 500_000_000_000},
        now=1062.0,
        write_tty=writer,
    )
    assert entries["block:1"]["seen_unfocused"] is True

    mod.process_entries(
        entries,
        views=views_focused,
        tty_atimes={"/dev/ttys099": 500_000_000_000},
        now=1063.0,
        write_tty=writer,
    )
    assert "block:1" not in entries
    assert len(writes) == 1
    assert decode_osc(writes[0][1]) == {"state": "clear", "id": "rex.snooze"}


def test_daemon_tick_autoclear_on_subsecond_keystroke_when_already_focused():
    mod = load_module()
    writes: list[tuple[str, str]] = []

    def writer(tty: str | None, data: str) -> bool:
        writes.append((tty or "", data))
        return True

    entries = {
        "block:1": {
            "block_id": "block:1",
            "session_id": "session:1",
            "window_id": "window:1",
            "tty": "/dev/ttys099",
            "created_at": 1000.0,
            "due_at": 1060.0,
            "duration_str": "1m",
            "note": "",
            "state": "ringing",
            "seen_unfocused": False,
            # Subsecond nanosecond timestamp (e.g. 500.1s vs 500.9s)
            "tty_atime_at_expiry": 500_100_000_000,
        }
    }
    views_focused = {
        "session:1": {
            "active_window_id": "window:1",
            "windows": [{"window_id": "window:1", "focused_block_id": "block:1", "layers": [{"blocks": [{"block_id": "block:1"}]}]}],
        }
    }
    mod.process_entries(
        entries,
        views=views_focused,
        tty_atimes={"/dev/ttys099": 500_900_000_000},
        now=1060.5,
        write_tty=writer,
    )
    assert "block:1" not in entries
    assert len(writes) == 1
    assert decode_osc(writes[0][1]) == {"state": "clear", "id": "rex.snooze"}


def test_unknown_views_and_failed_writes_preserve_entries():
    mod = load_module()
    entries = {
        "block:due": {
            "block_id": "block:due",
            "session_id": "session:1",
            "window_id": "window:1",
            "tty": "/dev/ttys099",
            "created_at": 1000.0,
            "due_at": 1050.0,
            "duration_str": "1m",
            "note": "",
            "state": "snoozed",
        },
        "block:new": {
            "block_id": "block:new",
            "session_id": "session:uninspected",
            "window_id": "window:9",
            "tty": "/dev/ttys098",
            "created_at": 1055.0,
            "due_at": 5000.0,
            "duration_str": "1h",
            "note": "",
            "state": "snoozed",
        },
    }

    # 1. Transient RPC failure (view is None) or uninspected session must NOT delete entries
    mod.process_entries(
        entries,
        views={"session:1": None},
        tty_atimes={},
        now=1060.0,
        write_tty=lambda _t, _d: True,
        inspected_at=1052.0,
    )
    assert "block:due" in entries
    assert "block:new" in entries

    # 2. Failed TTY write at expiry must NOT transition state to ringing
    views_ok = {
        "session:1": {
            "active_window_id": "window:2",
            "windows": [{"window_id": "window:1", "focused_block_id": "block:due", "layers": [{"blocks": [{"block_id": "block:due"}]}]}],
        }
    }
    mod.process_entries(
        entries,
        views=views_ok,
        tty_atimes={"/dev/ttys099": 100},
        now=1060.0,
        write_tty=lambda _t, _d: False,
        inspected_at=1060.0,
    )
    assert entries["block:due"]["state"] == "snoozed"

    # 3. Newly added entry (created_at > inspected_at) in an inspected session is not pruned by older view
    entries["block:race"] = {
        "block_id": "block:race",
        "session_id": "session:1",
        "window_id": "window:1",
        "tty": "/dev/ttys097",
        "created_at": 1070.0,
        "due_at": 2000.0,
        "state": "snoozed",
    }
    mod.process_entries(
        entries,
        views=views_ok,
        tty_atimes={"/dev/ttys099": 100},
        now=1060.0,
        write_tty=lambda _t, _d: True,
        inspected_at=1060.0,
    )
    assert "block:race" in entries
    assert entries["block:due"]["state"] == "ringing"


def test_ack_ringing_only_and_preset_guard(tmp_path, monkeypatch):
    mod = load_module()
    monkeypatch.setattr(mod, "STATE_DIR", tmp_path)
    monkeypatch.setattr(mod, "SNOOZES_FILE", tmp_path / "snoozes.json")
    monkeypatch.setattr(mod, "LOCK_FILE", tmp_path / "lock")
    monkeypatch.setattr(mod, "DAEMON_LOCK_FILE", tmp_path / "daemon.lock")
    monkeypatch.setattr(mod, "DAEMON_PID_FILE", tmp_path / "daemon.pid")
    monkeypatch.setattr(mod, "write_tty_direct", lambda _tty, _data: True)
    notified: list[bool] = []
    monkeypatch.setattr(mod, "_notify_or_start_daemon", lambda *, has_entries: notified.append(has_entries))

    with mod._locked_state() as entries:
        entries["block:resnoozed"] = {
            "block_id": "block:resnoozed",
            "session_id": "session:1",
            "tty": "/dev/ttys001",
            "state": "snoozed",
            "due_at": 9999.0,
        }
        entries["block:ringing"] = {
            "block_id": "block:ringing",
            "session_id": "session:1",
            "tty": "/dev/ttys002",
            "state": "ringing",
            "due_at": 100.0,
        }

    # --ringing-only must leave 'snoozed' entry untouched while clearing 'ringing'
    assert mod.ack_blocks(["block:resnoozed"], ringing_only=True) == 0
    assert "block:resnoozed" in mod.load_entries()
    assert mod.ack_blocks(["block:ringing"], ringing_only=True) == 1
    assert "block:ringing" not in mod.load_entries()

    # Empty targets without --all must be a no-op (never wipe everything)
    assert mod.ack_blocks([]) == 0
    assert "block:resnoozed" in mod.load_entries()

    # Pressing u/x on a preset row ('preset:15m') with fallback block_id clears fallback block_id
    assert mod.ack_blocks(["preset:15m"], fallback_block_id="block:resnoozed") == 1
    assert "block:resnoozed" not in mod.load_entries()
    assert notified[-1] is False


def test_cross_session_apply_uses_entry_session(tmp_path, monkeypatch):
    mod = load_module()
    monkeypatch.setattr(mod, "STATE_DIR", tmp_path)
    monkeypatch.setattr(mod, "SNOOZES_FILE", tmp_path / "snoozes.json")
    monkeypatch.setattr(mod, "LOCK_FILE", tmp_path / "lock")
    with mod._locked_state() as entries:
        entries["block:other"] = {
            "block_id": "block:other",
            "session_id": "session:B",
            "window_id": "window:B",
            "state": "snoozed",
            "due_at": 2000.0,
        }

    captured = {}

    def fake_snooze(sid, bid, secs, label, note=""):
        captured["vals"] = (sid, bid, secs, label, note)
        return {"due_at": 3000.0, "window_label": "tab"}

    monkeypatch.setattr(mod, "snooze_block", fake_snooze)
    mod.cmd_apply(["-s", "session:A", "-b", "block:current", "pane:block:other", "10m check B"])
    assert captured["vals"] == ("session:B", "block:other", 600, "10m", "check B")


def test_sigusr1_interrupts_daemon_wait():
    mod = load_module()
    rfd, wfd = os.pipe()
    os.set_blocking(rfd, False)
    os.set_blocking(wfd, False)
    prev_handler = signal.getsignal(signal.SIGUSR1)
    prev_wakeup = signal.set_wakeup_fd(wfd, warn_on_full_buffer=False)
    signal.signal(signal.SIGUSR1, lambda _s, _f: None)
    try:
        t0 = time.monotonic()
        threading.Timer(0.05, lambda: os.kill(os.getpid(), signal.SIGUSR1)).start()
        mod.wait_interruptible(rfd, 10.0)
        elapsed = time.monotonic() - t0
        assert elapsed < 1.0
    finally:
        signal.set_wakeup_fd(prev_wakeup)
        signal.signal(signal.SIGUSR1, prev_handler)
        os.close(rfd)
        os.close(wfd)


def test_next_sleep_seconds_cap_and_overdue_floor():
    mod = load_module()
    assert mod.next_sleep_seconds({}, now=1000.0) == 0.0
    # Counting down for 30m: capped at 60s so laptop lid-close sleep never delays wakeup >60s
    assert mod.next_sleep_seconds({"block:1": {"state": "snoozed", "due_at": 2800.0}}, now=1000.0) == 60.0
    # Short countdown (<60s): sleeps exact remaining duration
    assert mod.next_sleep_seconds({"block:1": {"state": "snoozed", "due_at": 1015.0}}, now=1000.0) == 15.0
    # Overdue snoozed entry (e.g. transient RPC failure) floors at 1.0s, never 0.1s busy-spin
    assert mod.next_sleep_seconds({"block:1": {"state": "snoozed", "due_at": 950.0}}, now=1000.0) == 1.0
    # Once ringing: checks focus/atime at 1s interval
    assert mod.next_sleep_seconds({"block:1": {"state": "ringing", "due_at": 1000.0}}, now=1005.0) == 1.0


def test_dead_session_pruning_and_go_block_id(tmp_path, monkeypatch):
    mod = load_module()
    monkeypatch.setattr(mod, "STATE_DIR", tmp_path)
    monkeypatch.setattr(mod, "SNOOZES_FILE", tmp_path / "snoozes.json")
    monkeypatch.setattr(mod, "LOCK_FILE", tmp_path / "lock")
    monkeypatch.setattr(mod, "_notify_or_start_daemon", lambda **_: None)

    monkeypatch.setattr(mod, "inspect_session", lambda _sid: None)
    monkeypatch.setattr(mod, "live_session_ids", lambda: {"session:alive"})
    views = mod.resolve_active_views({"session:killed"})
    assert views == {"session:killed": {"windows": []}}

    focused: list[tuple[str, str]] = []
    monkeypatch.setattr(
        mod,
        "find_block_context",
        lambda _sid, bid: {"session_id": "session:alive", "window_id": "window:1", "block_id": bid}
        if bid == "block:xyz"
        else None,
    )
    monkeypatch.setattr(mod, "rex", lambda *args, **_kw: focused.append((args[0], args[-1])))
    mod.cmd_go(["block:xyz"])
    assert ("focus", "block:xyz") in focused
