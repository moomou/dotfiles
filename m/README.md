m
=

A swiss army knife cli app for everyday use.

`m` is built with _performance_ and _ease_ _of_ _use_ in mind.


Features
==

## Speed

`m` is very fast. Invoking `m` to show the list of command takes ~100ms on 2017 mac book pro (assuming the filesystem cache is warm).

It was originally using `python-fire` but I decided to write a minimal command line parser to reduce the startup latency.

The launcher only installs its small shared logging dependency. `uv` resolves
larger dependencies on demand for the command groups that use them, so core
commands do not install the audio, scientific, web, or storage stacks.


## Ease of Use
Adding a new command to `m` is easy. Simply create a python module starting `m_` and inherit from `Base` class inside `m_base.py`.

Upgrading `m` is also easy. Because it's python, we can simply download the latest script files. This is supported via `m update`


Remote audio over Tailscale
==

Start the audio server on the Mac:

```sh
m a.server
```

Then send an audio file from another machine on the same Tailnet:

```sh
m a.play path/to/audio.mp3
```

The client finds a single running audio server among the online peers reported by
`tailscale status --json`. To skip discovery, set the Mac's MagicDNS hostname or
pass it directly:

```sh
export M_AUDIO_HOST=my-mac
m a.play path/to/audio.mp3
m a.play path/to/audio.mp3 --host my-mac
```

Both commands use port `47321` by default. Override it with `M_AUDIO_PORT` or
`--port`. The server listens on all IPv4 interfaces but rejects requests that do
not come from a Tailscale or loopback address. It streams each upload to a
temporary file, plays it with `afplay`, and removes it afterward.
