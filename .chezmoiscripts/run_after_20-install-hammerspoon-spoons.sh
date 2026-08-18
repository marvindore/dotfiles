#!/bin/sh
# Ensure required Hammerspoon Spoons are installed.
#
# Suggested chezmoi source-state filename:
#
#   .chezmoiscripts/run_after_20-install-hammerspoon-spoons.sh
#
# The run_after_ prefix makes this run after chezmoi has applied the
# remaining managed files.

set -eu

SPOONS_DIR="${HOME}/.hammerspoon/Spoons"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-hammerspoon-spoons.XXXXXX")"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT HUP INT TERM

mkdir -p "$SPOONS_DIR"

install_spoon() {
    spoon_name="$1"
    spoon_url="$2"

    archive_path="${TMP_DIR}/${spoon_name}.spoon.zip"
    extract_dir="${TMP_DIR}/${spoon_name}"
    extracted_spoon="${extract_dir}/${spoon_name}.spoon"
    destination="${SPOONS_DIR}/${spoon_name}.spoon"

    printf 'Installing Hammerspoon Spoon: %s\n' "$spoon_name"

    mkdir -p "$extract_dir"

    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --retry 3 \
        --retry-delay 1 \
        --output "$archive_path" \
        "$spoon_url"

    if [ ! -s "$archive_path" ]; then
        printf 'Error: downloaded archive is empty: %s\n' "$archive_path" >&2
        return 1
    fi

    if ! unzip -tq "$archive_path" >/dev/null 2>&1; then
        printf 'Error: downloaded file is not a valid ZIP archive: %s\n' "$spoon_url" >&2
        return 1
    fi

    unzip -q -o "$archive_path" -d "$extract_dir"

    if [ ! -d "$extracted_spoon" ]; then
        printf 'Error: archive did not contain %s.spoon\n' "$spoon_name" >&2
        return 1
    fi

    if [ ! -f "${extracted_spoon}/init.lua" ]; then
        printf 'Error: %s.spoon does not contain init.lua\n' "$spoon_name" >&2
        return 1
    fi

    # Replace the destination only after download and validation succeed.
    rm -rf "$destination"
    mv "$extracted_spoon" "$destination"

    printf 'Installed: %s\n' "$destination"
}

install_spoon \
    "RecursiveBinder" \
    "https://raw.githubusercontent.com/Hammerspoon/Spoons/master/Spoons/RecursiveBinder.spoon.zip"
