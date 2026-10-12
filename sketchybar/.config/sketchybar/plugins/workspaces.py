#!/usr/bin/env python3
"""AeroSpace workspace pills: event driven, with a slow recovery refresh."""
import collections
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
STATE = Path.home() / 'Library/Caches/dotfiles-sketchybar'
SBAR = shutil.which('sketchybar') or 'sketchybar'
AERO = shutil.which('aerospace') or 'aerospace'
COLORS = ['cba6f7', '89b4fa', 'a6e3a1', 'f9e2af', 'f5c2e7', '94e2d5', 'fab387']


def sort_key(name):
    return (0, int(name)) if name.isdigit() else (1, name.casefold())


def project(workspaces, windows, monitors, visible, focused, limit=7):
    """Return all workspaces, with per-display visibility and stable ordering."""
    displays = {m['monitor-id']: m['monitor-appkit-nsscreen-screens-id'] for m in monitors}
    visible_ids = {w['workspace'] for w in visible}
    grouped = collections.defaultdict(list)
    for window in windows:
        grouped[window['workspace']].append(window['app-name'])
    result = []
    for ws in sorted(workspaces, key=lambda w: sort_key(w['workspace'])):
        if ws['monitor-id'] not in displays:
            continue
        sid = ws['workspace']
        apps = sorted(set(grouped[sid]), key=str.casefold)
        result.append(dict(workspace=sid, display=displays[ws['monitor-id']], apps=apps,
                           window_count=len(grouped[sid]), focused=sid == focused,
                           visible=sid in visible_ids,
                           drawing=bool(apps) or sid in visible_ids or sid == focused))
    for display in set(displays.values()):
        candidates = [r for r in result if r['display'] == display and r['drawing']]
        if len(candidates) > limit:
            mandatory = [r for r in candidates if r['focused'] or r['visible']]
            keep = mandatory + [r for r in candidates if r not in mandatory][:max(0, limit - len(mandatory))]
            for row in candidates:
                row['drawing'] = row in keep
    return result


def query(*args):
    return json.loads(subprocess.check_output([AERO, *args, '--json'], text=True, timeout=3))


def snapshot():
    monitors = query('list-monitors', '--format', '%{monitor-id} %{monitor-appkit-nsscreen-screens-id}')
    workspaces = query('list-workspaces', '--all', '--format', '%{workspace} %{monitor-id}')
    windows = query('list-windows', '--all', '--format', '%{workspace} %{app-name}')
    visible = query('list-workspaces', '--monitor', 'all', '--visible')
    focused = query('list-workspaces', '--focused')[0]['workspace']
    return project(workspaces, windows, monitors, visible, focused)


def item_id(sid):
    return 'mocha.ws.' + hashlib.sha256(sid.encode()).hexdigest()[:12]


def accent(sid):
    index = int(sid) - 1 if sid.isdigit() else int(hashlib.sha256(sid.encode()).hexdigest()[:8], 16)
    return COLORS[index % len(COLORS)]


def tint(color):
    base = '1e1e2e'
    return '0xff' + ''.join(f'{round(int(color[i:i+2],16)*.18+int(base[i:i+2],16)*.82):02x}' for i in (0, 2, 4))


def send(args):
    if args:
        subprocess.run([SBAR, *args], check=True, timeout=5, stdout=subprocess.DEVNULL)


def update(initial=False):
    rows = snapshot()
    icons = json.loads((ROOT / 'app-icons.json').read_text())
    cache_path = STATE / 'workspaces.json'
    try:
        previous = json.loads(cache_path.read_text())
    except (OSError, ValueError):
        previous = {}
    signature = [(r['workspace'], r['display']) for r in rows]
    recreate = initial or previous.get('signature') != [list(s) for s in signature]
    args = []
    if recreate:
        if not initial:
            args += ['--remove', '/mocha\\.ws\\..*/', '--remove', '/mocha\\.more\\..*/', '--remove', '/mocha\\.entry\\..*/']
        for row in rows:
            sid = row['workspace']
            item = item_id(sid)
            command = f'{shlex.quote(AERO)} workspace {shlex.quote(sid)}'
            args += ['--add', 'item', item, 'left', '--set', item,
                     f'icon={sid}', 'icon.font=SF Pro:Semibold:12.0',
                     'label.font=sketchybar-app-font:Regular:15.0',
                     'background.height=27', 'background.corner_radius=8',
                     'background.drawing=on', 'background.border_width=1',
                     'icon.padding_left=9', 'icon.padding_right=5',
                     'label.padding_left=1', 'label.padding_right=9',
                     'padding_left=3', 'padding_right=3', f'click_script={command}']
        for display in sorted({r['display'] for r in rows}):
            parent = f'mocha.more.{display}'
            args += ['--add', 'item', parent, 'left', '--set', parent,
                     f'display={display}', 'icon=󰇘', 'icon.color=0xffa6adc8',
                     'icon.font=Hack Nerd Font:Regular:17.0', 'label.drawing=off',
                     'background.drawing=off', 'popup.align=left', 'popup.height=25',
                     'popup.background.color=0xff1e1e2e', 'popup.background.border_color=0xff45475a',
                     'popup.background.border_width=1', 'popup.background.corner_radius=10',
                     f'click_script={shlex.quote(SBAR)} --set {parent} popup.drawing=toggle',
                     f'script={shlex.quote(SBAR)} --set {parent} popup.drawing=off',
                     '--subscribe', parent, 'mouse.exited.global', 'aerospace_workspace_change']
            for row in [r for r in rows if r['display'] == display]:
                sid = row['workspace']
                entry = 'mocha.entry.' + item_id(sid).split('.')[-1]
                args += ['--add', 'item', entry, f'popup.{parent}', '--set', entry,
                         f'icon={sid}', 'icon.font=SF Pro:Semibold:12.0',
                         'label.font=SF Pro:Regular:12.0', 'background.drawing=off',
                         'icon.width=30', 'label.padding_right=15',
                         f'click_script={shlex.quote(SBAR)} --set {parent} popup.drawing=off; {shlex.quote(AERO)} workspace {shlex.quote(sid)}']
    if recreate or rows != previous.get('rows'):
        for row in rows:
            sid = row['workspace']
            color = accent(sid)
            selected = row['focused']
            foreground = '0xff181825' if selected else '0xff' + color
            glyphs = list(dict.fromkeys(icons.get(app, icons.get('Default', ':default:')) for app in row['apps']))
            label = ' '.join(glyphs[:2]) if glyphs else '—'
            args += ['--set', item_id(sid), f'display={row["display"]}',
                     'drawing=' + ('on' if row['drawing'] else 'off'),
                     f'label={label}', f'icon.color={foreground}', f'label.color={foreground}',
                     'background.color=' + ('0xff' + color if selected else tint(color)),
                     'background.border_color=' + ('0xffcdd6f4' if selected else ('0xff' + color if row['visible'] else '0x00000000'))]
            text = ', '.join(row['apps'])[:66] or 'Empty workspace'
            args += ['--set', 'mocha.entry.' + item_id(sid).split('.')[-1],
                     f'label={text}', 'icon.color=0xff' + color,
                     'label.color=' + ('0xffcba6f7' if selected else '0xffcdd6f4')]
    send(args)
    temp = cache_path.with_suffix('.tmp')
    temp.write_text(json.dumps(dict(signature=signature, rows=rows)))
    temp.replace(cache_path)


if __name__ == '__main__':
    if '--snapshot' in sys.argv:
        print(json.dumps(snapshot(), indent=2))
    else:
        STATE.mkdir(mode=0o700, parents=True, exist_ok=True)
        with (STATE / 'workspace.lock').open('w') as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                update(initial='--init' in sys.argv)
            except BlockingIOError:
                pass  # A periodic refresh recovers an event received during a batch.
            except (subprocess.SubprocessError, OSError, ValueError, KeyError, IndexError) as exc:
                print(f'Mocha workspace update: {exc}', file=sys.stderr)
                sys.exit(1)
