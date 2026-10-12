#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node - "$ROOT" <<'JS'
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = process.argv[2];
assert.ok(fs.existsSync(path.join(root, 'scripts/setup-herdr-mac.sh')), 'Missing portable Herdr setup script');
const tmp = fs.realpathSync(fs.mkdtempSync('/tmp/hdt-'));
let count = 0;
const pin = 'dd42772da4b8b9e18660d653d08149c7da1d2964';
function fixture() {
  const dir = path.join(tmp, String(++count));
  const repo = path.join(dir, 'checkout with spaces');
  const home = path.join(dir, 'home');
  const bin = path.join(dir, 'bin');
  const main = path.join(home, '.config/herdr/config.toml');
  const prefs = path.join(home, '.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml');
  const baseline = path.join(repo, 'herdr/.config/herdr/config.toml');
  const prefSource = path.join(repo, 'herdr/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml');
  fs.mkdirSync(path.dirname(baseline), {recursive:true});
  fs.mkdirSync(path.dirname(prefSource), {recursive:true});
  fs.mkdirSync(path.join(repo, 'scripts'), {recursive:true});
  fs.mkdirSync(bin, {recursive:true});
  fs.mkdirSync(home, {recursive:true});
  fs.writeFileSync(path.join(bin, 'node'), `#!/bin/sh
if [ -n "\${FAKE_NODE_VERSION:-}" ]; then
  exec "${process.execPath}" -e 'Object.defineProperty(process,"version",{value:process.env.FAKE_NODE_VERSION});require("vm").runInThisContext(require("fs").readFileSync(0,"utf8"));' -- "$@"
fi
exec "${process.execPath}" "$@"
`, {mode:0o755});
  fs.copyFileSync(path.join(root, 'scripts/setup-herdr-mac.sh'), path.join(repo, 'scripts/setup-herdr-mac.sh'));
  fs.writeFileSync(baseline, 'onboarding = false\n[keys]\nprefix = "ctrl+a"\n[ui]\n[theme]\nname = "catppuccin"\n');
  fs.writeFileSync(prefSource, 'row_label = "tab"\n');
  fs.writeFileSync(path.join(bin, 'uname'), '#!/bin/sh\nprintf "%s\\n" "${FAKE_OS:-Darwin}"\n', {mode:0o755});
  // Exercise actual CLI orchestration without touching the real server.
  fs.writeFileSync(path.join(bin, 'herdr'), String.raw`#!/usr/bin/env node
const fs=require('fs'),path=require('path');
const a=process.argv.slice(2), dir=process.env.FAKE_DIR;
fs.appendFileSync(path.join(dir,'calls'),JSON.stringify(a)+'\n');
const out=x=>console.log(JSON.stringify(x));
const record=()=>({plugin_id:'hhdebb.herdr-radar',enabled:!process.env.FAKE_DISABLED,warnings:[],source:{kind:'github',owner:process.env.FAKE_OWNER||'hhdebb',repo:'herdr-radar',resolved_commit:process.env.FAKE_PIN||'${pin}'}});
if(a[0]==='--version') console.log('herdr '+(process.env.FAKE_VERSION||'0.9.0'));
else if(a[0]==='status') out({server:{running:!process.env.FAKE_SERVER_DOWN,version:process.env.FAKE_SERVER_VERSION||'0.9.0',socket:path.join(process.env.HOME,'.config/herdr/herdr.sock')}});
else if(a[0]==='plugin'&&a[1]==='list') out({result:{plugins:process.env.FAKE_ABSENT&&!fs.existsSync(path.join(dir,'installed'))?[]:[record()]}});
else if(a[0]==='plugin'&&a[1]==='install') {fs.writeFileSync(path.join(dir,'installed'),'yes');console.log('installed');}
else if(a[0]==='plugin'&&a[1]==='enable') out({result:{}});
else if(a[0]==='plugin'&&a[1]==='action') {
 const id=String(Date.now());
 fs.writeFileSync(path.join(dir,'action'),JSON.stringify({id,action:a[3],polls:0}));
 out({result:{log:{log_id:id,status:'running'}}});
}
else if(a[0]==='plugin'&&a[1]==='log') {
 const action=JSON.parse(fs.readFileSync(path.join(dir,'action')));
 if(action.polls++===0) {
  fs.writeFileSync(path.join(dir,'action'),JSON.stringify(action));
  out({result:{logs:[{log_id:action.id,status:'running'}]}});process.exit(0);
 }
 if(process.env.FAKE_FAIL===action.action) out({result:{logs:[{log_id:action.id,status:'failed',exit_code:1,stderr:'deliberate action failure'}]}});
 else {
  if(action.action.endsWith('.configure')) {
   const config=path.join(process.env.HOME,'.config/herdr/config.toml');
   let text=fs.readFileSync(config,'utf8');
   if(!text.includes('herdr-radar sidebar block')) fs.appendFileSync(config,'\n# >>> herdr-radar sidebar block\n# <<< herdr-radar sidebar block\n');
  }
  if(action.action.endsWith('.state-stop')) {fs.writeFileSync(path.join(dir,'stopped'),'yes');fs.rmSync(path.join(dir,'healthy'),{force:true});}
  if(action.action.endsWith('.state-start')) {
   if(!fs.existsSync(path.join(dir,'stopped'))) throw Error('start before stop completion');
   fs.writeFileSync(path.join(dir,'healthy'),'yes');
  }
  out({result:{logs:[{log_id:action.id,status:'succeeded',exit_code:0}]}});
 }
}
else if(a[0]==='config') console.log('config: ok');
else if(a[0]==='agent') {
 const ready=path.join(dir,'labels-ready');
 const delayed=process.env.FAKE_LABEL_DELAY&&!fs.existsSync(ready);
 fs.writeFileSync(ready,'yes');
 out({result:{agents:[{pane_id:'w1:p1',agent_status:'idle',tokens:delayed?{}:{logo:'pi',title_idle:'named tab',ws_key:'0',tab_key:'0'}}]}});
}
else {console.error('Unexpected command '+JSON.stringify(a));process.exit(1);}
`, {mode:0o755});
  // A real local socket answers the script's daemon health probe. One socket
  // per test fixture, so no installed Radar process or PID is touched.
  const socket = path.join(home, '.local/state/herdr/plugins/hhdebb.herdr-radar/control.sock');
  fs.mkdirSync(path.dirname(socket), {recursive:true});
  const env = {...process.env, HOME:home, PATH:bin+path.delimiter+process.env.PATH, FAKE_DIR:dir,
    XDG_CONFIG_HOME:'', XDG_STATE_HOME:'', HERDR_CONFIG_PATH:'', HERDR_SOCKET_PATH:'', HERDR_SESSION:'', HERDR_BIN_PATH:''};
  return {dir,repo,home,main,prefs,baseline,prefSource,env};
}
function run(f, args=[], extra={}) {
  return spawnSync('bash', [path.join(f.repo,'scripts/setup-herdr-mac.sh'), ...args], {env:{...f.env,...extra},encoding:'utf8',timeout:20000});
}
function ok(r) { assert.equal(r.status,0,r.stdout+'\n'+r.stderr); }
function fail(r, text) { assert.notEqual(r.status,0); assert.match(r.stdout+r.stderr,text); }
function calls(f) {return fs.existsSync(path.join(f.dir,'calls'))?fs.readFileSync(path.join(f.dir,'calls'),'utf8').trim().split('\n').filter(Boolean).map(JSON.parse):[];}
function backups(f) {
  const dir=path.join(f.home,'.local/state/dotfiles-mac/herdr/backups');
  return fs.existsSync(dir)?fs.readdirSync(dir).map(n=>fs.readFileSync(path.join(dir,n),'utf8')):[];
}
function test(name, fn) {fn();console.log('PASS '+name);}
try {
 test('Radar follows the selected dark Herdr theme rather than desktop appearance',()=>{
  const prefs=fs.readFileSync(path.join(root,'herdr/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml'),'utf8');
  assert.match(prefs,/^follow_appearance\s*=\s*false\s*(?:#.*)?$/m,'Radar must not select light inks for a dark terminal');
  const main=fs.readFileSync(path.join(root,'herdr/.config/herdr/config.toml'),'utf8');
  assert.match(main,/\[theme\]\s*\nname\s*=\s*"catppuccin"/,'Herdr baseline must retain the dark theme');
 });
 test('fresh offline deployment and repeat preserve local edits',()=>{
  const f=fixture();ok(run(f,['--deploy-only']));
  assert.equal(fs.lstatSync(f.main).isSymbolicLink(),false);
  assert.equal(fs.readFileSync(f.main,'utf8'),fs.readFileSync(f.baseline,'utf8'));
  assert.equal(fs.realpathSync(f.prefs),f.prefSource);
  fs.appendFileSync(f.main,'# local edit\n');
  ok(run(f,['--deploy-only']));assert.match(fs.readFileSync(f.main,'utf8'),/# local edit/);
  assert.equal(backups(f).length,0);assert.equal(calls(f).length,0);
 });
 test('migrate only owned main symlink without writing its target',()=>{
  const f=fixture();fs.mkdirSync(path.dirname(f.main),{recursive:true});fs.symlinkSync(f.baseline,f.main);
  const before=fs.readFileSync(f.baseline,'utf8');ok(run(f,['--deploy-only']));
  assert.equal(fs.lstatSync(f.main).isSymbolicLink(),false);assert.equal(fs.readFileSync(f.baseline,'utf8'),before);
  assert.ok(backups(f).includes(before));
 });
 test('differing config refuses unless replacement explicitly approved',()=>{
  const f=fixture();fs.mkdirSync(path.dirname(f.main),{recursive:true});fs.writeFileSync(f.main,'# other config\n');
  fail(run(f,['--deploy-only']),/replace-config/);assert.equal(fs.existsSync(f.prefs),false);
  ok(run(f,['--deploy-only','--replace-config']));assert.ok(backups(f).includes('# other config\n'));
 });
 test('foreign symlink replacement never writes through it',()=>{
  const f=fixture();fs.mkdirSync(path.dirname(f.main),{recursive:true});const other=path.join(f.dir,'other');
  fs.writeFileSync(other,'# foreign\n');fs.symlinkSync(other,f.main);
  fail(run(f,['--deploy-only']),/replace-config/);ok(run(f,['--deploy-only','--replace-config']));
  assert.equal(fs.readFileSync(other,'utf8'),'# foreign\n');assert.ok(backups(f).includes('# foreign\n'));
 });
 test('conflicting preferences preflight prevents main-config changes',()=>{
  const f=fixture();fs.mkdirSync(path.dirname(f.prefs),{recursive:true});fs.writeFileSync(f.prefs,'row_label = "title"\n');
  fail(run(f,['--deploy-only']),/replace-config/);assert.equal(fs.existsSync(f.main),false);
  ok(run(f,['--deploy-only','--replace-config']));assert.ok(backups(f).includes('row_label = "title"\n'));
 });
 test('equivalent preference file becomes owned symlink',()=>{
  const f=fixture();fs.mkdirSync(path.dirname(f.prefs),{recursive:true});fs.copyFileSync(f.prefSource,f.prefs);
  ok(run(f,['--deploy-only']));assert.equal(fs.realpathSync(f.prefs),f.prefSource);
 });
 test('changed baseline requires backed-up replacement',()=>{
  const f=fixture();ok(run(f,['--deploy-only']));fs.appendFileSync(f.baseline,'# new baseline\n');
  fail(run(f,['--deploy-only']),/replace-config/);ok(run(f,['--deploy-only','--replace-config']));
  assert.match(fs.readFileSync(f.main,'utf8'),/# new baseline/);assert.equal(backups(f).length,1);
 });
 test('unlink removes only owned preference link and retains main config',()=>{
  const f=fixture();ok(run(f,['--deploy-only']));ok(run(f,['--unlink-preferences']));
  assert.equal(fs.existsSync(f.prefs),false);assert.equal(fs.existsSync(f.main),true);
 });
 test('reject unsupported platform and path overrides before changes',()=>{
  for(const extra of [{FAKE_OS:'Linux'},{XDG_CONFIG_HOME:'/other'},{XDG_STATE_HOME:'/other'},{HERDR_CONFIG_PATH:'/other'}]) {
   const f=fixture();fail(run(f,['--deploy-only'],extra),/macOS|override/);assert.equal(fs.existsSync(f.main),false);
  }
 });
 test('symlinked directory refuses before modifying repo or foreign state',()=>{
  const f=fixture();const other=path.join(f.dir,'foreign');fs.mkdirSync(other);
  fs.mkdirSync(path.join(f.home,'.config'));fs.symlinkSync(other,path.join(f.home,'.config/herdr'));
  fail(run(f,['--deploy-only']),/symlinked parent/);assert.deepEqual(fs.readdirSync(other),[]);
 });
 test('missing server and prerelease versions refuse without deployment',()=>{
  for(const extra of [{FAKE_SERVER_DOWN:'1'},{FAKE_VERSION:'0.9.0-beta.1'}]) {
   const f=fixture();fail(run(f,[],extra),/Launch Herdr|0\.9\.0/);assert.equal(fs.existsSync(f.main),false);
  }
 });
 test('old Node is rejected even for offline deployment',()=>{
  const f=fixture();fail(run(f,['--deploy-only'],{FAKE_NODE_VERSION:'v16.20.0'}),/Node 18/);
  assert.equal(fs.existsSync(f.main),false);
 });
 test('version floors and wrong plugin registration refuse before deployment',()=>{
  for(const extra of [{FAKE_VERSION:'0.8.2'},{FAKE_SERVER_VERSION:'0.8.2'},{FAKE_OWNER:'someone-else'},{FAKE_PIN:'wrong'}]) {
   const f=fixture();fail(run(f,[],extra),/0\.9\.0|registration/);assert.equal(fs.existsSync(f.main),false);
  }
 });
 test('failed plugin action stops the sequence and exposes error',()=>{
  const f=fixture();fail(run(f,[],{FAKE_FAIL:'hhdebb.herdr-radar.install-font'}),/deliberate action failure/);
  assert.ok(!calls(f).some(a=>a.includes('hhdebb.herdr-radar.state-start')));
 });
 test('stop/configure failure never starts a replacement daemon',()=>{
  for(const name of ['state-stop','configure']) {
   const f=fixture();fail(run(f,[],{FAKE_FAIL:'hhdebb.herdr-radar.'+name}),/deliberate action failure/);
   assert.ok(!calls(f).some(a=>a.includes('hhdebb.herdr-radar.state-start')));
  }
 });
 test('full setup waits for stop before configure/start and verifies health',()=>{
  const f=fixture();
  // Run fake daemon as a separate Node process so synchronous test execution
  // cannot prevent the real socket health probe from receiving a reply.
  const daemonCode=`const net=require('net'),fs=require('fs');const dir=process.argv[1];const sock=process.argv[2];net.createServer(s=>s.on('data',()=>{if(fs.existsSync(dir+'/healthy'))s.end(JSON.stringify({ok:true,pid:123,fire_age_ms:1,frame_running_ms:null})+'\\n');else s.end();})).listen(sock);`;
  const {spawn}=require('node:child_process');
  const daemon=spawn(process.execPath,['-e',daemonCode,f.dir,path.join(f.home,'.local/state/herdr/plugins/hhdebb.herdr-radar/control.sock')],{stdio:'ignore'});
  try {
   ok(run(f,[],{FAKE_ABSENT:'1',FAKE_LABEL_DELAY:'1'}));
   const c=calls(f), actions=c.filter(a=>a[0]==='plugin'&&a[1]==='action').map(a=>a[3]);
   assert.deepEqual(actions,['hhdebb.herdr-radar.install-font','hhdebb.herdr-radar.state-stop','hhdebb.herdr-radar.configure','hhdebb.herdr-radar.state-start']);
   assert.ok(c.some(a=>a[1]==='install'&&a.includes(pin)));
   assert.ok(!c.some(a=>a[0]==='server'&&a[1]==='stop'));
   const beforeCheck=calls(f).length;
   ok(run(f,['--check']));
   assert.ok(!calls(f).slice(beforeCheck).some(a=>a[0]==='plugin'&&['action','install','enable'].includes(a[1])));
   ok(run(f));
   const starts=calls(f).filter(a=>a.includes('hhdebb.herdr-radar.state-start'));
   assert.equal(starts.length,1,'unchanged healthy repeat should not restart Radar');
  } finally {daemon.kill();}
 });
 test('tracked baseline and preferences are portable',()=>{
  const main=fs.readFileSync(path.join(root,'herdr/.config/herdr/config.toml'),'utf8');
  assert.ok(!main.includes('/Users/'));assert.ok(!main.includes('>>> herdr-radar'));
  assert.match(fs.readFileSync(path.join(root,'herdr/.config/herdr/plugins/config/hhdebb.herdr-radar/config.toml'),'utf8'),/row_label = "tab"/);
 });
 test('Makefile routes Herdr deployment separately from Stow',()=>{
  const make=fs.readFileSync(path.join(root,'Makefile'),'utf8');
  assert.match(make,/STOW_PACKAGES\s*=\s*\$\(filter-out herdr,\$\(PACKAGES\)\)/);
  assert.match(make,/stow-herdr:[\s\S]*?setup-herdr-mac\.sh --deploy-only/);
  assert.match(make,/setup-herdr:[\s\S]*?setup-herdr-mac\.sh/);
 });
 console.log('All portable Herdr tests passed.');
} finally {fs.rmSync(tmp,{recursive:true,force:true});}
JS
