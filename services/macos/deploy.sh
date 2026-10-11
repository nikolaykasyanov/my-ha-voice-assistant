#!/bin/bash
#
# deploy.sh - install LaunchDaemon plists and (re)load them.
#
# Usage: sudo ./deploy.sh [-n] [-f] [plist_dir]
#   -n   dry run: show what would happen, change nothing
#   -f   force: reload even if the installed plist is identical
#   plist_dir defaults to the directory containing this script.
#
# For each *.plist in plist_dir:
#   1. validate it (plutil -lint) and read its Label
#   2. skip it if identical to the installed copy and already loaded (unless -f)
#   3. if the job is loaded: bootout and wait until it is really gone
#   4. install to /Library/LaunchDaemons as root:wheel, mode 644
#   5. bootstrap it into the system domain

set -u

DEST=/Library/LaunchDaemons
BOOTOUT_TIMEOUT=120   # seconds to wait for a job to stop (VMs can be slow)
DRY=0
FORCE=0

while getopts "nf" opt; do
  case $opt in
    n) DRY=1 ;;
    f) FORCE=1 ;;
    *) echo "Usage: sudo $0 [-n] [-f] [plist_dir]" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

SRC="${1:-$(cd "$(dirname "$0")" && pwd)}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo $0 $*" >&2
  exit 1
fi
if [ ! -d "$SRC" ]; then
  echo "Not a directory: $SRC" >&2
  exit 1
fi

run() {
  if [ "$DRY" -eq 1 ]; then echo "   [dry-run] $*"; else "$@"; fi
}

is_loaded() { launchctl print "system/$1" >/dev/null 2>&1; }

wait_until_unloaded() {
  local label=$1 i
  for ((i = 0; i < BOOTOUT_TIMEOUT; i++)); do
    is_loaded "$label" || return 0
    sleep 1
  done
  return 1
}

shopt -s nullglob
files=("$SRC"/*.plist)
if [ ${#files[@]} -eq 0 ]; then
  echo "No .plist files in $SRC"
  exit 0
fi

rc=0
for src in "${files[@]}"; do
  name=$(basename "$src")
  dst="$DEST/$name"
  echo "==> $name"

  if ! plutil -lint -s "$src" >/dev/null 2>&1; then
    echo "   ERROR: invalid plist, skipping" >&2
    rc=1; continue
  fi

  label=$(plutil -extract Label raw -o - "$src" 2>/dev/null)
  if [ -z "$label" ]; then
    echo "   ERROR: no Label key, skipping" >&2
    rc=1; continue
  fi
  if [ "$label.plist" != "$name" ]; then
    echo "   warning: filename does not match Label ($label); using the Label for launchctl"
  fi

  changed=1
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then changed=0; fi

  loaded=0
  if is_loaded "$label"; then loaded=1; fi

  if [ $changed -eq 0 ] && [ $loaded -eq 1 ] && [ $FORCE -eq 0 ]; then
    echo "   unchanged and running, skipping"
    # still make sure ownership/permissions are right
    run chown root:wheel "$dst"
    run chmod 644 "$dst"
    continue
  fi

  if [ $loaded -eq 1 ]; then
    echo "   unloading $label"
    run launchctl bootout "system/$label"
    if [ "$DRY" -eq 0 ] && ! wait_until_unloaded "$label"; then
      echo "   ERROR: $label still loaded after ${BOOTOUT_TIMEOUT}s, skipping" >&2
      rc=1; continue
    fi
  fi

  echo "   installing to $dst"
  run install -o root -g wheel -m 644 "$src" "$dst"

  echo "   loading $label"
  if ! run launchctl bootstrap system "$dst"; then
    echo "   ERROR: bootstrap failed for $label" >&2
    rc=1; continue
  fi
done

echo
if [ $rc -eq 0 ]; then echo "Done."; else echo "Done, with errors." >&2; fi
exit $rc
