#!/usr/bin/env bash
# Run as gfdad after uploading a complete prebuilt static artifact into releases/ID.
set -euo pipefail
[[ $(id -un) == gfdad ]] || { echo 'Run as gfdad' >&2; exit 1; }
release=${1:?Usage: gfdad-deploy-static RELEASE_ID}
[[ $release =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || exit 1
base=/var/www/gfdad
path="$base/releases/$release"
[[ -d $path && ! -L $path && -f $path/index.html ]] || { echo 'Missing release/index.html' >&2; exit 1; }
# Never publish hidden files (including .env/.git), symlinks or special files.
if find "$path" -mindepth 1 \( -name '.*' -o -type l -o \( ! -type f ! -type d \) \) -print -quit | grep -q .; then
    echo 'Artifact contains hidden files, links or special files; refusing deployment' >&2; exit 1
fi
find "$path" -type d -exec chmod 755 {} +
find "$path" -type f -exec chmod 644 {} +
tmp="$base/.current-$$"
trap 'rm -f "$tmp"' EXIT
ln -s "releases/$release" "$tmp"
mv -Tf "$tmp" "$base/current"
echo "Activated $release"
