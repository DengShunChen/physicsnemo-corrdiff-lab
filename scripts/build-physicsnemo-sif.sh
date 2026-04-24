#!/usr/bin/env bash
# 從 NGC 拉 PhysicsNeMo 官方映像並建成本機 .sif（Apptainer / Singularity）。
# 等同你原本的 build_physicsNeMo.sh，路徑預設對齊本 repo 根目錄下的 tmp/。
#
# 參考映像：
#   https://catalog.ngc.nvidia.com/orgs/nvidia/teams/physicsnemo/containers/physicsnemo
#
# 用法:
#   ./scripts/build-physicsnemo-sif.sh
#   PHYSICSNEMO_TAG=25.06 ./scripts/build-physicsnemo-sif.sh
#   OUTPUT_SIF=./my.sif ./scripts/build-physicsnemo-sif.sh
#
# 環境變數（皆可選）:
#   PHYSICSNEMO_TAG   映像 tag，預設 25.11
#   OUTPUT_SIF        輸出檔路徑，預設 <repo 根>/physicsnemo_<tag>.sif
#   TEMP_BUILD_DIR    建置暫存（需大空間），預設 <repo 根>/tmp/singularity_build
#   CACHE_DIR         layer 快取，預設 <repo 根>/tmp/singularity_cache
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

PHYSICSNEMO_TAG="${PHYSICSNEMO_TAG:-25.11}"
OUTPUT_SIF="${OUTPUT_SIF:-$REPO_ROOT/physicsnemo_${PHYSICSNEMO_TAG}.sif}"
TEMP_BUILD_DIR="${TEMP_BUILD_DIR:-$REPO_ROOT/tmp/singularity_build}"
CACHE_DIR="${CACHE_DIR:-$REPO_ROOT/tmp/singularity_cache}"

DOCKER_REF="docker://nvcr.io/nvidia/physicsnemo/physicsnemo:${PHYSICSNEMO_TAG}"

cmd_build() {
  if command -v apptainer >/dev/null 2>&1; then
    apptainer build "$@"
  elif command -v singularity >/dev/null 2>&1; then
    singularity build "$@"
  else
    echo "error: 找不到 apptainer 或 singularity，請先載入對應 module 或安裝。" >&2
    exit 1
  fi
}

echo "==> TEMP_BUILD_DIR=$TEMP_BUILD_DIR"
echo "==> CACHE_DIR=$CACHE_DIR"
echo "==> OUTPUT_SIF=$OUTPUT_SIF"
echo "==> FROM $DOCKER_REF"

mkdir -p "$TEMP_BUILD_DIR" "$CACHE_DIR"

export SINGULARITY_TMPDIR="$TEMP_BUILD_DIR"
export APPTAINER_TMPDIR="$TEMP_BUILD_DIR"
export SINGULARITY_CACHEDIR="$CACHE_DIR"
export APPTAINER_CACHEDIR="$CACHE_DIR"

cmd_build "$OUTPUT_SIF" "$DOCKER_REF"

echo "==> 完成: $OUTPUT_SIF"
