#!/usr/bin/env bash
# Builds the site and serves it over HTTP.
#
# HTTP rather than file:// is required: js-dos loads mars.jsdos with fetch(),
# and browsers block fetch on file:// origins.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

port="${PORT:-8080}"

bash "$REPO_ROOT/scripts/build-site.sh"

need python3
log "Serving $SITE_OUT at http://localhost:$port  (Ctrl-C to stop)"
cd "$SITE_OUT"
exec python3 -m http.server "$port"
