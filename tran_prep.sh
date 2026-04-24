#!/usr/bin/env bash
# CorrDiff / physicsnemo 訓練前：在容器內安裝 pip 依賴到 WORK_DIR/.local
# 用法：在專案根執行  bash tran_prep.sh
# 可選: WORK_DIR=/path/to/clone bash tran_prep.sh
# 若 login 不給用 GPU，本腳本預設 *不加* --nv；需與訓練相同可加：USE_SINGULARITY_NV=1 bash tran_prep.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-$SCRIPT_DIR}"
SIF="${WORK_DIR}/physicsnemo_25.11.sif"
CORR_DIR="${WORK_DIR}/physicsnemo/examples/weather/corrdiff"

SINGULARITY_FLAGS=(--bind "${WORK_DIR}:${WORK_DIR}")
if [[ "${USE_SINGULARITY_NV:-0}" == "1" ]]; then
  SINGULARITY_FLAGS=(--nv "${SINGULARITY_FLAGS[@]}")
fi

if [[ ! -f "$SIF" ]]; then
  echo "ERROR: 找不到 SIF: $SIF" >&2
  exit 1
fi
if [[ ! -d "${WORK_DIR}/physicsnemo" ]]; then
  echo "ERROR: 找不到 physicsnemo 目錄: ${WORK_DIR}/physicsnemo" >&2
  exit 1
fi

cd "$WORK_DIR"
mkdir -p "${WORK_DIR}/.local"

run_inside() {
  singularity exec "${SINGULARITY_FLAGS[@]}" "$SIF" bash -c "$1"
}

echo "==> WORK_DIR=$WORK_DIR"
echo "==> Singularity: ${SINGULARITY_FLAGS[*]} $SIF"
run_inside "
  set -euo pipefail
  if [[ -f \"\$HOME/.proxy\" ]]; then
    # shellcheck source=/dev/null
    source \"\$HOME/.proxy\"
  fi
  git config --global --add safe.directory ${WORK_DIR}/physicsnemo
  export PYTHONUSERBASE=${WORK_DIR}/.local
  export PATH=\"\${PYTHONUSERBASE}/bin:\${PATH}\"
  cd ${WORK_DIR}/physicsnemo
  pip install --user -q -U pip
  pip install --user .
  cd ${CORR_DIR}
  pip install --user -r requirements.txt
  python3 -c \"import physicsnemo; import wandb; print('physicsnemo OK')\"
  echo 'pip 依賴安裝完成。'
"

echo
echo "完成。之後在專案根執行: sbatch tran.slrum"
echo "訓練 log 若出現 c10d localhost:29500 errno 97: tran.slrum 內已預設 export MASTER_ADDR=127.0.0.1"
