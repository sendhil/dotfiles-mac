import importlib.util
import pathlib
import unittest

SOURCE = pathlib.Path(__file__).parents[1] / 'sketchybar' / '.config' / 'sketchybar' / 'plugins' / 'workspaces.py'


class WorkspaceLayoutTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not SOURCE.exists():
            return
        spec = importlib.util.spec_from_file_location('workspaces', SOURCE)
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def project(self, workspaces, windows, focused='3', visible=None, limit=7):
        self.assertTrue(SOURCE.exists(), 'Workspace projection has not been implemented')
        return self.module.project(
            workspaces, windows,
            [{'monitor-id': 1, 'monitor-appkit-nsscreen-screens-id': 2},
             {'monitor-id': 2, 'monitor-appkit-nsscreen-screens-id': 1}],
            visible or [{'workspace': focused}], focused, limit,
        )

    def test_keeps_selected_empty_workspace_and_hides_other_empty_workspaces(self):
        rows = self.project([{'workspace': str(i), 'monitor-id': 1} for i in range(1, 5)],
                            [{'workspace': '1', 'app-name': 'Safari'}])
        self.assertEqual([r['workspace'] for r in rows if r['drawing']], ['1', '3'])

    def test_sorts_numbers_and_translates_monitor_identifiers(self):
        rows = self.project([{'workspace': '10', 'monitor-id': 1},
                             {'workspace': '2', 'monitor-id': 2}], [])
        self.assertEqual([(r['workspace'], r['display']) for r in rows], [('2', 1), ('10', 2)])

    def test_retains_each_displays_visible_empty_workspace(self):
        rows = self.project([{'workspace': '3', 'monitor-id': 1}, {'workspace': '21', 'monitor-id': 2}],
                            [], visible=[{'workspace': '3'}, {'workspace': '21'}])
        self.assertTrue(all(r['drawing'] for r in rows))
        self.assertEqual([r['workspace'] for r in rows if r['focused']], ['3'])

    def test_caps_workspaces_without_losing_the_focused_one(self):
        rows = self.project([{'workspace': str(i), 'monitor-id': 1} for i in range(1, 21)],
                            [{'workspace': str(i), 'app-name': 'Terminal'} for i in range(1, 21)],
                            focused='19', limit=7)
        shown = [r['workspace'] for r in rows if r['drawing']]
        self.assertEqual(len(shown), 7)
        self.assertIn('19', shown)

    def test_deduplicates_apps_without_losing_window_count(self):
        rows = self.project([{'workspace': '3', 'monitor-id': 1}],
                            [{'workspace': '3', 'app-name': 'Terminal'}] * 3)
        self.assertEqual(rows[0]['apps'], ['Terminal'])
        self.assertEqual(rows[0]['window_count'], 3)

    def test_unknown_display_does_not_leak_onto_all_displays(self):
        rows = self.project([{'workspace': '3', 'monitor-id': 99}], [])
        self.assertEqual(rows, [])


if __name__ == '__main__':
    unittest.main()
