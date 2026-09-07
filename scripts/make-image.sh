#!/usr/bin/env bash
# Builds the bootable floppy image that v86 boots.
#
# Starts from the FreeDOS 720 KB boot floppy used by v86's own demos, then
# injects three things with mtools:
#
#   MARS.COM      the program itself
#   CTMOUSE.EXE   a resident int 33h mouse driver — DOSBox provided this
#                 service internally, real hardware emulation does not
#   AUTOEXEC.BAT  loads the driver, then runs MARS
#
# Both downloads are checksum-pinned, so a rebuild years from now either
# produces the same image or fails loudly rather than drifting.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

need curl
need unzip
command -v mcopy >/dev/null 2>&1 \
  || die "mtools not found — install it with 'brew install mtools' or 'apt-get install mtools'"

# mtools is strict about geometry on these vintage images; this is expected.
export MTOOLS_SKIP_CHECK=1

work="$BUILD_DIR/.image-work"
out="$BUILD_DIR/mars.img"

com="$BUILD_DIR/MARS.COM"
[ -f "$com" ] || die "$com not found — run scripts/build.sh first"

rm -rf "$work"
mkdir -p "$work"

# --- FreeDOS boot floppy -------------------------------------------------
log "Fetching the FreeDOS boot floppy"
curl -sSfL --max-time 180 "$FREEDOS_IMG_URL" -o "$work/freedos.img" \
  || die "could not download $FREEDOS_IMG_URL"
verify_sha "$work/freedos.img" "$FREEDOS_IMG_SHA256" "FreeDOS image"

# --- CuteMouse -----------------------------------------------------------
log "Fetching the CuteMouse driver"
curl -sSfL --max-time 180 "$CTMOUSE_URL" -o "$work/ctmouse.zip" \
  || die "could not download $CTMOUSE_URL"
verify_sha "$work/ctmouse.zip" "$CTMOUSE_ZIP_SHA256" "CuteMouse archive"

unzip -o -q "$work/ctmouse.zip" -d "$work/ctmouse" \
  || die "could not unpack the CuteMouse archive"
ctmouse="$work/ctmouse/CTMOUSE.EXE"
[ -f "$ctmouse" ] || die "CTMOUSE.EXE not found in the CuteMouse archive"

# --- compose the image ---------------------------------------------------
cp "$work/freedos.img" "$out"

# The stock image ships demo programs that crowd a 720 KB floppy. Drop the
# large ones so there is comfortable room, and so the boot is not cluttered.
for junk in ::/VIM.EXE ::/NASM.EXE ::/DEBUG.COM ::/PRIMES.EXE ::/X86TEST.ASM \
            ::/HELLO.ASM ::/CLOCK.COM ::/CAL.COM ::/FOO ::/README; do
  mdel -i "$out" "$junk" >/dev/null 2>&1 || true
done

cat > "$work/AUTOEXEC.BAT" <<'EOF'
@ECHO OFF
CTMOUSE.EXE
MARS.COM
EOF
# DOS expects CRLF line endings in batch files.
awk 'BEGIN{RS="\n";ORS="\r\n"} {print}' "$work/AUTOEXEC.BAT" > "$work/AUTOEXEC.CRLF"
mv "$work/AUTOEXEC.CRLF" "$work/AUTOEXEC.BAT"

mcopy -i "$out" -o "$com"                  ::/MARS.COM     || die "could not copy MARS.COM into the image"
mcopy -i "$out" -o "$ctmouse"              ::/CTMOUSE.EXE  || die "could not copy CTMOUSE.EXE into the image"
mcopy -i "$out" -o "$work/AUTOEXEC.BAT"    ::/AUTOEXEC.BAT || die "could not write AUTOEXEC.BAT into the image"

rm -rf "$work"

log "Built $out ($(wc -c < "$out" | tr -d ' ') bytes)"
mdir -i "$out" ::/ 2>/dev/null | grep -iE "MARS|CTMOUSE|AUTOEXEC|bytes free" >&2 || true
