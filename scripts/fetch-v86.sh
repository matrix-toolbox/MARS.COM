#!/usr/bin/env bash
# Downloads a pinned v86 release plus the BIOS blobs it needs.
#
# This runs at BUILD time, never at page-view time — the deployed site serves
# everything from its own origin, so it depends on no CDN once published.
#
# v86's npm package ships only the runtime (libv86.js + v86.wasm); the BIOS
# images live in the GitHub repo, so they are fetched separately.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

need npm
need tar
need curl

dest="$BUILD_DIR/v86"
work="$BUILD_DIR/.v86-download"

if [ -f "$dest/libv86.js" ] && [ -f "$dest/bios/seabios.bin" ] && [ "${FORCE_FETCH:-0}" != "1" ]; then
  log "v86 $V86_VERSION already present in $dest (set FORCE_FETCH=1 to refetch)"
  exit 0
fi

rm -rf "$work" "$dest"
mkdir -p "$work" "$dest/bios"

log "Fetching v86 $V86_VERSION from npm"
( cd "$work" && npm pack "v86@$V86_VERSION" >/dev/null ) \
  || die "npm pack failed for v86@$V86_VERSION"

tarball="$work/v86-$V86_VERSION.tgz"
[ -f "$tarball" ] || die "expected tarball $tarball was not produced"
verify_sha "$tarball" "$V86_TARBALL_SHA256" "v86 npm tarball"

tar xzf "$tarball" -C "$work" \
  package/build/libv86.js \
  package/build/v86.wasm \
  || die "v86 tarball did not contain the expected build layout"

cp "$work/package/build/libv86.js" "$dest/libv86.js"
cp "$work/package/build/v86.wasm"  "$dest/v86.wasm"

# SeaBIOS and the VGA BIOS are not in the npm package.
log "Fetching BIOS blobs from $V86_BIOS_REPO@$V86_BIOS_REF"
fetch_bios() {
  local blob="$1" expected="$2"
  curl -sSfL --max-time 120 \
    "https://raw.githubusercontent.com/$V86_BIOS_REPO/$V86_BIOS_REF/bios/$blob" \
    -o "$dest/bios/$blob" \
    || die "could not fetch bios/$blob"
  [ -s "$dest/bios/$blob" ] || die "bios/$blob came back empty"
  verify_sha "$dest/bios/$blob" "$expected" "bios/$blob"
}

fetch_bios seabios.bin "$V86_SEABIOS_SHA256"
fetch_bios vgabios.bin "$V86_VGABIOS_SHA256"

rm -rf "$work"

log "v86 $V86_VERSION staged in $dest ($(du -sh "$dest" | cut -f1))"
