#!/usr/bin/env bash

set -e

function pack_zig() {
    NAME="$1"
    OUT_DIR="$(realpath "$2")"

    LANG="zig"
    VERSION="0.0.2"

    pushd . >/dev/null
    cd "./languages/$LANG"

    tar --exclude "./.zig-cache" --exclude "./zig-out" -czvf "$OUT_DIR/$NAME-$LANG-v$VERSION.tar.gz" --transform "s,^\.,$NAME-v$VERSION," .

    popd >/dev/null
}

function pack_c() {
    NAME="$1"
    OUT_DIR="$(realpath "$2")"

    LANG="c"
    VERSION="0.0.1"

    pushd . >/dev/null
    cd "./languages/$LANG"

    TEMP="$OUT_DIR/c_temp"
    BUILD_DIR="$TEMP/build_dist"
    PREFIX="$TEMP/prefix"

    mkdir -p "$TEMP"

    meson setup "$BUILD_DIR" -Dbuildtype=release -Ddefault_library=both -Dprefix="/usr"
    meson compile -C "$BUILD_DIR"
    meson install -C "$BUILD_DIR" --destdir="$PREFIX"

    cd "$PREFIX"

    tar -czvf "$OUT_DIR/$NAME-$LANG-v$VERSION.tar.gz" --transform "s,^\.,$NAME-v$VERSION," .

    rm -rf "$TEMP"

    popd >/dev/null
}

function pack() {
    PACKAGE_NAME="terminal_progress"
    OUT_DIR="./dist"

    mkdir -pv "$OUT_DIR"

    pack_zig "$PACKAGE_NAME" "$OUT_DIR"
    pack_c "$PACKAGE_NAME" "$OUT_DIR"
}

pack
