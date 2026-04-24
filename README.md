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
| `inference.slrum`, `tran.slrum` 等 | Slurm 作業腳本範本。 |
| 根目錄 `corrdiff_*.log` | 執行日誌，已忽略。 |

## 版控策略（此根目錄 repo）

- **追蹤**：營隊自訂腳本、講義 PDF、本 `README`、根目錄 `.gitignore`、**`physicsnemo` 作為 submodule 的 commit 指針**（`.gitmodules`）。
- **不追蹤**：資料集、映像、`.local`、日誌與大型產出（見 `.gitignore`）。**子模組目錄內的內容**由該子 repo 管理；大檔仍留在本機、由子專案 `.gitignore` 處理。

若你修改的是 `physicsnemo` 內的範例或程式，請在 `physicsnemo` 內用 Git 管理（fork 或另開 branch 再 push）；**若要把新 commit 固定給上層 repo 使用**，在 `physicsnemo` 內 commit 後回到父層執行 `git add physicsnemo` 更新 submodule 指針再 push 父層。
