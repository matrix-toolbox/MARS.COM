#!/usr/bin/env bash
# Composes the deployable site from the bootable image, the v86 runtime and
# the static page sources.
#
# Everything the browser loads is copied into _site/, so the deployed page
# makes no third-party requests at view time.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

log "Building MARS.COM"
bash "$REPO_ROOT/scripts/build.sh"

log "Building the bootable floppy image"
bash "$REPO_ROOT/scripts/make-image.sh"

log "Fetching v86 $V86_VERSION"
bash "$REPO_ROOT/scripts/fetch-v86.sh"

log "Composing $SITE_OUT"
rm -rf "$SITE_OUT"
mkdir -p "$SITE_OUT"

cp "$REPO_ROOT/site/index.html"  "$SITE_OUT/index.html"
cp "$REPO_ROOT/site/style.css"   "$SITE_OUT/style.css"
cp "$REPO_ROOT/site/favicon.svg" "$SITE_OUT/favicon.svg"
cp "$BUILD_DIR/mars.img"         "$SITE_OUT/mars.img"
cp "$BUILD_DIR/MARS.COM"         "$SITE_OUT/MARS.COM"
cp "$REPO_ROOT/MARS.ASM"         "$SITE_OUT/MARS.ASM"
cp "$REPO_ROOT/mars_4_3.png"     "$SITE_OUT/mars_4_3.png"
cp -R "$BUILD_DIR/v86"           "$SITE_OUT/v86"

# GitHub Pages runs Jekyll by default, which strips paths beginning with a
# dot and can mangle asset directories. .nojekyll turns that off.
touch "$SITE_OUT/.nojekyll"

log "Site ready in $SITE_OUT ($(du -sh "$SITE_OUT" | cut -f1))"
