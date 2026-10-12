#!/usr/bin/env bash
# Deploy portable preferences; keep Herdr's generated config and runtime local.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if ! command -v node >/dev/null 2>&1; then
  echo 'Node 18+ is required (no runtimes are installed automatically).' >&2
  exit 1
fi
node - "$ROOT" "$@" <<'JS'
'use strict';
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const net = require('node:net');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const root = fs.realpathSync(process.argv[2]);
const args = process.argv.slice(3);
const ID = 'hhdebb.herdr-radar';
const PIN = 'dd42772da4b8b9e18660d653d08149c7da1d2964'; // Radar 1.4.4
const HOME = os.homedir();
const configDir = path.join(HOME, '.config/herdr');
const mainFile = path.join(configDir, 'config.toml');
const prefsFile = path.join(configDir, 'plugins/config', ID, 'config.toml');
const baseline = path.join(root, 'herdr/.config/herdr/config.toml');
const prefsSource = path.join(root, 'herdr/.config/herdr/plugins/config', ID, 'config.toml');
const stateDir = path.join(HOME, '.local/state/dotfiles-mac/herdr');
const markerFile = path.join(stateDir, 'deployment.json');
const socket = path.join(HOME, '.local/state/herdr/plugins', ID, 'control.sock');
const env = {...process.env, HERDR_SOCKET_PATH:path.join(configDir, 'herdr.sock'), HERDR_SESSION:''};
const allowed = new Set(['--deploy-only', '--check', '--replace-config', '--unlink-preferences', '--help']);
const hash = text => crypto.createHash('sha256').update(text).digest('hex');
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
function fail(message) {throw new Error(message);}
function cli(argv, json = false) {
  const r = spawnSync('herdr', argv, {env, encoding:'utf8', timeout:30000, maxBuffer:8*1024*1024});
  if (r.error || r.status !== 0) fail(`herdr ${argv.join(' ')}: ${r.error?.message || r.stderr.trim() || r.stdout.trim() || 'failed'}`);
  if (!json) return r.stdout.trim();
  let result;
  try {result = JSON.parse(r.stdout);} catch {fail(`herdr ${argv.join(' ')} returned invalid JSON`);}
  if (result.error) fail(JSON.stringify(result.error));
  return result;
}
function versionAtLeast(value, minimum) {
  const m = String(value).match(/^(?:herdr\s+|v)?(\d+)\.(\d+)\.(\d+)(?:\s|$|\+)/);
  if (!m) return false;
  const v = m.slice(1).map(Number);
  for(let i=0;i<3;i++) {if(v[i]!==minimum[i]) return v[i]>minimum[i];}
  return true;
}
function stat(file) {try {return fs.lstatSync(file);} catch(e) {if(e.code==='ENOENT') return null;throw e;}}
function text(file) {return fs.readFileSync(file, 'utf8');}
function linkedTo(file, target) {
  if (!stat(file)?.isSymbolicLink()) return false;
  try {return fs.realpathSync(file) === fs.realpathSync(target);} catch {return false;}
}
function loadMarker() {try {return JSON.parse(text(markerFile));} catch(e) {if(e.code==='ENOENT') return {};fail(`Unreadable deployment marker: ${e.message}`);}}
function parentSafety(file) {
  for(let dir=path.dirname(file);dir!==HOME && dir!==path.dirname(dir);dir=path.dirname(dir)) {
    if(stat(dir)?.isSymbolicLink()) fail(`Refusing symlinked parent directory ${dir}; unfold it before deployment.`);
  }
}
function atomicWrite(file, content) {
  fs.mkdirSync(path.dirname(file), {recursive:true});
  const tmp = `${file}.dotfiles-${process.pid}`;
  try {fs.writeFileSync(tmp, content, {mode:0o600,flag:'wx'});fs.renameSync(tmp,file);}
  finally {fs.rmSync(tmp,{force:true});}
}
function backup(file) {
  const dir=path.join(stateDir,'backups');fs.mkdirSync(dir,{recursive:true});
  const dest=path.join(dir,`${Date.now()}-${process.pid}-${path.basename(path.dirname(file))}-${path.basename(file)}`);
  fs.copyFileSync(file,dest,fs.constants.COPYFILE_EXCL);
  console.log(`Backup: ${dest}`);
}
function planFile(file, source, marker, isMain) {
  parentSafety(file);
  const s=stat(file);
  if(!s) return {file,source,backup:false};
  if(!s.isFile()&&!s.isSymbolicLink()) fail(`Not a file: ${file}`);
  const owned=linkedTo(file,source);
  let equal=false;
  try {equal=text(file)===text(source);} catch {fail(`Unreadable or dangling config: ${file}; resolve it before deployment.`);}
  if(isMain && !s.isSymbolicLink() && marker.baseline_hash===hash(text(source))) return null;
  if(!isMain && owned) return null;
  if(!owned&&!equal&&!args.includes('--replace-config')) {
    fail(`Conflicting or changed config: ${file}. Review it, then use --replace-config to back up and replace it.`);
  }
  // A foreign link, even with equal contents, needs explicit authorization.
  if(s.isSymbolicLink()&&!owned&&!args.includes('--replace-config')) fail(`Foreign config symlink: ${file}; review before --replace-config.`);
  return {file,source,backup:true};
}
function deploy(marker) {
  // Preflight both before any writes, so a preference conflict cannot partly
  // replace the main config. Runtime registry changes happen only afterwards.
  const plans=[planFile(mainFile,baseline,marker,true),planFile(prefsFile,prefsSource,marker,false)].filter(Boolean);
  parentSafety(markerFile);
  for(const p of plans) {
    if(p.backup) backup(p.file);
    fs.mkdirSync(path.dirname(p.file),{recursive:true});
    if(p.file===mainFile) atomicWrite(p.file,text(p.source));
    else {
      const tmp=`${p.file}.dotfiles-${process.pid}`;
      try {fs.symlinkSync(p.source,tmp);fs.renameSync(tmp,p.file);} finally {fs.rmSync(tmp,{force:true});}
    }
    console.log(`Deployed: ${p.file}`);
  }
  const next={...marker,baseline_hash:hash(text(baseline))};
  if(plans.some(p=>p.file===mainFile)) delete next.applied_baseline_hash;
  if(JSON.stringify(next)!==JSON.stringify(marker)) atomicWrite(markerFile,JSON.stringify(next,null,2)+'\n');
  return next;
}
function registration() {
  const plugins=cli(['plugin','list','--json'],true).result?.plugins;
  if(!Array.isArray(plugins)) fail('Malformed plugin list');
  const matches=plugins.filter(p=>p.plugin_id===ID);
  if(matches.length>1) fail('Duplicate Radar registration');
  const p=matches[0];
  if(p && (p.source?.kind!=='github'||p.source.owner!=='hhdebb'||p.source.repo!=='herdr-radar'||p.source.resolved_commit!==PIN||p.warnings?.length)) {
    fail('Unexpected Radar registration/source/version; inspect it manually. No registration was overwritten.');
  }
  return p;
}
function serverPreflight() {
  if(!versionAtLeast(cli(['--version']),[0,9,0])) fail('Herdr 0.9.0+ is required.');
  const s=cli(['status','--json'],true).server;
  if(!s?.running) fail('Launch Herdr once, then rerun setup from a shell in that session. Offline deployment: --deploy-only.');
  if(!versionAtLeast(s.version,[0,9,0])) fail('The running Herdr server must be 0.9.0+; it will not be restarted automatically.');
  if(s.socket && s.socket!==env.HERDR_SOCKET_PATH) fail('Unexpected server socket; refusing to configure another session.');
}
async function action(name) {
  const response=cli(['plugin','action','invoke',`${ID}.${name}`],true);
  const id=response.result?.log?.log_id;
  if(!id) fail(`No log ID returned for ${name}`);
  const until=Date.now()+30000;
  while(Date.now()<until) {
    const logs=cli(['plugin','log','list','--plugin',ID,'--limit','100'],true).result?.logs;
    if(!Array.isArray(logs)) fail(`Malformed plugin logs for ${name}`);
    const log=logs.find(l=>l.log_id===id);
    if(log?.status==='succeeded'&&log.exit_code===0) {console.log(`Radar action completed: ${name}`);return;}
    if(log && log.status!=='running') fail(`Radar ${name} failed (${log.status}, exit ${log.exit_code}): ${log.stderr||log.stdout||'no output'}`);
    await pause(100);
  }
  fail(`Timed out waiting for Radar action ${name} (${id}); no dependent action was launched.`);
}
function ping() {
  return new Promise(resolve=>{
    let done=false,body='';
    const stream=net.connect({path:socket});
    const finish=value=>{if(done)return;done=true;stream.destroy();resolve(value);};
    stream.setTimeout(1000,()=>finish(null));
    stream.on('error',()=>finish(null));stream.on('close',()=>finish(null));
    stream.on('connect',()=>stream.write('{"cmd":"ping"}\n'));
    stream.on('data',chunk=>{
      body+=chunk;
      if(body.length>8192) return finish(null);
      if(body.includes('\n')) {try{finish(JSON.parse(body.split('\n')[0]));}catch{finish(null);}}
    });
  });
}
function healthy(p) {return p?.ok===true && typeof p.fire_age_ms==='number' && p.fire_age_ms<30000 && (p.frame_running_ms===null || (typeof p.frame_running_ms==='number'&&p.frame_running_ms<300000));}
async function waitDaemon(wantRunning) {
  const until=Date.now()+20000;
  do {
    const p=await ping();
    if(wantRunning?healthy(p):p===null) return;
    await pause(100);
  } while(Date.now()<until);
  fail(wantRunning?'Radar did not become healthy.':'Radar still answers after stop; refusing to start another daemon.');
}
async function verify() {
  if(stat(mainFile)?.isSymbolicLink()) fail('Main config should be a local regular file.');
  if(!linkedTo(prefsFile,prefsSource)) fail('Radar preferences are not linked to this checkout.');
  if(!text(mainFile).includes('# >>> herdr-radar sidebar block')) fail('Radar sidebar block is absent; run full setup.');
  cli(['config','check']);
  await waitDaemon(true);
  // A responding control socket is not proof the first render finished.
  // Startup clears old tokens before repainting, so wait for current labels.
  const until=Date.now()+20000;
  let agents, missing;
  do {
    agents=cli(['agent','list'],true).result?.agents;
    if(!Array.isArray(agents)) fail('Malformed agent list');
    missing=agents.filter(a=>{
      const tokens=a.tokens??{};
      return !tokens.ws_key||!tokens.tab_key||!Object.keys(tokens).some(k=>k.startsWith('title_'));
    });
    if(!missing.length) break;
    await pause(100);
  } while(Date.now()<until);
  if(missing.length) fail(`Radar labels not ready on ${missing.map(a=>a.pane_id).join(', ')}`);
  console.log(`Verified Radar healthy; ${agents.length} live agent pane(s).`);
  console.log('In Herdr, choose "reload config" to refresh client layout/keys. New terminal windows pick up installed fonts.');
}
async function main() {
  if(args.some(a=>!allowed.has(a))) fail('Unknown option; use --help.');
  if(args.includes('--help')) {
    console.log('Usage: setup-herdr-mac.sh [--deploy-only | --check | --unlink-preferences] [--replace-config]\nDefault: deploy, ensure pinned Radar/font, apply and verify. No Herdr server restart.');return;
  }
  if(args.filter(a=>['--deploy-only','--check','--unlink-preferences'].includes(a)).length>1) fail('Choose only one mode.');
  if(!versionAtLeast(process.version,[18,0,0])) fail('Node 18+ is required.');
  const platform=spawnSync('uname',['-s'],{encoding:'utf8',timeout:5000});
  if(platform.status!==0||platform.stdout.trim()!=='Darwin') fail('This setup is for macOS only.');
  for(const key of ['XDG_CONFIG_HOME','XDG_STATE_HOME','HERDR_CONFIG_PATH']) if(process.env[key]) fail(`${key} override is not supported; refusing a potentially wrong config path.`);
  if(process.env.HERDR_SESSION && process.env.HERDR_SESSION!=='default') fail('Named sessions are not supported by this bootstrap; use the default session.');
  if(process.env.HERDR_SOCKET_PATH && process.env.HERDR_SOCKET_PATH!==env.HERDR_SOCKET_PATH) fail('HERDR_SOCKET_PATH override is not supported; use the default local session.');
  if(args.includes('--unlink-preferences')) {
    parentSafety(prefsFile);
    if(linkedTo(prefsFile,prefsSource)) {fs.unlinkSync(prefsFile);console.log('Removed owned Radar preference symlink; main config/runtime retained.');}
    else if(stat(prefsFile)) fail('Refusing to unlink preferences not owned by this checkout.');
    return;
  }
  const marker=loadMarker();
  if(args.includes('--deploy-only')) {deploy(marker);console.log('Offline deployment complete; run make setup-herdr for plugin/font setup.');return;}
  serverPreflight();
  let plugin=registration(); // Validate before filesystem deployment.
  if(args.includes('--check')) {
    if(!plugin?.enabled) fail('Pinned Radar is not enabled.');
    if(marker.baseline_hash!==hash(text(baseline))) fail('Baseline changed; review and redeploy with --replace-config.');
    if(marker.applied_prefs_hash!==hash(text(prefsSource))) fail('Preferences changed; rerun full setup to apply them.');
    await verify();return;
  }
  const next=deploy(marker);
  if(!plugin) {
    console.log(`Installing reviewed Radar 1.4.4 commit ${PIN}`);
    console.log(cli(['plugin','install','hhdebb/herdr-radar','--ref',PIN,'--yes']));
    plugin=registration();if(!plugin) fail('Radar installation did not register the expected plugin.');
  }
  if(!plugin.enabled) cli(['plugin','enable',ID],true);
  const prefsHash=hash(text(prefsSource));
  const current=await ping();
  const needsApply=next.applied_prefs_hash!==prefsHash || next.applied_baseline_hash!==next.baseline_hash || !text(mainFile).includes('# >>> herdr-radar sidebar block') || !healthy(current);
  // install-font is idempotent and repairs missing local fonts/maps even when
  // settings are unchanged. It never restarts terminal or Herdr processes.
  await action('install-font');
  if(needsApply) {
    await action('state-stop');await waitDaemon(false);
    try {await action('configure');}
    catch(e) {console.error('Radar is stopped after configure failure; inspect logs before invoking state-start.');throw e;}
    await action('state-start');
  }
  await verify();
  atomicWrite(markerFile,JSON.stringify({...next,applied_baseline_hash:next.baseline_hash,applied_prefs_hash:prefsHash},null,2)+'\n');
}
main().catch(e=>{console.error(`Setup failed: ${e.message}`);process.exitCode=1;});
JS
