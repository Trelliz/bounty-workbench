import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from verify_issue import validate, validate_issue
from collect_patch import collect
import subprocess

class WorkerTests(unittest.TestCase):
    def test_repo_input(self):
        self.assertEqual(validate('owner/repo', '42'), ('owner/repo', 42))
        for bad in ('https://github.com/o/r', 'a/../b', 'o/.git', 'invalid', '-foo/bar'):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                validate(bad, 42)

    def test_bad_issue_number(self):
        for x in ('0', '-1', 'whatever'):
            with self.assertRaises(ValueError): validate('owner/repo', x)

    def test_open_issue(self):
        self.assertEqual(validate_issue({'state': 'open', 'title': 'Fix issue', 'body': 'text', 'html_url': 'https://github.com/owner/repo/issues/2'}, 'owner/repo', 2)['title'], 'Fix issue')

    def test_no_pr(self):
        with self.assertRaises(ValueError):
            validate_issue({'state': 'open','title':'x','body':'','pull_request':{}, 'html_url':'https://github.com/owner/repo/issues/2'}, 'owner/repo', 2)

    def test_patch_includes_untracked(self):
        with tempfile.TemporaryDirectory() as d:
            repo=Path(d)/'repo'
            repo.mkdir()
            subprocess.run(['git','init','-q'],cwd=repo,check=True)
            subprocess.run(['git','-c','user.email=test@example.test','-c','user.name=Test','commit','-q','--allow-empty','-m','init'],cwd=repo,check=True)
            (repo/'a.txt').write_text('draft')
            collect(repo,Path(d)/'out')
            self.assertIn(b'draft', (Path(d)/'out'/'solution.patch').read_bytes())

if __name__=='__main__':
    unittest.main()
