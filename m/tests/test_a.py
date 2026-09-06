import http.client
import logging
import os
import pathlib
import sys
import tempfile
import threading
import unittest
from unittest import mock

# Make the m/ root importable when run from any cwd.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import m_a  # noqa: E402


class AddressTests(unittest.TestCase):
    def test_tailnet_and_loopback_addresses_are_allowed(self):
        self.assertTrue(m_a._is_tailnet_address("100.64.0.1"))
        self.assertTrue(m_a._is_tailnet_address("100.127.255.254"))
        self.assertTrue(m_a._is_tailnet_address("fd7a:115c:a1e0::1"))
        self.assertTrue(m_a._is_tailnet_address("127.0.0.1"))

    def test_other_addresses_are_rejected(self):
        self.assertFalse(m_a._is_tailnet_address("100.128.0.1"))
        self.assertFalse(m_a._is_tailnet_address("192.168.1.10"))
        self.assertFalse(m_a._is_tailnet_address("not-an-address"))


class DiscoveryTests(unittest.TestCase):
    def test_online_peer_hosts_prefer_magic_dns_and_are_deduplicated(self):
        status = {
            "Peer": {
                "one": {
                    "Online": True,
                    "DNSName": "mac.example.ts.net.",
                    "HostName": "mac",
                },
                "duplicate": {
                    "Online": True,
                    "DNSName": "mac.example.ts.net.",
                },
                "two": {"Online": True, "HostName": "desktop"},
                "offline": {"Online": False, "HostName": "offline"},
            }
        }
        self.assertEqual(
            m_a._tailnet_peer_hosts(status),
            ["mac.example.ts.net", "desktop"],
        )

    @mock.patch.object(m_a, "_probe_server")
    @mock.patch.object(m_a, "_tailscale_status")
    def test_discovery_selects_the_running_audio_server(self, status, probe):
        status.return_value = {
            "Peer": {
                "one": {"Online": True, "HostName": "laptop"},
                "two": {"Online": True, "HostName": "desktop"},
            }
        }
        probe.side_effect = lambda host, port: host == "laptop" and port == 47321

        self.assertEqual(m_a._discover_host(47321), "laptop")

    @mock.patch.object(m_a, "_probe_server", return_value=True)
    @mock.patch.object(m_a, "_tailscale_status")
    def test_discovery_rejects_ambiguous_servers(self, status, _probe):
        status.return_value = {
            "Peer": {
                "one": {"Online": True, "HostName": "laptop"},
                "two": {"Online": True, "HostName": "desktop"},
            }
        }

        with self.assertRaisesRegex(RuntimeError, "multiple audio servers"):
            m_a._discover_host(47321)


class AudioServerTests(unittest.TestCase):
    def setUp(self):
        self.received = None
        self.received_path = None

        def play_audio(path):
            self.received_path = path
            self.received = pathlib.Path(path).read_bytes()

        handler = m_a._handler_class(
            play_audio,
            max_bytes=1024 * 1024,
            allow_any_client=False,
            logger=logging.getLogger("test-audio-server"),
        )
        self.server = m_a._AudioHTTPServer(("127.0.0.1", 0), handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=2)

    def test_audio_bytes_are_played_and_temporary_file_is_removed(self):
        payload = b"fake audio bytes\x00\x01\x02"
        with tempfile.TemporaryDirectory() as temp_dir:
            path = pathlib.Path(temp_dir, "sound.mp3")
            path.write_bytes(payload)
            m_a._send_audio(path, "127.0.0.1", self.server.server_port)

        self.assertEqual(self.received, payload)
        self.assertTrue(self.received_path.endswith(".mp3"))
        self.assertFalse(os.path.exists(self.received_path))

    def test_health_endpoint_identifies_the_service(self):
        connection = http.client.HTTPConnection(
            "127.0.0.1",
            self.server.server_port,
            timeout=2,
        )
        try:
            connection.request("GET", "/health")
            response = connection.getresponse()
            body = response.read()
        finally:
            connection.close()

        self.assertEqual(response.status, 200)
        self.assertIn(b'"service": "m-audio"', body)


if __name__ == "__main__":
    unittest.main()
