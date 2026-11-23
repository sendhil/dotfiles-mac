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
