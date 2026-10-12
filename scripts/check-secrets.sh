#!/usr/bin/env sh
set -eu

if ! command -v docker >/dev/null 2>&1; then
  echo "Gitleaks: Docker is not installed; skipping the secret scan." >&2
  exit 0
fi

if ! docker info >/dev/null 2>&1; then
  echo "Gitleaks: the Docker daemon is unavailable; skipping the secret scan." >&2
  exit 0
fi

repository_root=$(git rev-parse --show-toplevel)

exec docker run --rm \
  -e GIT_OPTIONAL_LOCKS=0 \
  --mount "type=bind,source=${repository_root},target=/repo,readonly" \
  --workdir /repo \
  ghcr.io/gitleaks/gitleaks:v8.30.1 \
  git --pre-commit --redact --staged --verbose
