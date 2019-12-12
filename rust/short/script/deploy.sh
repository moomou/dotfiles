#!/bin/sh

DIR=$(dirname "$0")

# build latest release
pushd "$DIR/.."

# build the latest binary
echo Building...
cargo build --release --target=x86_64-unknown-linux-musl --bin short
# copy over the binary
echo Copying bin to prod
gcloud compute scp --project ppymou target/x86_64-unknown-linux-musl/release/short mini:~/
# deploy short
echo Restarting service
gcloud compute ssh --project ppymou mini -- '
    sudo mkdir -p /opt/short
    sudo chown $(whoami) /opt/short

    sudo mv ~/short /opt/short
    pkill -SIGINT short || true

    /opt/short/short /opt/short/data.json 80 &
'
echo Done
popd
