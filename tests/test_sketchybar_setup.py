import importlib.util
import json
from pathlib import Path
import tempfile
import shutil
import subprocess
from unittest.mock import patch
import unittest

SOURCE = Path(__file__).parents[1] / 'scripts' / 'sketchybar_setup.py'

class SetupTests(unittest.TestCase):
    def setUp(self):
        self.assertTrue(SOURCE.exists(), 'Portable installer is not implemented')
        spec = importlib.util.spec_from_file_location('setup', SOURCE)
        self.m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.m)
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name) / 'Another User'
        self.home.mkdir()

    def test_restore_existing_directory_and_absent_path(self):
        cfg = self.home / '.config/sketchybar'
        cfg.mkdir(parents=True)
        (cfg / 'custom').write_text('original')
        snap = self.m.Snapshot.create(self.home, ['.config/sketchybar', 'Library/LaunchAgents/test.plist'], {})
        self.m.remove_path(cfg)
        cfg.symlink_to('/tmp/new checkout/sketchybar', target_is_directory=True)
        agent = self.home / 'Library/LaunchAgents/test.plist'
        agent.parent.mkdir(parents=True)
        agent.write_text('installed')
        snap.record()
        snap.restore_files()
        self.assertEqual((cfg / 'custom').read_text(), 'original')
        self.assertFalse(agent.exists())

    def test_restore_preserves_original_symlink_without_editing_target(self):
        target = self.home / 'original-source'
        target.mkdir()
        (target / 'a').write_text('untouched')
        link = self.home / 'config'
        link.symlink_to('original-source')
        snap = self.m.Snapshot.create(self.home, ['config'], {})
        link.unlink()
        link.mkdir()
        snap.record()
        snap.restore_files()
        self.assertEqual(link.readlink(), Path('original-source'))
        self.assertEqual((target / 'a').read_text(), 'untouched')

    def test_restore_refuses_to_overwrite_later_edits(self):
        path = self.home / 'agent'
        path.write_text('original')
        snap = self.m.Snapshot.create(self.home, ['agent'], {})
        path.write_text('installed')
        snap.record()
        path.write_text('user edit')
        with self.assertRaisesRegex(RuntimeError, 'changed since setup'):
            snap.restore_files()
        self.assertEqual(path.read_text(), 'user edit')

    def test_reopening_snapshot_does_not_replace_original_backup(self):
        path = self.home / 'config'
        path.write_text('original')
        snap = self.m.Snapshot.create(self.home, ['config'], {})
        path.write_text('first installation')
        snap.record()
        reopened = self.m.Snapshot(snap.root)
        path.write_text('second installation')
        reopened.record()
        reopened.restore_files()
        self.assertEqual(path.read_text(), 'original')

    def test_launch_agent_uses_discovered_executable_and_home_with_spaces(self):
        p = self.m.launch_agent('local.sketchybar-mocha', '/usr/local/bin/sketchybar', self.home)
        self.assertEqual(p['ProgramArguments'], ['/usr/local/bin/sketchybar'])
        self.assertTrue(p['StandardErrorPath'].startswith(str(self.home)))
        self.assertTrue(p['RunAtLoad'])
        self.assertTrue(p['KeepAlive'])

    def test_waits_for_clock_initialization_before_reporting_ready(self):
        self.assertTrue(hasattr(self.m, 'wait_ready'), 'Setup needs a readiness check')
        responses = [subprocess.CompletedProcess([], 0, '{"label":{"value":""}}', ''),
                     subprocess.CompletedProcess([], 0, '{"label":{"value":"1:09 PM"}}', '')]
        with patch.object(self.m, 'run', side_effect=responses), patch('time.sleep'):
            self.m.wait_ready()

    def test_readiness_timeout_reports_startup_failure(self):
        self.assertTrue(hasattr(self.m, 'wait_ready'), 'Setup needs a readiness check')
        with patch.object(self.m, 'run', return_value=subprocess.CompletedProcess([], 1, '', '')):
            with self.assertRaisesRegex(RuntimeError, 'did not finish starting'):
                self.m.wait_ready(timeout=0)

    def test_full_setup_rerun_restore_with_real_stow(self):
        stow = shutil.which('stow') or '/opt/homebrew/bin/stow'
        self.assertTrue(Path(stow).exists(), 'Stow is required for the integration test')
        repo = Path(self.tmp.name) / 'dotfiles checkout'
        for package in ('sketchybar', 'aerospace'):
            folder = repo / package / '.config' / package
            folder.mkdir(parents=True)
            (folder / 'config').write_text('tracked content')
        original = self.home / '.config/sketchybar'
        original.mkdir(parents=True)
        (original / 'old').write_text('previous custom bar')
        prefs = {'_HIHideMenuBar': '0', 'AppleMenuBarVisibleInFullscreen': '1'}
        calls = []
        real_run = self.m.run
        def fake_run(args, check=True):
            calls.append([str(x) for x in args])
            if args[0] == 'stow':
                return real_run([stow, *args[1:]], check)
            output = '{"label": {"value": "1:09 PM"}}' if args[0] == 'sketchybar' else ''
            return subprocess.CompletedProcess(args, 0, output, '')
        with patch.object(self.m, 'REPO', repo), \
             patch.object(self.m, 'dependencies', return_value=[]), \
             patch.object(self.m, 'loaded', return_value=False), \
             patch.object(self.m, 'run', side_effect=fake_run), \
             patch.object(self.m, 'pref_read', side_effect=prefs.get), \
             patch.object(self.m, 'pref_write', side_effect=lambda k,v: prefs.update({k:v})), \
             patch.object(self.m.shutil, 'which', side_effect=lambda c: '/usr/local/bin/' + c):
            self.m.setup(self.home)
            latest = self.home / 'Library/Application Support/dotfiles-sketchybar/active-backup'
            first_backup = latest.read_text()
            self.assertTrue(original.is_symlink())
            self.assertEqual((original / 'config').read_text(), 'tracked content')
            self.assertEqual(prefs['_HIHideMenuBar'], '1')
            self.m.setup(self.home)
            self.assertEqual(latest.read_text(), first_backup)
            self.m.restore(self.home)
            self.assertEqual((original / 'old').read_text(), 'previous custom bar')
            self.assertFalse((self.home / '.config/aerospace').exists())
            self.assertFalse(latest.exists())
            self.assertEqual(prefs, {'_HIHideMenuBar':'0', 'AppleMenuBarVisibleInFullscreen':'1'})
        self.assertEqual(sum(c[0]=='stow' and '--simulate' in c for c in calls), 2)

    def test_failed_mid_install_can_restore_written_files(self):
        a = self.home / 'a'; b = self.home / 'b'
        a.write_text('old a'); b.write_text('old b')
        snap = self.m.Snapshot.create(self.home, ['a', 'b'], {})
        a.write_text('new a')
        snap.record()
        snap.restore_files()
        self.assertEqual(a.read_text(), 'old a')
        self.assertEqual(b.read_text(), 'old b')

if __name__ == '__main__':
    unittest.main()
