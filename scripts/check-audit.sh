#!/usr/bin/env sh
set -eu

if ! command -v docker >/dev/null 2>&1; then
  echo "OSV-Scanner: Docker is not installed; skipping the dependency vulnerability scan." >&2
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "OSV-Scanner: the Docker daemon is unavailable; skipping the dependency vulnerability scan." >&2
  exit 0
fi

repository_root=$(git rev-parse --show-toplevel)

exec docker run --rm \
  --mount "type=bind,source=${repository_root},target=/src,readonly" \
  --workdir /src \
  ghcr.io/google/osv-scanner:v2.7.0 \
  scan source --lockfile /src/pnpm-lock.yaml
