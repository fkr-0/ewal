#!/bin/sh
set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
image=${EWAL_CORE_COMPAT_IMAGE:-silex/emacs@sha256:360944881ba217966447d3e5f9c9b4521d656db74c7dc885e869d35a7e92e120}
workdir=$(mktemp -d "${TMPDIR:-/tmp}/ewal-core-compat.XXXXXX")
source_dir="$workdir/source"
trap 'rm -rf "$workdir"' EXIT HUP INT TERM

case "$image" in
  *@sha256:????????????????????????????????????????????????????????????????) ;;
  *)
    echo "EWAL_CORE_COMPAT_IMAGE must use an immutable sha256 digest" >&2
    exit 2
    ;;
esac

command -v docker >/dev/null 2>&1 || {
  echo "Docker is required for the Emacs 25.1 compatibility gate" >&2
  exit 2
}

mkdir -p "$source_dir"
tar -C "$project_root" \
  --exclude=.git \
  --exclude=.eldev \
  --exclude=.ws-bridge \
  --exclude=dist \
  --exclude='*.elc' \
  -cf - . | tar -C "$source_dir" -xf -

if ! docker image inspect "$image" >/dev/null 2>&1; then
  docker pull "$image" >/dev/null
fi

docker run --rm \
  --network none \
  --entrypoint emacs \
  --env HOME=/tmp/ewal-home \
  --volume "$source_dir:/workspace" \
  --workdir /workspace \
  "$image" \
  -Q --batch -L . -l scripts/core-compat.el
