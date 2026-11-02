#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');
const root = process.argv[2];
const script = path.join(root, 'ghostty/.config/ghostty/theme.sh');
const temp = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'ghostty-theme-')));
let count = 0;
let passed = 0;
function fixture() {
  const dir = path.join(temp, String(++count));
  const home = path.join(dir, 'home with spaces');
  const bin = path.join(dir, 'bin');
  const base = path.join(dir, 'tracked-config');
  const config = path.join(home, '.config/ghostty/config');
  const state = path.join(home, '.local/state/dotfiles-mac/ghostty/theme.ghostty');
  const calls = path.join(dir, 'calls');
  const themes = path.join(dir, 'theme resources');
  fs.mkdirSync(themes, {recursive: true});
  fs.writeFileSync(path.join(themes, 'Catppuccin Mocha'), 'cursor-color = #f5e0dc\n');
  fs.mkdirSync(path.dirname(config), {recursive: true});
  fs.mkdirSync(bin, {recursive: true});
  fs.writeFileSync(base, 'theme = TokyoNight Storm\ncursor-color = #7aa2f7\n');
  fs.symlinkSync(base, config);
  const mock = String.raw`#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const name = path.basename(process.argv[1]);
const args = process.argv.slice(2);
fs.appendFileSync(process.env.FAKE_CALLS, JSON.stringify({name, args}) + '\n');
if (name === 'ghostty') {
  if (args[0] === '+validate-config') {
    if (process.env.FAKE_VALIDATION_FAIL) {console.error('deliberate invalid config'); process.exit(7);}
    const file = args.find(x => x.startsWith('--config-file='));
    if (!file || !fs.existsSync(file.slice('--config-file='.length))) process.exit(8);
  } else if (args[0] === '+list-themes') {
    for (const theme of ['TokyoNight Storm', 'TokyoNight Day', 'Catppuccin Mocha']) {
      console.log(theme + ' (resources)' + (args.includes('--path') ? ' ' + path.join(process.env.FAKE_THEME_DIR, theme) : ''));
    }
  } else process.exit(9);
} else if (name === 'pgrep') {
  process.exit(process.env.FAKE_GHOSTTY_RUNNING ? 0 : 1);
} else if (name === 'osascript') {
  if (process.env.FAKE_RELOAD_FAIL) {console.error('automation denied'); process.exit(1);}
  console.log(process.env.FAKE_RELOAD_FALSE ? 'false' : 'true');
} else if (name === 'fzf') {
  fs.writeFileSync(process.env.FAKE_CALLS + '.choices', fs.readFileSync(0, 'utf8'));
  if (process.env.FAKE_PICK_EXIT) process.exit(Number(process.env.FAKE_PICK_EXIT));
  console.log(process.env.FAKE_PICK || 'TokyoNight Day');
}
`;
  for (const name of ['ghostty', 'pgrep', 'osascript', 'fzf']) {
    fs.writeFileSync(path.join(bin, name), mock, {mode: 0o755});
  }
  return {home, bin, base, config, state, calls, original: fs.readFileSync(base, 'utf8'), env: {
    ...process.env, HOME: home, PATH: bin + path.delimiter + process.env.PATH,
    GHOSTTY_BIN: path.join(bin, 'ghostty'), FAKE_CALLS: calls, FAKE_THEME_DIR: themes,
    FAKE_VALIDATION_FAIL: '', FAKE_GHOSTTY_RUNNING: '', FAKE_RELOAD_FAIL: '', FAKE_RELOAD_FALSE: '', FAKE_PICK_EXIT: '', FAKE_PICK: '',
  }};
}
function run(f, args = [], extra = {}, target = script) {
  return spawnSync('bash', [target, ...args], {env: {...f.env, ...extra}, encoding: 'utf8', timeout: 10000});
}
function ok(result) {assert.equal(result.status, 0, result.stdout + result.stderr);}
function unchanged(f) {
  assert.equal(fs.readFileSync(f.base, 'utf8'), f.original, 'tracked base must remain unchanged');
  assert.ok(fs.lstatSync(f.config).isSymbolicLink(), 'base symlink must survive');
}
function calls(f, name) {
  return fs.existsSync(f.calls) ? fs.readFileSync(f.calls, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse).filter(x => x.name === name) : [];
}
function test(name, body) {
  if (process.env.GHOSTTY_THEME_TEST_FILTER && !name.includes(process.env.GHOSTTY_THEME_TEST_FILTER)) return;
  body(); passed++; console.log('ok - ' + name);
}
try {
  test('set persists a validated local override without changing the tracked base', () => {
    const f = fixture();
    ok(run(f, ['set', 'TokyoNight Day']));
    assert.ok(fs.existsSync(f.state), 'set must create the machine-local override');
    assert.equal(fs.readFileSync(f.state, 'utf8'), 'theme = TokyoNight Day\ncursor-color = #2e7de9\n');
    assert.equal(fs.statSync(f.state).mode & 0o777, 0o600);
    assert.equal(calls(f, 'ghostty').filter(x => x.args[0] === '+validate-config').length, 1);
    unchanged(f);
  });
  test('toggle alternates Day and Storm without changing the base', () => {
    const f = fixture();
    ok(run(f, ['toggle']));
    assert.ok(fs.existsSync(f.state), 'toggle must persist the alternate theme');
    assert.match(fs.readFileSync(f.state, 'utf8'), /^theme = TokyoNight Day$/m);
    ok(run(f, ['toggle']));
    assert.match(fs.readFileSync(f.state, 'utf8'), /^theme = TokyoNight Storm$/m);
    unchanged(f);
  });
  test('reset removes the override and exposes the base theme', () => {
    const f = fixture();
    ok(run(f, ['set', 'TokyoNight Day']));
    ok(run(f, ['reset']));
    assert.ok(!fs.existsSync(f.state), 'reset must remove the local override');
    const result = run(f, ['current']);
    ok(result);
    assert.equal(result.stdout.trim(), 'TokyoNight Storm');
    unchanged(f);
  });
  test('the default favorites picker applies its selected theme locally', () => {
    const f = fixture();
    ok(run(f, [], {FAKE_PICK: 'Catppuccin Mocha'}));
    assert.ok(fs.existsSync(f.state), 'the picker must persist its selection');
    assert.equal(fs.readFileSync(f.state, 'utf8'), 'theme = Catppuccin Mocha\ncursor-color = #f5e0dc\n');
    assert.equal(calls(f, 'fzf').length, 1);
    unchanged(f);
  });
  test('cancel and no-match leave the prior selection untouched', () => {
    for (const code of ['130', '1']) {
      const f = fixture();
      ok(run(f, ['set', 'TokyoNight Day']));
      const before = fs.readFileSync(f.state, 'utf8');
      ok(run(f, ['pick'], {FAKE_PICK_EXIT: code}));
      assert.equal(fs.readFileSync(f.state, 'utf8'), before);
      assert.equal(calls(f, 'ghostty').filter(x => x.args[0] === '+validate-config').length, 1);
      unchanged(f);
    }
  });
  test('unknown and unavailable themes cannot replace the prior selection', () => {
    for (const theme of ['Unknown Theme', 'TokyoNight Night', 'TokyoNight Day\nbackground = red']) {
      const f = fixture();
      ok(run(f, ['set', 'TokyoNight Day']));
      const before = fs.readFileSync(f.state, 'utf8');
      const result = run(f, ['set', theme]);
      assert.notEqual(result.status, 0, 'unsupported theme must be rejected');
      assert.equal(fs.readFileSync(f.state, 'utf8'), before);
      unchanged(f);
    }
  });
  test('the picker offers only favorites installed in this Ghostty', () => {
    const f = fixture();
    ok(run(f, ['pick']));
    assert.equal(fs.readFileSync(f.calls + '.choices', 'utf8'), 'TokyoNight Storm\nTokyoNight Day\nCatppuccin Mocha\n');
  });
  test('a running Ghostty reloads through native automation rather than typing keys', () => {
    const f = fixture();
    ok(run(f, ['set', 'TokyoNight Day'], {FAKE_GHOSTTY_RUNNING: '1'}));
    const reloads = calls(f, 'osascript');
    assert.equal(reloads.length, 1, 'a running Ghostty must receive a reload');
    const action = reloads[0].args.join(' ');
    assert.match(action, /perform action "reload_config"/);
    assert.doesNotMatch(action, /System Events|keystroke|input text|new window/);
  });
  test('unavailable automation preserves the theme and gives a manual-reload fallback', () => {
    for (const extra of [{FAKE_RELOAD_FAIL: '1'}, {FAKE_RELOAD_FALSE: '1'}]) {
      const f = fixture();
      const result = run(f, ['set', 'TokyoNight Day'], {FAKE_GHOSTTY_RUNNING: '1', ...extra});
      ok(result);
      assert.match(result.stderr, /Cmd\+Shift\+,/);
      assert.match(fs.readFileSync(f.state, 'utf8'), /^theme = TokyoNight Day$/m);
      unchanged(f);
    }
  });
  test('validation failure preserves the last good override and cleans temporary files', () => {
    const f = fixture();
    ok(run(f, ['set', 'TokyoNight Day']));
    const before = fs.readFileSync(f.state, 'utf8');
    const result = run(f, ['set', 'TokyoNight Storm'], {FAKE_VALIDATION_FAIL: '1', FAKE_GHOSTTY_RUNNING: '1'});
    assert.notEqual(result.status, 0, 'invalid candidate must fail');
    assert.equal(fs.readFileSync(f.state, 'utf8'), before);
    assert.deepEqual(fs.readdirSync(path.dirname(f.state)), ['theme.ghostty']);
    assert.equal(calls(f, 'osascript').length, 0);
    unchanged(f);
  });
  test('help describes the picker, toggle, and reset without changing state', () => {
    const f = fixture();
    const result = run(f, ['--help']);
    ok(result);
    assert.match(result.stdout, /pick/);
    assert.match(result.stdout, /toggle/);
    assert.match(result.stdout, /reset/);
    assert.ok(!fs.existsSync(f.state));
    assert.equal(calls(f, 'ghostty').length, 0);
  });
  test('the original toggle entry point uses local persistence through a stowed helper', () => {
    const f = fixture();
    const live = path.join(f.home, '.config/ghostty');
    fs.symlinkSync(script, path.join(live, 'theme.sh'));
    const wrapper = path.join(live, 'toggle-theme.sh');
    fs.symlinkSync(path.join(root, 'ghostty/.config/ghostty/toggle-theme.sh'), wrapper);
    ok(run(f, [], {}, wrapper));
    assert.ok(fs.existsSync(f.state), 'legacy toggle must use the machine-local override');
    assert.match(fs.readFileSync(f.state, 'utf8'), /^theme = TokyoNight Day$/m);
    unchanged(f);
  });
  test('native Ghostty loads local selection and reset without duplicating icon maps', () => {
    const native = '/Applications/Ghostty.app/Contents/MacOS/ghostty';
    assert.ok(fs.existsSync(native), 'native Ghostty is required for this integration test');
    const f = fixture();
    fs.writeFileSync(f.base, fs.readFileSync(path.join(root, 'ghostty/.config/ghostty/config'), 'utf8'));
    f.original = fs.readFileSync(f.base, 'utf8');
    const env = {GHOSTTY_BIN: native, XDG_CONFIG_HOME: path.join(f.home, '.config')};
    ok(run(f, ['set', 'TokyoNight Day'], env));
    const effective = () => {
      const result = spawnSync(native, ['+show-config', '--no-pager'], {env: {...f.env, ...env}, encoding: 'utf8', timeout: 10000});
      ok(result);
      return result.stdout;
    };
    const day = effective();
    assert.match(day, /^theme = TokyoNight Day$/m, 'the base must include the local override');
    assert.match(day, /^cursor-color = #2e7de9$/m);
    for (const range of ['U+E1A0-U+E1BA', 'U+E1C0-U+E1C5']) {
      assert.equal(day.split('\n').filter(line => line === 'font-codepoint-map = ' + range + '=Herdr Agent Icons Max').length, 1);
    }
    ok(run(f, ['set', 'Catppuccin Mocha'], env));
    const mocha = effective();
    assert.match(mocha, /^theme = Catppuccin Mocha$/m);
    assert.match(mocha, /^cursor-color = #f5e0dc$/m, 'other favorites must use their own cursor color');
    ok(run(f, ['reset'], env));
    const storm = effective();
    assert.match(storm, /^theme = TokyoNight Storm$/m);
    assert.match(storm, /^cursor-color = #7aa2f7$/m);
    unchanged(f);
  });
  test('the real fzf accepts the picker flags and selects a favorite non-interactively', () => {
    const nativeFzf = '/opt/homebrew/bin/fzf';
    assert.ok(fs.existsSync(nativeFzf), 'Homebrew fzf is required for this integration test');
    const f = fixture();
    fs.unlinkSync(path.join(f.bin, 'fzf'));
    fs.symlinkSync(nativeFzf, path.join(f.bin, 'fzf'));
    ok(run(f, ['pick'], {FZF_DEFAULT_OPTS: '--filter=Day', FZF_DEFAULT_OPTS_FILE: ''}));
    assert.match(fs.readFileSync(f.state, 'utf8'), /^theme = TokyoNight Day$/m);
    unchanged(f);
  });
  console.log(passed + ' Ghostty theme tests passed');
} finally {
  fs.rmSync(temp, {recursive: true, force: true});
}
JS
