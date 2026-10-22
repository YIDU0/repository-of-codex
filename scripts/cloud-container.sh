#!/usr/bin/env bash
set -euo pipefail
_worktime_container_repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$_worktime_container_repo"
source scripts/env.sh
_worktime_docker=(env -u DOCKER_HOST -u DOCKER_CONTEXT -u DOCKER_TLS -u DOCKER_TLS_VERIFY -u DOCKER_CERT_PATH docker --host=unix:///var/run/docker.sock)
_worktime_image=worktime-toolchain:stage1
if [[ "${1:-}" == build ]]; then
  "${_worktime_docker[@]}" build --secret id=system_ca,src=/etc/ssl/certs/ca-certificates.crt \
    -t "$_worktime_image" -f tool/docker/Dockerfile .
  exit
fi
_worktime_mounts=(
  --mount "type=bind,src=$_worktime_container_repo,dst=/workspace/repository-of-codex"
  --mount "type=bind,src=$WORKTIME_TOOLCHAINS,dst=/workspace/.toolchains"
  --mount type=bind,src=/etc/ssl/certs/ca-certificates.crt,dst=/run/system-ca.pem,readonly
  --mount type=bind,src=/etc/ssl/certs/ca-certificates.crt,dst=/etc/ssl/certs/ca-certificates.crt,readonly
)
for _worktime_state in android dart-tool dartServer; do
  mkdir -p "$WORKTIME_TOOLCHAINS/container-state/$_worktime_state"
  _worktime_mounts+=(--mount "type=bind,src=$WORKTIME_TOOLCHAINS/container-state/$_worktime_state,dst=/home/builder/.$_worktime_state")
done
if [[ -n "${CODEX_PROXY_CERT:-}" && -f "$CODEX_PROXY_CERT" ]]; then
  _worktime_mounts+=(--mount "type=bind,src=$CODEX_PROXY_CERT,dst=/run/proxy-ca.pem,readonly")
fi
exec "${_worktime_docker[@]}" run --rm --init --cpus=4 --memory=8g --shm-size=1g \
  "${_worktime_mounts[@]}" "$_worktime_image" "$@"
