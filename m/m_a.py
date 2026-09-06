import concurrent.futures
import http.client
import ipaddress
import json
import logging
import os
import pathlib
import re
import shutil
import socket
import subprocess
import tempfile
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import quote, unquote

import m_base


DEFAULT_PORT = 47321
DEFAULT_MAX_MB = 512
CHUNK_SIZE = 1024 * 1024
DISCOVERY_TIMEOUT_SECONDS = 0.5
TAILSCALE_NETWORKS = (
    ipaddress.ip_network("100.64.0.0/10"),
    ipaddress.ip_network("fd7a:115c:a1e0::/48"),
)


def _to_bool(value):
    if isinstance(value, bool):
        return value
    if value is None:
        return False
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _to_int(value, name, *, minimum, maximum):
    if isinstance(value, bool):
        raise ValueError(f"{name} must be an integer")
    try:
        parsed = int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{name} must be an integer") from exc
    if not minimum <= parsed <= maximum:
        raise ValueError(f"{name} must be between {minimum} and {maximum}")
    return parsed


def _port(value=None):
    value = value if value is not None else os.environ.get("M_AUDIO_PORT", DEFAULT_PORT)
    return _to_int(value, "port", minimum=1, maximum=65535)


def _is_tailnet_address(address):
    try:
        ip = ipaddress.ip_address(address)
    except ValueError:
        return False
    return ip.is_loopback or any(ip in network for network in TAILSCALE_NETWORKS)


def _safe_suffix(filename):
    suffix = pathlib.Path(filename).suffix
    if re.fullmatch(r"\.[A-Za-z0-9]{1,10}", suffix):
        return suffix.lower()
    return ".audio"


def _copy_exact(source, destination, size):
    remaining = size
    while remaining:
        chunk = source.read(min(CHUNK_SIZE, remaining))
        if not chunk:
            raise EOFError(f"request ended with {remaining} bytes missing")
        destination.write(chunk)
        remaining -= len(chunk)


def _handler_class(play_audio, *, max_bytes, allow_any_client, logger):
    class AudioRequestHandler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.0"
        server_version = "m-audio/1"

        def _send_json(self, status, payload):
            body = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(body)

        def _is_allowed(self):
            return allow_any_client or _is_tailnet_address(self.client_address[0])

        def _reject_untrusted_client(self):
            if self._is_allowed():
                return False
            logger.warning("Rejected non-Tailscale client %s", self.client_address[0])
            self._send_json(HTTPStatus.FORBIDDEN, {"error": "Tailscale client required"})
            return True

        def do_GET(self):
            if self._reject_untrusted_client():
                return
            if self.path != "/health":
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})
                return
            self._send_json(HTTPStatus.OK, {"service": "m-audio", "version": 1})

        def do_POST(self):
            if self._reject_untrusted_client():
                return
            if self.path != "/play":
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "not found"})
                return

            raw_size = self.headers.get("Content-Length")
            try:
                size = _to_int(
                    raw_size,
                    "Content-Length",
                    minimum=1,
                    maximum=max_bytes,
                )
            except ValueError as exc:
                self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})
                return

            filename = unquote(self.headers.get("X-M-Audio-Filename", "audio"))
            temp_path = None
            try:
                with tempfile.NamedTemporaryFile(
                    prefix="m-audio-",
                    suffix=_safe_suffix(filename),
                    delete=False,
                ) as audio_file:
                    temp_path = audio_file.name
                    _copy_exact(self.rfile, audio_file, size)

                logger.info(
                    "Playing %s (%d bytes) from %s",
                    filename,
                    size,
                    self.client_address[0],
                )
                play_audio(temp_path)
            except EOFError as exc:
                logger.warning(
                    "Incomplete audio upload from %s: %s",
                    self.client_address[0],
                    exc,
                )
                self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(exc)})
                return
            except subprocess.CalledProcessError as exc:
                logger.error("Audio player exited with status %s", exc.returncode)
                self._send_json(
                    HTTPStatus.INTERNAL_SERVER_ERROR,
                    {"error": f"audio player exited with status {exc.returncode}"},
                )
                return
            except OSError as exc:
                logger.error("Unable to receive or play audio: %s", exc)
                self._send_json(
                    HTTPStatus.INTERNAL_SERVER_ERROR,
                    {"error": "unable to receive or play audio"},
                )
                return
            finally:
                if temp_path:
                    try:
                        os.unlink(temp_path)
                    except FileNotFoundError:
                        pass

            self._send_json(HTTPStatus.OK, {"status": "played", "filename": filename})

        def log_message(self, message, *args):
            logger.debug("%s - %s", self.client_address[0], message % args)

    return AudioRequestHandler


class _AudioHTTPServer(HTTPServer):
    allow_reuse_address = True


def _tailscale_binary():
    executable = shutil.which("tailscale")
    if executable:
        return executable

    macos_app_binary = "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    if os.path.isfile(macos_app_binary) and os.access(macos_app_binary, os.X_OK):
        return macos_app_binary
    return None


def _tailscale_status():
    executable = _tailscale_binary()
    if not executable:
        raise RuntimeError("tailscale CLI not found")

    try:
        result = subprocess.run(
            [executable, "status", "--json"],
            check=True,
            capture_output=True,
            text=True,
            timeout=10,
        )
    except subprocess.CalledProcessError as exc:
        detail = exc.stderr.strip() or f"exit status {exc.returncode}"
        raise RuntimeError(f"tailscale status failed: {detail}") from exc
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError("tailscale status timed out") from exc

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError("tailscale status returned invalid JSON") from exc


def _tailnet_peer_hosts(status):
    peers = status.get("Peer") or {}
    if isinstance(peers, dict):
        peers = peers.values()

    hosts = []
    for peer in peers:
        if not isinstance(peer, dict) or not peer.get("Online"):
            continue
        host = (peer.get("DNSName") or peer.get("HostName") or "").rstrip(".")
        if host and host not in hosts:
            hosts.append(host)
    return hosts


def _probe_server(host, port):
    connection = http.client.HTTPConnection(
        host,
        port,
        timeout=DISCOVERY_TIMEOUT_SECONDS,
    )
    try:
        connection.request("GET", "/health", headers={"Connection": "close"})
        response = connection.getresponse()
        payload = json.loads(response.read(4096))
        return response.status == HTTPStatus.OK and payload.get("service") == "m-audio"
    except (OSError, http.client.HTTPException, json.JSONDecodeError):
        return False
    finally:
        connection.close()


def _discover_host(port):
    peers = _tailnet_peer_hosts(_tailscale_status())
    if not peers:
        raise RuntimeError("no online Tailscale peers found")

    worker_count = min(4, len(peers))
    with concurrent.futures.ThreadPoolExecutor(max_workers=worker_count) as executor:
        probes = {executor.submit(_probe_server, host, port): host for host in peers}
        matches = sorted(
            host for future, host in probes.items() if future.result()
        )

    if not matches:
        raise RuntimeError(
            "no m audio server found; start `m a.server` on the Mac or set M_AUDIO_HOST"
        )
    if len(matches) > 1:
        raise RuntimeError(
            "multiple audio servers found; select one with --host: "
            + ", ".join(matches)
        )
    return matches[0]


def _resolve_host(host, port):
    configured = host if host is not None else os.environ.get("M_AUDIO_HOST")
    if configured is not None:
        if isinstance(configured, bool) or not str(configured).strip():
            raise ValueError("host must be a non-empty Tailscale hostname")
        configured = str(configured).strip().rstrip(".")
        if "://" in configured or "/" in configured:
            raise ValueError("host must be a hostname, not a URL")
        return configured
    return _discover_host(port)


def _string_arg(value, name):
    if isinstance(value, bool) or not str(value).strip():
        raise ValueError(f"{name} must be a non-empty string")
    return str(value).strip()


def _send_audio(path, host, port):
    size = path.stat().st_size
    if size < 1:
        raise ValueError(f"audio file is empty: {path}")

    connection = http.client.HTTPConnection(host, port, timeout=30)
    try:
        connection.connect()
        connection.putrequest("POST", "/play")
        connection.putheader("Content-Type", "application/octet-stream")
        connection.putheader("Content-Length", str(size))
        connection.putheader("X-M-Audio-Filename", quote(path.name, safe=""))
        connection.putheader("Connection", "close")
        connection.endheaders()

        remaining = size
        with path.open("rb") as audio_file:
            while remaining:
                chunk = audio_file.read(min(CHUNK_SIZE, remaining))
                if not chunk:
                    raise OSError(f"audio file changed while reading: {path}")
                connection.send(chunk)
                remaining -= len(chunk)

        if connection.sock:
            connection.sock.settimeout(None)
        response = connection.getresponse()
        body = response.read()
    finally:
        connection.close()

    if response.status != HTTPStatus.OK:
        try:
            detail = json.loads(body).get("error")
        except (json.JSONDecodeError, AttributeError):
            detail = body.decode("utf-8", errors="replace").strip()
        raise RuntimeError(
            f"audio server returned {response.status}: {detail or response.reason}"
        )


class A(m_base.Base):
    def play(self, audio_file, host=None, port=None):
        """Send an audio file to a Mac running `m a.server`."""
        path = pathlib.Path(audio_file).expanduser()
        if not path.is_file():
            self._logger.fatal("Audio file not found: %s", path)

        try:
            server_port = _port(port)
            server_host = _resolve_host(host, server_port)
            self._logger.info(
                "Sending %s to %s:%d",
                path,
                server_host,
                server_port,
            )
            _send_audio(path, server_host, server_port)
        except (OSError, RuntimeError, ValueError, socket.timeout) as exc:
            self._logger.fatal("Unable to play %s: %s", path, exc)

        self._logger.info("Playback completed on %s", server_host)

    def server(
        self,
        bind=None,
        port=None,
        max_mb=None,
        allow_any_client=None,
        player=None,
    ):
        """Listen for audio files and play them with macOS afplay."""
        try:
            server_port = _port(port)
            max_mb = _to_int(
                max_mb if max_mb is not None else DEFAULT_MAX_MB,
                "max_mb",
                minimum=1,
                maximum=10240,
            )
        except ValueError as exc:
            self._logger.fatal("Invalid server configuration: %s", exc)

        try:
            bind = _string_arg(
                bind if bind is not None else os.environ.get("M_AUDIO_BIND", "0.0.0.0"),
                "bind",
            )
            player = _string_arg(
                player
                if player is not None
                else os.environ.get("M_AUDIO_PLAYER", "afplay"),
                "player",
            )
        except ValueError as exc:
            self._logger.fatal("Invalid server configuration: %s", exc)

        player_path = shutil.which(player)
        if not player_path:
            self._logger.fatal("Audio player not found: %s", player)

        if allow_any_client is None:
            allow_any_client = os.environ.get("M_AUDIO_ALLOW_ANY_CLIENT")
        allow_any_client = _to_bool(allow_any_client)

        def play_audio(path):
            subprocess.run([player_path, path], check=True)

        handler = _handler_class(
            play_audio,
            max_bytes=max_mb * 1024 * 1024,
            allow_any_client=allow_any_client,
            logger=self._logger,
        )

        try:
            server = _AudioHTTPServer((bind, server_port), handler)
        except OSError as exc:
            self._logger.fatal(
                "Unable to listen on %s:%d: %s",
                bind,
                server_port,
                exc,
            )

        access = "any client" if allow_any_client else "Tailscale clients only"
        self._logger.info(
            "Audio server listening on %s:%d (%s)",
            bind,
            server_port,
            access,
        )
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            self._logger.info("Audio server stopped")
        finally:
            server.server_close()
