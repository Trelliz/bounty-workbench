"""Offline tests: publishing must never contact GitHub accidentally."""
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
# The real bridge module is in the repository, but is not needed to exercise
# the publisher's safe outbound message or rate cap.
with mock.patch.dict(sys.modules, {'bounty_copilot_bridge': mock.Mock()}):
    import publish_scanner_queue as publisher


class PublisherTests(unittest.TestCase):
    def test_destination_refuses_public(self):
        with tempfile.TemporaryDirectory() as folder, mock.patch.object(publisher.os, 'geteuid', return_value=123):
            with mock.patch.object(publisher, 'read_token', return_value='fake-token'), mock.patch.object(
                    publisher, 'api_request', return_value={'full_name': 'Trelliz/bounty-workbench', 'private': False}) as call:
                self.assertRaises(ValueError, publisher.run, Path(folder), 'Trelliz/bounty-workbench', Path('/token'), True)
                self.assertEqual(call.call_count, 1)

    def test_publish_sends_only_public_issue_url_and_sats(self):
        with tempfile.TemporaryDirectory() as folder, mock.patch.object(publisher.os, 'geteuid', return_value=123):
            with mock.patch.object(publisher, 'read_token', return_value='fake-token'), mock.patch.object(
                    publisher, 'qualified_leads', return_value=[('someorg/somerepo', 123, 25000)]), mock.patch.object(
                    publisher, 'remote_existing', return_value=(set(), 0)), mock.patch.object(
                    publisher, 'api_request') as api:
                api.side_effect = [{'full_name': 'Trelliz/bounty-inbox', 'private': True}, {'number': 1}]
                publisher.run(Path(folder), 'Trelliz/bounty-inbox', Path('/token'), True)
                self.assertEqual(api.call_count, 2)
                path, token = api.call_args.args
                self.assertEqual(path, '/repos/Trelliz/bounty-inbox/issues')
                self.assertEqual(token, 'fake-token')
                body = api.call_args.kwargs['body']['body']
                self.assertIn('https://github.com/someorg/somerepo/issues/123', body)
                self.assertIn('UNVERIFIED', body)
                self.assertNotIn('/var/lib/', body)
                self.assertNotIn('fake-token', body)

    def test_daily_cap_skips_all_queue(self):
        with tempfile.TemporaryDirectory() as folder, mock.patch.object(publisher.os, 'geteuid', return_value=123):
            with mock.patch.object(publisher, 'read_token', return_value='fake-token'), mock.patch.object(
                    publisher, 'remote_existing', return_value=(set(), 10)), mock.patch.object(
                    publisher, 'qualified_leads') as leads, mock.patch.object(
                    publisher, 'api_request', return_value={'full_name': 'Trelliz/bounty-inbox', 'private': True}):
                publisher.run(Path(folder), 'Trelliz/bounty-inbox', Path('/token'), True)
                leads.assert_not_called()

    def test_read_token_rejects_loose_file_mode(self):
        with tempfile.TemporaryDirectory() as folder:
            p = Path(folder) / 'token'
            p.write_text('secret-token')
            p.chmod(0o644)
            self.assertRaises(ValueError, publisher.read_token, p)

    def test_remote_dedupes_published_ids(self):
        with mock.patch.object(publisher, 'api_request', return_value=[
            {'title': 'Bounty lead: owner/repo#45', 'created_at': '2020-01-01T00:00:00Z'},
            {'title': 'Other issue', 'created_at': '2020-01-01T00:00:00Z'}
        ]) as api:
            ids, count = publisher.remote_existing('Trelliz/bounty-inbox', 't')
            self.assertEqual(ids, {'owner/repo#45'})
            self.assertEqual(count, 0)
            self.assertEqual(api.call_count, 1)


if __name__ == '__main__':
    unittest.main()
