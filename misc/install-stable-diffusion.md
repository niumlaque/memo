---
title: Stable Diffusion を WSL2 で用意する
permalink: /misk/install-sd/
---

## Distro 準備
問題発生時に検索結果が多そうな Ubuntu にしておく。


```
wsl --install -d Ubuntu-24.04
wsl --shutdown
wsl --export Ubuntu-24.04 "D:\w\wsl\ubuntu24.tar"
wsl --unregister Ubuntu-24.04
wsl --import stable-diffusion "D:\w\wsl\stable-diffusion" "D:\w\wsl\ubuntu24.tar" --version 2
```

## Stable Diffusion のインストール
記述時点での HEAD ブランチでは `webui.sh` が失敗するため、dev ブランチで clone する。
```sh
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${HOME}/apps"
WEBUI_DIR="${APP_DIR}/stable-diffusion-webui"
PYTHON_VERSION="3.10"
LISTEN_HOST="127.0.0.1"
PORT="7860"

echo "[1/8] Check WSL2 NVIDIA GPU visibility"
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi was not found."
  echo "Make sure the Windows NVIDIA driver supports CUDA on WSL2."
  exit 1
fi

nvidia-smi

echo "[2/8] Install apt dependencies"
sudo apt update
sudo apt install -y \
  git \
  wget \
  curl \
  ca-certificates \
  build-essential \
  libgl1 \
  libglib2.0-0 \
  libgoogle-perftools4 \
  libtcmalloc-minimal4

echo "[3/8] Install uv"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

export PATH="${HOME}/.local/bin:${PATH}"

echo "[4/8] Install Python ${PYTHON_VERSION} with uv"
uv python install "${PYTHON_VERSION}"

PYTHON_BIN="$(uv python find "${PYTHON_VERSION}")"

echo "[5/8] Clone AUTOMATIC1111 stable-diffusion-webui"
mkdir -p "${APP_DIR}"

if [ ! -d "${WEBUI_DIR}" ]; then
  git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git -b dev "${WEBUI_DIR}"
else
  git -C "${WEBUI_DIR}" pull --ff-only
fi

echo "[6/8] Create webui-user.sh"
cat > "${WEBUI_DIR}/webui-user.sh" <<EOF
#!/usr/bin/env bash

python_cmd="${PYTHON_BIN}"

export COMMANDLINE_ARGS="--listen --server-name ${LISTEN_HOST} --port ${PORT} --xformers --api --theme dark --opt-sdp-attention"

export TORCH_COMMAND="pip install torch torchvision --index-url https://download.pytorch.org/whl/cu126"
EOF

chmod +x "${WEBUI_DIR}/webui-user.sh"

echo "[7/8] Create model directories"
mkdir -p "${WEBUI_DIR}/models/Stable-diffusion"
mkdir -p "${WEBUI_DIR}/models/Lora"
mkdir -p "${WEBUI_DIR}/models/VAE"

echo "[8/8] Setup completed"
echo
echo "Next step:"
echo "  Put .safetensors or .ckpt model files into:"
echo "  ${WEBUI_DIR}/models/Stable-diffusion"
echo
echo "Start command:"
echo "  cd ${WEBUI_DIR}"
echo "  ./webui.sh"
echo
echo "Open from Windows browser:"
echo "  http://127.0.0.1:${PORT}"
```

## モデルのダウンロード
ライセンスの同意が必要なので手動で DL する。
`https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0` へアクセスし、`Files and versions` のタブを開く。
`sd_xl_base_1.0.safetensors` をダウンロードし、`~/apps/stable-diffusion-webui/models/Stable-diffusion/` に配置する。

最後に `webui.sh` を実行して起動できる。

