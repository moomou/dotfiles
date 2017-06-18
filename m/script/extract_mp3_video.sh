#!/bin/bash
find . -type f -name "$1" -exec bash -c 'FILE="$1"; ffmpeg -i "${FILE}" -vn -c:a libmp3lame -y "$2${FILE%.mkv}.mp3";' _ '{}' \;
