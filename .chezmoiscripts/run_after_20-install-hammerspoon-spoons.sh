#!/bin/sh
# Ensures the required Hammerspoon Spoons are installed. Runs on every apply.
# Silent when every Spoon is present. Prints what it repairs.
# A failed download prints a warning and does not stop `chezmoi apply`.
# To update a Spoon, delete its folder and run `chezmoi apply`.
set -u

SPOONS_DIR="${HOME}/.hammerspoon/Spoons"
TMP_DIR=""

say() { printf 'hammerspoon: %s\n' "$*"; }
warn() { printf 'hammerspoon: WARNING: %s\n' "$*" >&2; }
cleanup() { [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR"; }
trap cleanup EXIT HUP INT TERM

# Returns 0 when nothing needs to be done, and prints the reason otherwise.
spoon_needs_install() {
    dir="${SPOONS_DIR}/$1.spoon"
    if [ -f "${dir}/init.lua" ]; then
        return 1
    fi
    if [ -d "$dir" ]; then
        say "$1.spoon exists but has no init.lua (incomplete or damaged). Reinstalling."
    else
        say "$1.spoon is not installed (first run, or it was deleted). Installing."
    fi
    return 0
}

download_spoon() {
    name="$1"; url="$2"; archive="${TMP_DIR}/${name}.spoon.zip"; extract_dir="${TMP_DIR}/${name}"
    curl --fail --location --silent --show-error --retry 3 --retry-delay 1 \
        --output "$archive" "$url" || { warn "download failed: $url"; return 1; }
    [ -s "$archive" ] || { warn "downloaded archive is empty: $url"; return 1; }
    unzip -tq "$archive" >/dev/null 2>&1 || { warn "not a valid ZIP archive: $url"; return 1; }
    mkdir -p "$extract_dir" && unzip -q -o "$archive" -d "$extract_dir" || { warn "unzip failed: $archive"; return 1; }
    [ -f "${extract_dir}/${name}.spoon/init.lua" ] || { warn "archive has no ${name}.spoon/init.lua: $url"; return 1; }
}

install_spoon() {
    name="$1"; url="$2"
    spoon_needs_install "$name" || return 0
    [ -n "$TMP_DIR" ] || TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-hammerspoon-spoons.XXXXXX")"
    if ! download_spoon "$name" "$url"; then
        warn "${name}.spoon was not installed. Hammerspoon features that use it will fail. Rerun 'chezmoi apply' when online."
        return 0
    fi
    # Replace the destination only after download and validation succeed.
    mkdir -p "$SPOONS_DIR"
    rm -rf "${SPOONS_DIR}/${name}.spoon"
    mv "${TMP_DIR}/${name}/${name}.spoon" "${SPOONS_DIR}/${name}.spoon"
    say "installed ${SPOONS_DIR}/${name}.spoon"
}

install_spoon \
    "RecursiveBinder" \
    "https://raw.githubusercontent.com/Hammerspoon/Spoons/master/Spoons/RecursiveBinder.spoon.zip"
