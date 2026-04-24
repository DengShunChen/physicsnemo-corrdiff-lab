# AI-Powered Physics Bootcamp（CWA 工作區）

本目錄為 **CWA x NVIDIA**「AI-Powered Physics Bootcamp」實作與實驗用工作區，與上層 **Git 版控** 的建議方式如下。

## 目錄說明

| 內容 | 說明 |
|------|------|
| `physicsnemo/` | 官方 [NVIDIA PhysicsNeMo](https://github.com/NVIDIA/physicsnemo) 的 Git clone。請**在該目錄內**以既有 `origin` 做 `git pull` / branch，勿依賴上層 repo 追蹤整個目錄。本機的 corrdiff `checkpoints_*` 等產出體積極大，應由該專案既有 `.gitignore` 排除，不進版控。 |
| `modulus_datasets-hrrr_mini_v1/` | HRRR mini 資料集（體積大），已列入根目錄 `.gitignore`。 |
| `physicsnemo_25.11.sif` | Singularity 映像，已忽略。 |
| `.local/` | 本機 Python/套件路徑，已忽略。 |
| `Day*.pdf` | 營隊講義 PDF。 |
| `inference.slrum`, `tran.slrum` 等 | Slurm 作業腳本範本。 |
| 根目錄 `corrdiff_*.log` | 執行日誌，已忽略。 |

## 版控策略（此根目錄 repo）

- **追蹤**：營隊自訂腳本、講義 PDF、本 `README`、根目錄 `.gitignore`。
- **不追蹤**：`physicsnemo/` 整體、資料集、映像、`.local`、日誌與大型產出（見 `.gitignore`）。

若你修改的是 `physicsnemo` 內的範例或程式，請在 `physicsnemo` 內用 Git 管理（fork 或另開 branch 再 push）。

## 網路連線（CWA proxy）

若此環境需要走 CWA proxy 才能連外（例如 push/pull GitHub），先執行：

```bash
. ~/.proxy
```
