"""Guard retired integrations and reproducible tmux plugin metadata."""
import configparser
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RepositoryCleanupTests(unittest.TestCase):
    def test_retired_files_are_absent(self):
        for name in (
            "bin/.local/bin/opencode-sessions",
            "bin/.local/bin/cmux-scratch",
            "bin/.local/bin/cmux-scratch.swift",
            "cmux/.config/cmux/cmux.json",
            "cmux/.config/cmux/settings.json",
            "scripts/agentmemory-batch.py",
            "scripts/agentmemory-graph-extract.py",
            "scripts/opencode-permissions.py",
            "scripts/opencode-to-jsonl.py",
        ):
            with self.subTest(path=name):
                self.assertFalse((ROOT / name).exists())

    def test_retired_callers_are_absent(self):
        for name in ("Makefile", "bash-linux/.bash/utilities", "wezterm/.wezterm.lua"):
            text = (ROOT / name).read_text().lower()
            for word in ("opencode", "oc-session", "oc-active-sessions", "cmux"):
                with self.subTest(path=name, word=word):
                    self.assertNotIn(word, text)
        self.assertNotIn("build-bin:", (ROOT / "Makefile").read_text())

    def test_submodule_mappings_match_gitlinks(self):
        expected = {
            "tmux/.tmux/plugins/tmux-jump": "https://github.com/schasse/tmux-jump",
            "tmux/.tmux/plugins/tmux-yank": "https://github.com/tmux-plugins/tmux-yank",
            "tmux/.tmux/plugins/tokyo-night-tmux": "https://github.com/janoamaral/tokyo-night-tmux",
            "tmux/.tmux/plugins/vim-tmux-navigator": "https://github.com/christoomey/vim-tmux-navigator",
        }
        config = configparser.ConfigParser()
        config.read(ROOT / ".gitmodules")
        actual = {config[s]["path"]: config[s]["url"] for s in config.sections()}
        self.assertEqual(actual, expected)
        self.assertEqual(len(config.sections()), len(expected))
        tracked = subprocess.check_output(
            ["git", "ls-files", "--stage", "-z"], cwd=ROOT
        ).decode().split("\0")
        gitlinks = {line.split("\t", 1)[1] for line in tracked if line.startswith("160000 ")}
        self.assertEqual(gitlinks, set(expected))
        self.assertTrue(any(
            line.startswith("100755 ") and line.endswith("\ttmux/.tmux/plugins/tpm/tpm")
            for line in tracked
        ))


if __name__ == "__main__":
    unittest.main()
