# 公里尺度大氣降尺度的生成式修正擴散模型（CorrDiff）

> 本文件為 NVIDIA PhysicsNeMo 官方 CorrDiff 說明之歸檔，方便離線查閱。線上版：  
> <https://docs.nvidia.com/physicsnemo/latest/physicsnemo/examples/weather/corrdiff/README.html>  
> 原始範例程式路徑：`physicsnemo/examples/weather/corrdiff/`

## 問題概覽

在不必付出昂貴模擬成本的前提下，為了改善天氣災害預測，會以高解析度氣象資料與較粗解析度的 ERA5 再分析資料，訓練具成本效益的隨機降尺度模型 **CorrDiff**。CorrDiff 採用 UNet 與擴散兩階段流程，以處理多尺度難題；在預測天氣極端、以及精準擷取豪雨、颱風動力等多變量關聯上表現佳，顯示從全球尺度到公里尺度的機器學習天氣預報具發展潛力。

*以 CorrDiff 為基礎的臺灣降尺度 — 見官方文件圖 42。*

## HRRR-Mini 範例入門

要開始使用 CorrDiff，官方提供一個稱為 **CorrDiff-Mini** 的簡化版，內容包含：

- 較小的神經網路架構，以降低記憶體與訓練時間。
- 以 HRRR 為基礎的縮小訓練資料集，樣本較少（可自 NGC 取得）。

以上調整可將訓練時間從數千 GPU 小時降為 **在 A100 上約 10 小時**。CorrDiff-Mini 內附的簡化資料載入器，也可作為在自訂資料集上訓練 CorrDiff 的參考範例。**注意**：CorrDiff-Mini 僅供**學習與教學**，其推論結果不應用於實務應用。

### 前置作業

- 安裝 PhysicsNeMo（若尚未安裝），並將 `examples/weather/corrdiff` 資料夾複製到具 GPU 的機器上。
- 自 NGC 下載 **CorrDiff-Mini** 資料集。
- 安裝相依套件：

```bash
pip install -r requirements.txt
```

在此 bootcamp 專案中，前置安裝可於專案根目錄執行 `tran_prep.sh`（會安裝 physicsnemo 與 corrdiff 的 `requirements.txt`）。

### NVIDIA Earth-2 教學 Demo（以 HRRR-Mini 訓練 CorrDiff）

以下對應 *Day2 NVIDIA Earth-2 Overview* 投影片中「DEMO - Train CorrDiff with PhysicsNeMo」的步驟（以 Docker + 單卡執行 `python train.py` 為例）。

| 步驟 | 官方示範（本機／Docker） | 本 repo / HPC 常見做法 |
|------|-------------------------|------------------------|
| 工作目錄 | `cd ~/AI-Powered-Physics-Bootcamp` | 同上，或你的 clone 路徑（例如 `…/source/AI-Powered-Physics-Bootcamp`） |
| 下載資料 | 自 NGC 下載 HRRR-Mini 資料集 | 同上（需 NGC CLI 與帳號） |
| 原始碼 | `git clone https://github.com/NVIDIA/physicsnemo` | 本 repo 已內含 `physicsnemo/` 則**不必**再 clone |
| 執行環境 | `docker run … nvcr.io/nvidia/physicsnemo/physicsnemo:25.11` | 叢集可改用 **Apptainer/Singularity** `.sif` 映像，見 `tran.slrum`；概念與 25.11 映像相同 |
| 安裝套件 | 容器內 `pip install .` 與 `pip install -r requirements.txt` | 登入或 CPU 節點執行 **`bash tran_prep.sh`**（寫入 `$WORK_DIR/.local`） |
| Git safe.directory | 範例路徑 `/home/ubuntu/.../physicsnemo` | 改成你的**實際**絕對路徑；`tran_prep.sh` 已帶上 `$WORK_DIR/physicsnemo` |
| 監控 | `tensorboard --logdir tensorboard/ --port 8889` | 埠可自訂；遠端需 SSH tunnel 或叢集允許的埠 |
| 訓練 | 單一程序 `python train.py --config-name=config_training_hrrr_mini_regression.yaml` | 多卡可用 `torchrun --nproc_per_node=…`（與你 `tran.slrum` 一致） |

**官方指令順序（摘要）：**

```bash
cd ~/AI-Powered-Physics-Bootcamp

# 1) 從 NGC 下載 HRRR-Mini（需已安裝並登入 ngc / API key）
ngc registry resource download-version "nvidia/modulus/modulus_datasets-hrrr_mini:1"

# 2) 若尚無原始碼則取得 physicsnemo（本 bootcamp 若已內建目錄可略過）
# git clone https://github.com/NVIDIA/physicsnemo

# 3) 啟動官方 PhysicsNeMo 容器（本機有 Docker + NVIDIA Container Toolkit）
# docker run --gpus all -it --rm --net host --shm-size=1g \
#   --ulimit memlock=-1 --ulimit stack=67108864 \
#   -v $PWD:$PWD -w $PWD \
#   nvcr.io/nvidia/physicsnemo/physicsnemo:25.11 bash

# 4) 讓 corrdiff 的 data/ 指向下載的資料夾（名稱以 NGC 解壓結果為準，常見 v1 目錄）
ln -sfn "$PWD/modulus_datasets-hrrr_mini_v1" physicsnemo/examples/weather/corrdiff/data

# 5) 容器內安裝（或於本專案改跑: bash tran_prep.sh）
# cd physicsnemo && pip install .
# cd examples/weather/corrdiff && pip install -r requirements.txt

# 6) 若 git 在容器內抱怨目錄權限，safe.directory 請改成你的實際路徑
# git config --global --add safe.directory $PWD/physicsnemo

# 7) TensorBoard（可選）
# nohup tensorboard --logdir tensorboard/ --port 8889 &

# 8) 訓練：HRRR-Mini 迴歸
cd physicsnemo/examples/weather/corrdiff
python train.py --config-name=config_training_hrrr_mini_regression.yaml
```

擴散模型訓練須在迴歸完成後，另行使用 `config_training_hrrr_mini_diffusion.yaml` 並傳入 `++training.io.regression_checkpoint_path=...`（見下文「訓練擴散模型」）。

## 設定概要

CorrDiff 訓練由 `train.py` 管理，並以 YAML 設定檔（Hydra）驅動。

- **基礎設定：** `conf/base/`
- **訓練**
  - **GEFS-HRRR（CONUS）：**
    - `conf/config_training_gefs_hrrr_regression.yaml` — 迴歸
    - `conf/config_training_gefs_hrrr_diffusion.yaml` — 擴散
  - **HRRR-Mini（較小 CONUS）：**
    - `conf/config_training_hrrr_mini_regression.yaml`
    - `conf/config_training_hrrr_mini_diffusion.yaml`
  - **臺灣：**
    - `conf/config_training_taiwan_regression.yaml`
    - `conf/config_training_taiwan_diffusion.yaml`
  - **自訂：**
    - `conf/config_training_custom.yaml`
- **生成／推論**
  - `conf/config_generate_taiwan.yaml`
  - `conf/config_generate_hrrr_mini.yaml`
  - `conf/config_generate_gefs_hrrr.yaml`
  - `conf/config_generate_custom.yaml`

以 `--config-name` 選擇設定。各訓練檔會定義：資料集、模型、訓練超參數。

執行時可用 Hydra 的 `++` 語法**覆寫**設定，例如批次大小：

```bash
python train.py ++training.hp.total_batch_size=64
```

## 訓練迴歸模型

兩階段流程：

1. 先訓練**確定性迴歸**模型。
2. 再以上述迴歸檢查點訓練**擴散**模型。

**CorrDiff-Mini 迴歸** 頂層檔案：`config_training_hrrr_mini_regression.yaml` — 常見欄位：`dataset`、`model`、`model_size`、`training`、`wandb`。

**自** `conf/base/` **載入**，例如：

- `dataset/hrrr_mini.yaml`
- `model/regression.yaml`
- `model_size/mini.yaml`
- `training/regression.yaml`

**指令：**

```bash
python train.py --config-name=config_training_hrrr_mini_regression.yaml
```

**訓練細節：**

- 耗時：單張 **A100** 上約數小時
- **檢查點：** 若中斷可從最新檢查點續訓
- **多 GPU：** `torchrun` 或 MPI
- **記憶體：** 預設透過 `training.hp.total_batch_size` 讓**有效**總批次為 256。若 OOM，可降低每 GPU 批次，例如 `++training.hp.batch_size_per_gpu=64` — CorrDiff 以**梯度累積**維持有效總批次不變。

## 訓練擴散模型

**需要：** 已訓練好的迴歸檢查點、相同資料集、`config_training_hrrr_mini_diffusion.yaml`。

```bash
python train.py --config-name=config_training_hrrr_mini_diffusion.yaml \
  ++training.io.regression_checkpoint_path=</path/to/regression/model>
```

檢查點會寫入 `checkpoints_diffusion/`。範例最終檔名（與文件一致）：`EDMPrecondSR.0.8000000.mdlus`。

## 生成（推論）

**需要：** 迴歸檢查點、擴散檢查點，例如 `conf/config_generate_hrrr_mini.yaml`。

```bash
python generate.py --config-name="config_generate_hrrr_mini.yaml" \
  ++generation.io.res_ckpt_filename=</path/to/diffusion/model> \
  ++generation.io.reg_ckpt_filename=</path/to/regression/model>
```

**NetCDF4** 輸出群組：`input`、`truth`、`prediction`。

## 另例：臺灣資料集

- 以較粗解析度 **ERA5** 為條件的高解析度氣象；授權 **CC BY-NC-ND 4.0**。

**下載（NGC）：**

```bash
ngc registry resource download-version "nvidia/modulus/modulus_datasets_cwa:v1"
```

**模型型別：** 迴歸、擴散、**patch 擴散**（省記憶體／大範圍域）。

**頂層** `config_training_taiwan_regression.yaml` — 將 `dataset` 設為 `cwb`，調整 `model`、`model_size`（建議 `normal`）、`training.hp`、`wandb`。基底：`dataset/cwb.yaml`、`model/*.yaml`、`training/*.yaml`。擴散變體需設定 `training.io.regression_checkpoint_path`。

**單 GPU：**

```bash
python train.py --config-name=config_training_taiwan_regression.yaml
```

**多 GPU（單節點）：**

```bash
torchrun --standalone --nnodes=<NUM_NODES> --nproc_per_node=<NUM_GPUS_PER_NODE> train.py
```

更換設定檔可切換模型型別（例如 `config_training_taiwan_diffusion.yaml`）。

### 取樣與評估

```bash
python generate.py --config-name=config_generate_taiwan.yaml
```

```bash
python score_samples.py path=<PATH_TO_NC_FILE> output=<OUTPUT_FILE>
```

作圖：`inference/`、Earth2Studio，或自訂 NetCDF 工具。

## NGC 上其他可下載資源

CorrDiff 教學常用的是 **HRRR-Mini**（上文「HRRR-Mini 範例入門」）與 **CWA**（「另例：臺灣資料集」）；NGC 上還有許多供 **Modulus / PhysicsNeMo 其他範例** 使用的資料。版本標籤以 [該 NGC resource 頁面](https://catalog.ngc.nvidia.com) 為準，下列為專內常見的 CLI／連結慣例。

| 用途（概略） | 下載方式 |
|-------------|----------|
| CorrDiff：HRRR 縮小版 | `ngc registry resource download-version "nvidia/modulus/modulus_datasets-hrrr_mini:1"`（解壓目錄常見為 `modulus_datasets-hrrr_mini_v1`） |
| CorrDiff：臺灣／CWA | `ngc registry resource download-version "nvidia/modulus/modulus_datasets_cwa:v1"` |
| 機房／資料中心 CFD 範例 | `ngc registry resource download-version "nvidia/physicsnemo/physicsnemo_datacenter_cfd_dataset:v1"`（見 `physicsnemo/examples/cfd/datacenter/README.md`） |
| 心血管模擬（範例腳本以 wget） | `physicsnemo/examples/healthcare/bloodflow_1d_mgn/raw_dataset/download_dataset.sh` 內有 `api.ngc.nvidia.com` zip 連結 |
| 圓柱流、Stokes 等 CFD 範例 | 多數在對應 `examples/cfd/.../README.md` 或 `download_dataset.sh` 內以 **wget** 或 **NGC 連結** 提供 |

**自行瀏覽目錄：**在 [NGC Resources 搜尋 `PhysicsNeMo` 或 `Modulus`](https://catalog.ngc.nvidia.com/resources?filters=&orderBy=scoreDESC&query=PhysicsNeMo&page=&pageSize=) 可看到資料集、補充檔與不同 team（例如 `nvidia/physicsnemo/...` 與 `nvidia/modulus/...`）。**以 CLI 列出**（已登入 `ngc` 時）可用 `ngc registry resource list` 搭配 org／team 篩選。一般下載格式與上表相同：

```bash
ngc registry resource download-version "nvidia/<team>/<resource_name>:<version_tag>"
```

## 日誌與監控

- **TensorBoard：** `tensorboard --logdir=/path/to/logdir --port=6006`（依需求再做埠轉送／SSH tunnel）。
- **Weights & Biases** — 專案名稱寫死為 `Modulus-Launch`、實體 `Modulus`、群組 `CorrDiff-DDP-Group`。在 YAML 中例如：

```yaml
wandb:
  mode: offline       # "online" | "offline" | "disabled"
  results_dir: "./wandb"
  watch_model: true
```

首次使用請執行 `wandb login`。

## 自訂資料集

實作一個繼承 **`DownscalingDataset`**（`datasets/base.py`）的類別，需具備：`longitude`、`latitude`、`input_channels`、`output_channels`、`time`、`image_shape`、`__len__`、`__getitem__`。

`__getitem__` 回傳 `(img_clean, img_lr)`，或可選的 `lead_time_label`。

**YAML** 範例：

```yaml
dataset:
  type: path/to/your/dataset.py::CustomDataset
  data_path: /path/to/your/data
  stats_path: /path/to/statistics.json
  input_variables: ["temperature", "pressure"]
  output_variables: ["high_res_temperature"]
  invariant_variables: ["topography"]
```

參考：`datasets/hrrrmini.py`、`datasets/cwb.py`。

**訓練：** `config_training_custom.yaml`；可覆寫如 `++training.hp.lr=0.0001`。

**Patch 大小（patch 擴散）：** 使用 `inference/power_spectra.py` 的 `average_power_spectrum()`、`power_spectra_to_acf()`；令 `patch_shape_x` / `patch_shape_y` ≥ 殘差自相關長度。除錯可先從 `model_size: mini` 開始。

**生成：** `config_generate_custom.yaml`，例如：

```bash
python generate.py --config-name=config_generate_custom.yaml \
  ++generation.io.res_ckpt_filename=/path/to/diffusion/checkpoint.mdlus \
  ++generation.io.reg_ckpt_filename=/path/to/regression/checkpoint.mdlus \
  ++dataset.type=path/to/your/dataset.py::CustomDataset \
  ++generation.num_ensembles=10
```

## 常見問答（精簡）

- **預訓練檢查點（NVIDIA AI Enterprise 等）：** 可能與目前版 `train.py`／`generate.py` 不相容；多數僅供 **Earth2Studio**。除非區域與變數一致，建議**自頭訓練**（完整 FAQ 見官方文件）。
- **樣本數：** 粗估 **≥ 50,000**；在 patch 訓練中，每個 patch 可計為一筆樣本。
- **GPU：** 記憶體夠用則 1 張即可；牆上時間約與 GPU 數成線性；大規模範例常見 **64× A100**。OOM 時：降低 `batch_size_per_gpu` 或 patch 大小（仍須大於自相關長度）。
- **美國尺度的自訂訓練成本範例：** 約 5,000 A100·小時；64 GPU 時牆上約 **80 小時**；實際隨樣本數變化。
- **降尺度比上限：** 相同變數約 **×16**；新輸出變數約 **×11** 空間超解析。
- **收斂判斷：** 損失應隨訓練下降（見官方損失曲線圖）。
- **關鍵超參數：** `patch_shape_*`、`training_duration`（常見 1M–30M 樣本）、`lr_rampup`、`lr`、`batch_size_per_gpu`。
- **驗證：** 可選 `validation:` 區塊，繼承自 `dataset` 的覆寫。**無內建 early stopping** — 依記錄的驗證損失手動挑最佳檢查點。

## 參考文獻

- Residual Diffusion Modeling for Km-scale Atmospheric Downscaling
- Elucidating the design space of diffusion-based generative models
- Score-Based Generative Modeling through Stochastic Differential Equations
