#!/usr/bin/env bash

set -eu

this_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
opencode_bin="$this_dir/opencode.real"

if [ ! -x "$opencode_bin" ]; then
    filtered_path=
    while IFS= read -r path_entry; do
        if [ -d "$path_entry" ] && [ "$(cd "$path_entry" && pwd -P)" = "$this_dir" ]; then
            continue
        fi
        filtered_path="${filtered_path:+$filtered_path:}$path_entry"
    done < <(printf '%s' "$PATH" | tr ':' '\n')
    opencode_bin=$(PATH="$filtered_path" command -v opencode || true)
fi

if [ -z "$opencode_bin" ] || [ ! -x "$opencode_bin" ]; then
    printf 'Unable to find the OpenCode executable\n' >&2
    exit 1
fi

export OPENCODE_DISABLE_SHARE=1
export OPENCODE_CONFIG_CONTENT='{"enabled_providers":["moomoutu3"],"experimental":{"openTelemetry":false,"policies":[{"effect":"deny","action":"provider.use","resource":"*"},{"effect":"allow","action":"provider.use","resource":"moomoutu3"}]}}'
unset OPENCODE_AUTO_SHARE
unset OTEL_EXPORTER_OTLP_ENDPOINT
unset OTEL_EXPORTER_OTLP_HEADERS
unset OTEL_RESOURCE_ATTRIBUTES
export OTEL_SDK_DISABLED=true

exec "$opencode_bin" "$@"
