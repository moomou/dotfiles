m
=

A swiss army knife cli app for everyday use.

`m` is built with _performance_ and _ease_ _of_ _use_ in mind.


Features
==

## Speed

`m` is very fast. Invoking `m` to show the list of command takes ~100ms on 2017 mac book pro (assuming the filesystem cache is warm).

It was originally using `python-fire` but I decided to write a minimal command line parser to reduce the startup latency.


## Ease of Use
Adding a new command to `m` is easy. Simply create a python module starting `m_` and inherit from `Base` class inside `m_base.py`.

Upgrading `m` is also easy. Because it's python, we can simply download the latest script files. This is supported via `m update`

