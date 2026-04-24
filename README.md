# AI-Powered Physics Bootcamp（CWA 工作區）

本目錄為 **CWA x NVIDIA**「AI-Powered Physics Bootcamp」實作與實驗用工作區，與上層 **Git 版控** 的建議方式如下。

## 目錄說明

| 內容 | 說明 |
|------|------|
| `physicsnemo/` | 官方 [NVIDIA PhysicsNeMo](https://github.com/NVIDIA/physicsnemo) 的 **git submodule**（`main` 上游固定在某個 commit，見父 repo 的 `physicsnemo` 指針）。本機的 corrdiff `checkpoints_*` 等產出體積極大，由子專案既有 `.gitignore` 排除，不進上層 Git。子目錄內開發/更新請用 `cd physicsnemo` 內的 Git。 **clone 此 repo 後**請執行 `git submodule update --init --recursive` 帶出子模組。 |
| `modulus_datasets-hrrr_mini_v1/` | HRRR mini 資料集（體積大），已列入根目錄 `.gitignore`。 |
| `physicsnemo_25.11.sif` | Singularity 映像，已忽略。 |
| `.local/` | 本機 Python/套件路徑，已忽略。 |
| `Day*.pdf` | 營隊講義 PDF。 |
| `inference.slrum`, `tran.slrum` 等 | Slurm 作業腳本範本（**不是**只有 `.sif` 就能跑，見下方）。 |
| 根目錄 `corrdiff_*.log` | 執行日誌，已忽略。 |

## Slurm / 容器訓練（`tran.slrum`）要準備什麼？

`tran.slrum` 會用 `singularity exec --nv` 掛進本 repo、在容器內對 `physicsnemo/` 做 `pip install --user`，因此 **光準備好 `physicsnemo_25.11.sif` 不夠**，還需要下列項目一併就緒：

| 項目 | 說明 |
|------|------|
| **容器映像** | 例如 `physicsnemo_25.11.sif` 放在 `WORK_DIR`（與腳本內路徑一致）。可用 `scripts/build-physicsnemo-sif.sh` 從 NGC 建置。 |
| **`physicsnemo/` 原始碼** | 主機上須有子模組目錄（`git submodule update --init --recursive`）。腳本用 `--bind` 掛載 `WORK_DIR`，訓練程式從這裡執行。 |
| **依賴安裝** | 腳本內會在容器裡 `pip install --user .` 與 corrdiff 的 `requirements.txt`，安裝目標為 `PYTHONUSERBASE=$WORK_DIR/.local`（首次或升版後需實際跑過安裝步驟）。若改以本機 **uv** 開發，可參考 `scripts/install-physicsnemo-uv.sh`。 |
| **Diffusion 訓練** | 腳本中 `REGRESSION_MODEL` 指向的 **regression checkpoint**（`.mdlus`）路徑在本機必須存在；需先完成 regression 或自行替換為你的檔案路徑。 |
| **資料與設定** | HRRR mini 等資料路徑須與所選的 `config_*.yaml` 一致（例如本機的 `modulus_datasets-hrrr_mini_v1/`，實際欄位以 config 為準）。 |
| **叢集資源** | `#SBATCH` 的 `partition`、`gres`（GPU 數量）、時間上限等，請改成符合你實驗室／叢集可申請的設定。 |

若希望**盡量只依賴映像、少在掛載目錄裡 `pip install`**，需改用自訂定義的容器內建環境或把依賴 bake 進 image，並相應修改腳本掛載範圍與啟動方式；此 repo 內的範例仍以「映像 + 原始碼 + `.local`」流程為主。

## 版控策略（此根目錄 repo）

- **追蹤**：營隊自訂腳本、講義 PDF、本 `README`、根目錄 `.gitignore`、**`physicsnemo` 作為 submodule 的 commit 指針**（`.gitmodules`）。
- **不追蹤**：資料集、映像、`.local`、日誌與大型產出（見 `.gitignore`）。**子模組目錄內的內容**由該子 repo 管理；大檔仍留在本機、由子專案 `.gitignore` 處理。

若你修改的是 `physicsnemo` 內的範例或程式，請在 `physicsnemo` 內用 Git 管理（fork 或另開 branch 再 push）；**若要把新 commit 固定給上層 repo 使用**，在 `physicsnemo` 內 commit 後回到父層執行 `git add physicsnemo` 更新 submodule 指針再 push 父層。
