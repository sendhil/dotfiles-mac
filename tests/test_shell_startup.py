"""Exercise resolved prompt configuration and opt-in machine-local startup logic.

Set SHELL_STARTUP_LOCAL_CONFIG to test local startup blocks without adding any
private configuration to the repository. Only the named integration blocks are
read into fixtures; environment values and other local contents are not logged.
"""
import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class PromptStartupTests(unittest.TestCase):
    def test_unused_cloud_and_task_segments_are_disabled_without_removing_work_context(self):
        with tempfile.TemporaryDirectory() as home:
            result = subprocess.run(
                ['/bin/zsh', '-dfc', 'source "$1"; print -rl -- $POWERLEVEL9K_LEFT_PROMPT_ELEMENTS $POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS', 'prompt-test', str(ROOT / 'prezto/.p10k.zsh')],
                env={'HOME': home, 'PATH': '/usr/bin:/bin', 'TERM': 'xterm-256color'},
                capture_output=True, text=True, timeout=10, check=False,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        segments = result.stdout.splitlines()
        for segment in ('gcloud', 'google_app_cred', 'azure', 'taskwarrior'):
            self.assertNotIn(segment, segments)
        for segment in ('dir', 'vcs', 'aws', 'kubecontext'):
            self.assertIn(segment, segments)


LOCAL_CONFIG = os.environ.get('SHELL_STARTUP_LOCAL_CONFIG')


@unittest.skipUnless(LOCAL_CONFIG, 'set SHELL_STARTUP_LOCAL_CONFIG for machine-local tests')
class LocalShellStartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='shell-startup-test-')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        self.calls = self.home / 'calls'
        self.config = Path(LOCAL_CONFIG).read_text()
        self.env = {'HOME': str(self.home), 'PATH': str(self.bin), 'TEST_CALLS': str(self.calls)}

    def stub(self, name, body):
        executable = self.bin / name
        executable.write_text('#!/bin/sh\n' + body)
        executable.chmod(0o700)

    def block(self, start, end):
        return self.config.split(start, 1)[1].split(end, 1)[0]

    def run_block(self, text, assertions, input=''):
        source = self.home / 'startup.zsh'
        source.write_text(text)
        return subprocess.run(
            ['/bin/zsh', '-dfc', 'source "$1"; ' + assertions, 'startup-test', str(source)],
            env=self.env, input=input, capture_output=True, text=True, timeout=10, check=False,
        )

    def recorded_calls(self):
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_local_integrations_do_not_launch_devbox(self):
        self.stub('fzf', 'printf "fzf\\n" >>"$TEST_CALLS"\nprintf "export FZF_INTEGRATION=ready\\n"\n')
        self.stub('direnv', 'printf "direnv\\n" >>"$TEST_CALLS"\nprintf "export DIRENV_INTEGRATION=ready\\n"\n')
        self.stub('devbox', 'printf "devbox\\n" >>"$TEST_CALLS"\n')
        integration = 'eval "$(fzf --zsh)"' + self.block('eval "$(fzf --zsh)"', '#eval "$(mcfly init zsh)"')
        result = self.run_block(integration, 'print -r -- "$FZF_INTEGRATION/$DIRENV_INTEGRATION"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'ready/ready')
        self.assertNotIn('devbox', self.recorded_calls())
        self.assertEqual(self.recorded_calls(), ['fzf', 'direnv'])

    def dx_block(self):
        return self.block('# Work-local dx tools and shell completions.', '# # The next line updates PATH for the Google Cloud SDK.')

    def stub_dx(self, output="export DX_MARKER='value with spaces'", status=0, check_stdin=False):
        stdin_check = 'if read -r unexpected; then exit 91; fi\n' if check_stdin else ''
        self.stub('dx', 'printf "dx %s\\n" "$*" >>"$TEST_CALLS"\n'
                  + '[ "$#" -eq 1 ] && [ "$1" = env ] || exit 90\n'
                  + stdin_check + 'printf "%s\\n" ' + shlex.quote(output)
                  + ('\nprintf "fixture diagnostic\\n" >&2' if status else '')
                  + f'\nexit {status}\n')

    def test_dx_env_is_evaluated_from_one_invocation(self):
        self.stub_dx()
        result = self.run_block(self.dx_block(), 'print -r -- "${DX_MARKER-unset}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.recorded_calls(), ['dx env'])
        self.assertEqual(result.stdout.strip(), 'value with spaces')
        self.assertEqual(result.stderr, '')

    def test_dx_env_does_not_consume_shell_input(self):
        self.stub_dx(check_stdin=True)
        result = self.run_block(self.dx_block(), 'print -r -- "${DX_MARKER-unset}"', input='user input\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'value with spaces')
        self.assertEqual(self.recorded_calls(), ['dx env'])

    def test_failed_dx_env_output_is_not_evaluated(self):
        self.stub_dx(output='export DX_MARKER=should-not-be-applied', status=7)
        result = self.run_block(self.dx_block(), 'print -r -- "${DX_MARKER-unset}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'unset')
        self.assertEqual(result.stderr, '')
        self.assertEqual(self.recorded_calls(), ['dx env'])

    def test_missing_dx_does_not_break_shell_startup(self):
        result = self.run_block(self.dx_block(), 'print -r -- "${DX_MARKER-unset}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'unset')
        self.assertEqual(result.stderr, '')
        self.assertEqual(self.recorded_calls(), [])

    def test_empty_dx_env_output_is_safe(self):
        self.stub_dx(output='')
        result = self.run_block(self.dx_block(), 'print -r -- "${DX_MARKER-unset}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'unset')
        self.assertEqual(result.stderr, '')
        self.assertEqual(self.recorded_calls(), ['dx env'])

    def test_dx_env_applies_multiline_completion_code(self):
        self.stub_dx(output='export DX_MARKER=ready\ndx_fixture_completion() { print -r -- completion-ready; }')
        result = self.run_block(self.dx_block(), 'dx_fixture_completion')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'completion-ready')
        self.assertEqual(self.recorded_calls(), ['dx env'])

    def test_dx_env_does_not_leave_its_temporary_variable(self):
        self.stub_dx()
        result = self.run_block(self.dx_block(), 'print -r -- ${+parameters[_dotfiles_dx_shellenv]}')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), '0')


if __name__ == '__main__':
    unittest.main()
