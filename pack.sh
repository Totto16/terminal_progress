#!/usr/bin/env bash

set -e

function pack_zig() {
    NAME="$1"
    OUT_DIR="$2"
    LANG="zig"
    tar --exclude "./.zig-cache" --exclude "./zig-out" -czvf "$OUT_DIR/$NAME-$LANG.tar.gz" -C "./languages/$LANG" .
}

function pack() {
    PACKAGE_NAME="terminal_progress"
    OUT_DIR="./dist"

    mkdir -pv "$OUT_DIR"

    pack_zig "$PACKAGE_NAME" "$OUT_DIR"
}

pack
