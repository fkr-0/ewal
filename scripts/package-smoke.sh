#!/bin/sh
set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
version=$(tr -d '\r\n' < "$project_root/VERSION")
workdir=$(mktemp -d "${TMPDIR:-/tmp}/ewal-package-smoke.XXXXXX")
trap 'rm -rf "$workdir"' EXIT HUP INT TERM

output_dir="$workdir/dist"
extract_dir="$workdir/extract"
archive="$output_dir/ewal-$version.tar"
package_dir="$extract_dir/ewal-$version"

mkdir -p "$output_dir" "$extract_dir"
cd "$project_root"
eldev package --warnings-as-errors --output-dir "$output_dir"

test -f "$archive"
tar -tf "$archive" | grep -q "^ewal-$version/palettes/dark/sexy-material.json$"
tar -tf "$archive" | grep -q "^ewal-$version/LICENSE$"
tar -xf "$archive" -C "$extract_dir"

emacs -Q --batch -L "$package_dir" \
  --eval "(progn
             (require 'ewal)
             (setq ewal-use-built-in-always t
                   ewal-built-in-palette \"sexy-material\"
                   ewal-dark-palette-p t)
             (ewal-load-colors nil t)
             (unless (and (equal ewal-version \"$version\")
                          (file-readable-p
                           (expand-file-name
                            \"palettes/dark/sexy-material.json\"
                            (file-name-directory
                             (locate-library \"ewal\"))))
                          (ewal-color-valid-p
                           (ewal-get-color 'foreground)))
               (kill-emacs 1))
             (princ
              (format \"package=%s version=%s foreground=%s\\n\"
                      \"$archive\" ewal-version
                      (ewal-get-color 'foreground))))"

sha256sum "$archive"
