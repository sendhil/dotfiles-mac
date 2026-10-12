#!/usr/bin/env python3
"""Install the Stow-managed Mocha bar. Python 3.9+, no third-party modules."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import time

REPO = Path(__file__).resolve().parents[1]
LABELS = ('local.sketchybar-mocha', 'local.sketchybar-native-toggle')
PREFS = ('_HIHideMenuBar', 'AppleMenuBarVisibleInFullscreen')
PATHS = ['.config/sketchybar', '.config/aerospace'] + [f'Library/LaunchAgents/{x}.plist' for x in LABELS]


def run(args, check=True):
    result = subprocess.run([str(a) for a in args], text=True, capture_output=True)
    if check and result.returncode:
        raise RuntimeError(f'{args[0]} failed: {result.stderr.strip() or result.stdout.strip()}')
    return result


def remove_path(path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def copy_path(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_symlink():
        dst.symlink_to(os.readlink(src))
    elif src.is_dir():
        shutil.copytree(src, dst, symlinks=True)
    elif src.exists():
        shutil.copy2(src, dst)


def fingerprint(path):
    if path.is_symlink():
        return 'link:' + os.readlink(path)
    if path.is_file():
        return hashlib.sha256(path.read_bytes()).hexdigest()
    if path.is_dir():
        return {p.name: fingerprint(p) for p in sorted(path.iterdir())}
    return None


class Snapshot:
    def __init__(self, root):
        self.root = Path(root)
        self.data = json.loads((self.root / 'manifest.json').read_text())
        self.home = Path(self.data['home'])

    @classmethod
    def create(cls, home, paths, extra):
        root = home / 'Library/Application Support/dotfiles-sketchybar' / datetime.datetime.now().strftime('backup-%Y%m%d-%H%M%S-%f')
        root.mkdir(parents=True, mode=0o700)
        for rel in paths:
            copy_path(home / rel, root / 'files' / rel)
        data = dict(home=str(home), paths=paths, extra=extra,
                    managed={rel: fingerprint(home / rel) for rel in paths})
        (root / 'manifest.json').write_text(json.dumps(data, indent=2))
        return cls(root)

    def save(self):
        temp = self.root / 'manifest.tmp'
        temp.write_text(json.dumps(self.data, indent=2))
        temp.replace(self.root / 'manifest.json')

    def record(self):
        self.data['managed'] = {rel: fingerprint(self.home / rel) for rel in self.data['paths']}
        self.save()

    def validate_restore(self):
        for rel, expected in self.data['managed'].items():
            if fingerprint(self.home / rel) != expected:
                raise RuntimeError(f'{rel} changed since setup; preserve those edits before restoring. Backup: {self.root}')

    def restore_files(self):
        self.validate_restore()
        for rel in self.data['paths']:
            remove_path(self.home / rel)
            copy_path(self.root / 'files' / rel, self.home / rel)


def launch_agent(label, executable, home):
    args = [str(executable)]
    if label == LABELS[1]:
        args += ['--trigger-zone', '2', '--menu-bar-height', '50', '--debounce', '180']
    logs = home / 'Library/Logs/SketchyBar-Mocha'
    return dict(Label=label, ProgramArguments=args, RunAtLoad=True, KeepAlive=True,
                ThrottleInterval=10,
                EnvironmentVariables={'PATH': os.environ.get('PATH', '/usr/bin:/bin')},
                StandardOutPath=str(logs / f'{label}.log'),
                StandardErrorPath=str(logs / f'{label}.error.log'))


def pref_read(key):
    r = run(['defaults', 'read', '-g', key], check=False)
    return r.stdout.strip() if r.returncode == 0 else None


def pref_write(key, value):
    if value is None:
        run(['defaults', 'delete', '-g', key], check=False)
    else:
        run(['defaults', 'write', '-g', key, '-bool', 'true' if str(value).lower() in ('1', 'true', 'yes') else 'false'])


def loaded(label):
    return run(['launchctl', 'print', f'gui/{os.getuid()}/{label}'], check=False).returncode == 0


def dependencies(home, install=False):
    deps = json.loads((REPO / 'scripts/sketchybar-dependencies.json').read_text())
    missing = []
    for dep in deps:
        if 'command' in dep:
            present = shutil.which(dep['command']) is not None
        else:
            present = any((p / dep['font']).exists() for p in (home / 'Library/Fonts', Path('/Library/Fonts')))
        if not present:
            missing.append(dep)
    if install and missing:
        brew = shutil.which('brew')
        if not brew:
            raise RuntimeError('Install Homebrew first: https://brew.sh')
        os.environ['HOMEBREW_NO_AUTO_UPDATE'] = '1'
        os.environ['HOMEBREW_NO_INSTALL_CLEANUP'] = '1'
        for dep in missing:
            print(f'Installing {dep["package"]}…', flush=True)
            args = [brew, 'install'] + (['--cask'] if dep['kind'] == 'cask' else []) + [dep['package']]
            subprocess.run(args, check=True)
    return missing


def check(home):
    problems = []
    for dep in dependencies(home):
        problems.append(f'Missing dependency: {dep["package"]}')
    for package in ('sketchybar', 'aerospace'):
        p = home / '.config' / package
        expected = REPO / package / '.config' / package
        if not p.is_symlink() or p.resolve() != expected.resolve():
            problems.append(f'{p} is not linked to this checkout')
    for label in LABELS:
        state = run(['launchctl', 'print', f'gui/{os.getuid()}/{label}'], check=False)
        if state.returncode or 'state = running' not in state.stdout:
            problems.append(f'Login service not running: {label}')
    spaces = run(['defaults', 'read', 'com.apple.spaces', 'spans-displays'], check=False)
    if spaces.returncode == 0 and spaces.stdout.strip() == '1':
        problems.append('Enable Displays have separate Spaces in System Settings, then log out/in')
    if pref_read(PREFS[0]) != '1' or pref_read(PREFS[1]) != '0':
        problems.append('Native menu bar is not set to Always auto-hide')
    if shutil.which('sketchybar'):
        result = run(['sketchybar', '--query', 'bar'], check=False)
        if result.returncode or 'mocha.clock' not in result.stdout:
            problems.append('Mocha bar is not responding')
    if shutil.which('aerospace'):
        result = run(['aerospace', 'list-monitors', '--json'], check=False)
        if result.returncode:
            problems.append('AeroSpace is not responding; open it and grant Accessibility access')
    print('\n'.join(problems) if problems else 'OK: dependencies, Stow links, services, native-menu settings, and bar are ready.')
    print('Display note: built-in top gap assumes a notched MacBook. See README for non-notched screens and monitor assignments.')
    return 1 if problems else 0


def wait_ready(timeout=10):
    deadline = time.monotonic() + timeout
    while True:
        result = run(['sketchybar', '--query', 'mocha.clock'], check=False)
        try:
            if result.returncode == 0 and json.loads(result.stdout).get('label', {}).get('value'):
                return
        except ValueError:
            pass
        if time.monotonic() >= deadline:
            raise RuntimeError('Mocha did not finish starting; inspect ~/Library/Logs/SketchyBar-Mocha/')
        time.sleep(0.2)


def setup(home):
    if (home / '.aerospace.toml').exists():
        raise RuntimeError('A ~/.aerospace.toml exists. Back it up and move it aside first so AeroSpace uses ~/.config/aerospace/aerospace.toml.')
    if loaded('homebrew.mxcl.sketchybar') or (home / 'Library/LaunchAgents/homebrew.mxcl.sketchybar.plist').exists():
        raise RuntimeError('A Homebrew SketchyBar service exists. Run brew services stop sketchybar first; this installer uses its own login agents.')
    dependencies(home, install=True)
    state = home / 'Library/Application Support/dotfiles-sketchybar'
    latest = state / 'active-backup'
    if latest.exists():
        snap = Snapshot(Path(latest.read_text().strip()))
        if snap.home != home:
            raise RuntimeError('Backup belongs to another home directory')
        snap.validate_restore()
    else:
        extra = dict(preferences={k: pref_read(k) for k in PREFS},
                     loaded={label: loaded(label) for label in LABELS})
        snap = Snapshot.create(home, PATHS, extra)
        latest.write_text(str(snap.root))
    print(f'Original backup: {snap.root}', flush=True)
    try:
        for label in LABELS:
            run(['launchctl', 'bootout', f'gui/{os.getuid()}/{label}'], check=False)
        for package in ('sketchybar', 'aerospace'):
            p = home / '.config' / package
            expected = REPO / package / '.config' / package
            if not p.is_symlink() or p.resolve() != expected.resolve():
                remove_path(p)
                snap.record()
        (home / '.config').mkdir(exist_ok=True)
        run(['stow', '--simulate', '--dir', REPO, '--target', home, 'sketchybar', 'aerospace'])
        run(['stow', '--dir', REPO, '--target', home, 'sketchybar', 'aerospace'])
        snap.record()
        (home / 'Library/Logs/SketchyBar-Mocha').mkdir(parents=True, exist_ok=True)
        agents = home / 'Library/LaunchAgents'
        agents.mkdir(parents=True, exist_ok=True)
        for label, command in zip(LABELS, ('sketchybar', 'sketchybar-toggle')):
            executable = shutil.which(command)
            if not executable:
                raise RuntimeError(f'{command} is missing after dependency installation')
            (agents / f'{label}.plist').write_bytes(plistlib.dumps(launch_agent(label, executable, home)))
            snap.record()
        pref_write(PREFS[0], '1')
        pref_write(PREFS[1], '0')
        run(['killall', 'SystemUIServer'], check=False)
        run(['killall', 'Dock'], check=False)
        run(['open', '-a', 'AeroSpace'])
        for label in LABELS:
            run(['launchctl', 'bootstrap', f'gui/{os.getuid()}', agents / f'{label}.plist'])
        result = run(['aerospace', 'reload-config'], check=False)
        if result.returncode:
            print('Open AeroSpace and grant Accessibility permission, then rerun --check.')
        wait_ready()
        print('Mocha setup complete. Run this script with --check to verify, or --restore to undo.')
    except Exception:
        print('Setup stopped. Your original backup is intact; run --restore to roll back.', file=sys.stderr)
        raise


def restore(home):
    latest = home / 'Library/Application Support/dotfiles-sketchybar/active-backup'
    if not latest.exists():
        raise RuntimeError('No active setup backup exists')
    snap = Snapshot(Path(latest.read_text().strip()))
    if snap.home != home:
        raise RuntimeError('Backup belongs to another home directory')
    snap.validate_restore()
    for label in LABELS:
        run(['launchctl', 'bootout', f'gui/{os.getuid()}/{label}'], check=False)
    snap.restore_files()
    for key, value in snap.data['extra']['preferences'].items():
        pref_write(key, value)
    for label, was_loaded in snap.data['extra']['loaded'].items():
        if was_loaded:
            run(['launchctl', 'bootstrap', f'gui/{os.getuid()}', home / f'Library/LaunchAgents/{label}.plist'])
    run(['killall', 'SystemUIServer'], check=False)
    run(['killall', 'Dock'], check=False)
    if shutil.which('aerospace'):
        run(['aerospace', 'reload-config'], check=False)
    latest.unlink()
    print(f'Previous configuration and menu-bar preferences restored. Backup retained: {snap.root}')
    print('Installed Homebrew dependencies remain available.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--check', action='store_true', help='Inspect without changing anything')
    group.add_argument('--restore', action='store_true', help='Restore the original pre-setup snapshot')
    args = parser.parse_args()
    if sys.platform != 'darwin' or sys.version_info < (3, 9):
        parser.error('macOS and Python 3.9+ are required')
    home = Path.home()
    try:
        if args.check:
            return check(home)
        if args.restore:
            restore(home)
        else:
            setup(home)
        return 0
    except (RuntimeError, OSError, subprocess.CalledProcessError) as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
