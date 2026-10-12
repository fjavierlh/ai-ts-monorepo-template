#!/usr/bin/env sh
set -eu

repository_root=$(git rev-parse --show-toplevel)
cd "$repository_root"

reports_dir="${repository_root}/reports"
mkdir -p "$reports_dir"

rm -f \
  "${reports_dir}/eslint.json" \
  "${reports_dir}/knip.json" \
  "${reports_dir}/spectral.json"

pnpm exec eslint . \
  --format json \
  --output-file "${reports_dir}/eslint.json" || true

pnpm exec knip \
  --no-progress \
  --reporter json > "${reports_dir}/knip.json" || true

pnpm exec spectral lint \
  --format json \
  --output "${reports_dir}/spectral.json" \
  packages/commons/openapi.yaml || true

exec pnpm check
