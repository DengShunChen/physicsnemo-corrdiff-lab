#!/usr/bin/env bash
# 以 uv 從本 repo 的 physicsnemo 子目錄（或自訂路徑）安裝 NVIDIA PhysicsNeMo。
# 上游文件：https://github.com/NVIDIA/physicsnemo
#
# 用法範例：
#   ./scripts/install-physicsnemo-uv.sh                    # 等同 cu12，無額外 extra
#   ./scripts/install-physicsnemo-uv.sh cu13
#   ./scripts/install-physicsnemo-uv.sh --extra nn-extras   # 預設仍為 cu12 + nn-extras
#   ./scripts/install-physicsnemo-uv.sh none --extra nn-extras
#   PHYSICSNEMO_DIR=/path/to/physicsnemo ./scripts/install-physicsnemo-uv.sh none
#
# 環境變數：
#   PHYSICSNEMO_DIR  — physicsnemo 專案根目錄（需含 pyproject.toml），預設為本腳本上一層的 ./physicsnemo
#   UV_VERSION       — 若本機沒有 uv，可指定要安裝的版本（可選，例如 0.6.0）
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PHYSICSNEMO_DIR="${PHYSICSNEMO_DIR:-$REPO_ROOT/physicsnemo}"

usage() {
  cat <<'EOF'
以 uv 安裝子目錄中的 NVIDIA PhysicsNeMo（預設 ./physicsnemo，亦即 upstream submodule）

用法:
  install-physicsnemo-uv.sh <cu12|cu13|none> [額外傳給 uv sync 的參數...]

引數:
  [cu12|cu13|none]   可選；未指定則預設 cu12。none 表示不帶 cu12/cu13
  其餘                原樣轉給 uv sync（常見: --extra nn-extras）

範例:
  ./scripts/install-physicsnemo-uv.sh cu13
  ./scripts/install-physicsnemo-uv.sh cu12 --extra nn-extras
  ./scripts/install-physicsnemo-uv.sh --extra nn-extras

官方說明: https://github.com/NVIDIA/physicsnemo（README「uv」小節）
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -f "$PHYSICSNEMO_DIR/pyproject.toml" ]]; then
  echo "error: 找不到 pyproject.toml：$PHYSICSNEMO_DIR" >&2
  echo "hint: 先執行 git submodule update --init，或設定 PHYSICSNEMO_DIR" >&2
  exit 1
fi

ensure_uv() {
  if command -v uv >/dev/null 2>&1; then
    return 0
  fi
  echo "本機沒有找到 uv，安裝到 ~/.local/bin ..." >&2
  if [[ -n "${UV_VERSION:-}" ]]; then
    curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | sh
  else
    curl -LsSf "https://astral.sh/uv/install.sh" | sh
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
  if ! command -v uv >/dev/null 2>&1; then
    echo "error: uv 安裝後仍不在 PATH。請手動将 ~/.local/bin 加入 PATH。" >&2
    exit 1
  fi
}

ensure_uv

MODE="cu12"
if [[ "${1:-}" == "cu12" || "${1:-}" == "cu13" || "${1:-}" == "none" ]]; then
  MODE="$1"
  shift
fi

SYNC=(uv sync)
if [[ "$MODE" != "none" ]]; then
  SYNC+=(--extra "$MODE")
fi
SYNC+=("$@")

cd "$PHYSICSNEMO_DIR"
echo "==> 目錄: $PHYSICSNEMO_DIR" >&2
echo "==> 執行: ${SYNC[*]}" >&2
"${SYNC[@]}"

echo "==> 驗證 import ..." >&2
uv run python -c "import physicsnemo; print('PhysicsNeMo version:', physicsnemo.__version__)"

echo "完成。" >&2
