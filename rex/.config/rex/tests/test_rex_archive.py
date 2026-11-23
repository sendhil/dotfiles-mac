import json
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path

import pytest


@pytest.fixture
def archive(tmp_path, monkeypatch):
    monkeypatch.setenv('REX_ARCHIVE_DIR', str(tmp_path))
    path = Path(__file__).resolve().parents[3] / '.local/bin/rex-archive'
    loader = SourceFileLoader('rex_archive', str(path))
    module = module_from_spec(spec_from_loader(loader.name, loader))
    loader.exec_module(module)
    return module


def test_duplicate_labels_survive(archive):
    for number in (1, 2):
        archive.write_archive(dict(type='tab', label='logs', session_label='api', number=number))
    assert sorted(json.loads(p.read_text())['number'] for p in archive.archives()) == [1, 2]


@pytest.mark.parametrize('program', ['claude', 'codex', 'pi'])
def test_ambiguous_resume_is_typed_not_run(archive, program):
    pane = archive.classify({'foreground': {'name': program}})
    assert pane['cmd']
    assert not pane['autorun']


def test_legacy_resume_is_not_executed(archive, monkeypatch):
    calls = []
    def rex(*args, **kw):
        calls.append(args)
        if args[0] == 'new':
            return {'session_id': 's', 'initial_windows': [{'block_ids': ['b']}]}
    monkeypatch.setattr(archive, 'rex', rex)
    monkeypatch.setattr(archive, 'capture_tail', lambda *args: ['ready'])
    pane = {'cmd': 'pi --continue', 'autorun': True, 'cwd': '/tmp'}
    archive.restore_archive({'windows': [{'label': 'tab', 'layout': {'pane': 'old'}, 'panes': {'old': pane}}]})
    assert 'send' in [c[0] for c in calls]
    assert 'send-key' not in [c[0] for c in calls]


def test_native_archive_refuses_scope_change(archive, monkeypatch, capsys):
    view = {'label': 'api', 'windows': [
        {'label': 'logs', 'window_id': 'w', 'layers': [{'kind': 'tiled', 'blocks': [{'block_id': 'b'}]}]},
        {'window_id': 'other'}]}
    monkeypatch.setattr(archive, 'inspect', lambda sid: view)
    monkeypatch.setattr(archive, 'block_process', lambda *a: {})
    assert 'tab-summary' in archive.COMMANDS
    archive.COMMANDS['tab-summary'](['s', 'b'])
    summary = json.loads(capsys.readouterr().out)
    view['windows'].pop()
    with pytest.raises(archive.RexError, match='changed'):
        archive.COMMANDS['archive-confirmed'](['s', 'w', summary['scope']])
    assert archive.archives() == []


def test_native_restore_catalog_omits_terminal_output(archive, monkeypatch, capsys):
    archive.write_archive(dict(type='tab', label='logs', session_label='api', session_id='gone',
                               archived_at=1, windows=[{'panes': {'b': {'tail': ['private output']}}}]))
    monkeypatch.setattr(archive, 'list_sessions', lambda: [])
    assert 'catalog' in archive.COMMANDS
    archive.COMMANDS['catalog']([])
    out = capsys.readouterr().out
    assert 'private output' not in out
    assert json.loads(out)['archives'][0]['destination'] == 'choose'


def test_native_restore_reports_staged_commands(archive, monkeypatch, capsys):
    pane = {'cmd': 'pi --continue', 'autorun': True, 'kind': 'agent', 'cwd': '/tmp'}
    archive.write_archive(dict(type='session', label='logs', windows=[
        {'label': 'logs', 'layout': {'pane': 'old'}, 'panes': {'old': pane}}]))
    key = 'archive:' + archive.archives()[0].stem
    def rex(*args, **kwargs):
        if args[0] == 'new':
            return {'session_id': 's', 'initial_windows': [{'block_ids': ['b']}]}
        assert args[0] == 'send'
    monkeypatch.setattr(archive, 'rex', rex)
    monkeypatch.setattr(archive, 'capture_tail', lambda *args: ['ready'])
    archive.cmd_restore_to([key, 'new'])
    assert archive.archives() == []
    assert json.loads(capsys.readouterr().out)['staged_commands'] == 1


def test_review_does_not_close_without_explicit_confirmation(archive, monkeypatch):
    assert 'review' in archive.COMMANDS
    monkeypatch.setattr(archive, 'list_sessions', lambda: [{'session_id':'session:1','label':'api'}])
    seen = []
    monkeypatch.setattr(archive, 'confirm', lambda verb, names: seen.extend(names) or False)
    monkeypatch.setattr(archive, 'cmd_archive', lambda *a, **kw: pytest.fail('cancelled archive'))
    archive.COMMANDS['review'](['archive', 'session:1'])
    assert seen == ['Whole session: api']


def test_favorite_workspace_lifecycle(archive, monkeypatch):
    live = {}
    monkeypatch.setattr(archive, 'list_sessions', lambda: list(live.values()))
    def rex(*args, **kw):
        if args[0] == 'new':
            sid = 'session:' + str(len(created))
            created.append(sid)
            live[sid] = {'session_id': sid, 'label': 'fleet'}
            return {'session_id': sid, 'initial_windows': [{'block_ids': ['b'], 'window_id': 'w'}]}
        assert args[0] == 'focus'
    created = []
    monkeypatch.setattr(archive, 'rex', rex)
    data = dict(type='session', label='fleet', session_label='fleet', archived_at=1,
                windows=[{'label': 'logs', 'layout': None, 'panes': {}}])
    archive.write_archive(data)
    assert 'star' in archive.COMMANDS
    key = 'archive:' + archive.archives()[0].stem
    archive.cmd_star([key])
    fid = archive.favorite_rows()[0]['id']
    first = archive.open_favorite(fid)['session']
    assert archive.open_favorite(fid)['session'] == first
    assert len(created) == 1
    archive.write_archive(dict(data, session_id=first))
    live.clear()
    assert archive.favorite_rows()[0]['state'] == 'Archived'
    assert archive.open_favorite(fid)['session'] != first
    live.clear()
    live['session:unrelated'] = dict(session_id='session:unrelated', label='fleet')
    assert archive.favorite_rows()[0]['state'] == 'Missing'
    with pytest.raises(archive.RexError):
        archive.open_favorite(fid)
    archive.forget_missing(fid)
    assert archive.favorite_rows() == []


def test_live_tab_star_survives_parent_session_archive(archive, monkeypatch):
    live = [{'session_id': 'session:old', 'label': 'project'}]
    monkeypatch.setattr(archive, 'list_sessions', lambda: live)
    monkeypatch.setattr(archive, 'inspect', lambda sid: {'windows': [{'window_id': 'w2', 'label': 'logs'}]})
    archive.cmd_star(['tab:session:old|w2'])
    fid = archive.favorite_rows()[0]['id']
    windows = [dict(source_window=w, label=w, layout=None, panes={}) for w in ('w1', 'w2')]
    archive.write_archive(dict(type='session', label='project', session_id='session:old', archived_at=1, windows=windows))
    live.clear()
    def rex(*args, **kw):
        if args[0] == 'new':
            return {'session_id':'session:new', 'initial_windows':[{'block_ids':['b'], 'window_id':'new1'}]}
        if args[0] == 'window':
            return {'block_ids':['b2'], 'window_id':'new2'}
        assert args[0] == 'focus'
    monkeypatch.setattr(archive, 'rex', rex)
    assert archive.open_favorite(fid) == {'session':'session:new', 'window':'new2'}


def test_star_archived_tab_keeps_destination_choice(archive, monkeypatch):
    monkeypatch.setattr(archive, 'list_sessions', lambda: [])
    archive.write_archive(dict(type='tab', session_label='old', label='logs', session_id='gone',
                               windows=[{}], archived_at=1))
    key = 'archive:' + archive.archives()[0].stem
    archive.cmd_star([key])
    fid = archive.favorite_rows()[0]['id']
    assert archive.open_favorite(fid) == {'choose': True}
    assert archive.archives()
    archive.cmd_star([key])
    assert archive.favorite_rows() == []
