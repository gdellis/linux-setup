#!/usr/bin/env bash
# ------------------------------------------------------------
# region Script Setup
# ------------------------------------------------------------
# Uncomment for verbose debugging
# set -x 

# ------------------------------------------------------------
# Setup Directory Variables
# ------------------------------------------------------------
# region
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# ------------------------------------------------------------
# region Determine top‑level directory
# ------------------------------------------------------------
# 1️⃣ Prefer Git if we are inside a repo
TOP="$(git rev-parse --show-toplevel 2>/dev/null)"

# 2️⃣ If not a Git repo, look for a known marker (e.g., .topdir)
if [[ -z "$TOP" ]]; then
  # Resolve the directory where this script resides
  SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

  # Walk upward until we find .topdir or stop at /
  DIR="$SCRIPT_DIR"
  while [[ "$DIR" != "/" ]]; do
    if [[ -f "$DIR/.topdir" ]]; then
      TOP="$DIR"
      break
    fi
    DIR="$(dirname "$DIR")"
  done
fi

# 3️⃣ Give up with a clear error if we still have no root
if [[ -z "$TOP" ]]; then
  echo "❌  Unable to locate project root. Ensure you are inside a Git repo or that a .topdir file exists."
  exit 1
fi

export TOP
log_info "(setup_bash.sh) Project root resolved to: $TOP"
# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

# ------------------------------------------------------------
# region Setup Logger
# ------------------------------------------------------------
LIB_DIR="$TOP/lib"

# Source Logger
source "$LIB_DIR/logging.sh" || exit 1
# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

# Error handling function
handle_error()
{
    local _msg="$1"
    echo -e "[ERROR] $_msg"
    exit 1
}

cloud_models=(
    "ministral-3:3b-cloud"
    "ministral-3:8b-cloud"
    "ministral-3:14b-cloud"
    "mistral-large-3:675b-cloud"
    "qwen3-coder:480b-cloud"
    "cogito-2.1:671b-cloud"
    "kimi-k2-thinking:cloud"
    "kimi-k2:1t-cloud"
    "minimax-m2:cloud"
    "deepseek-v3.1:671b-cloud"
    "gpt-oss:120b-cloud"
    "glm-4.6:cloud"
    "qwen3-vl:235b-instruct-cloud"
    "qwen3-vl:235b-cloud"
    "gpt-oss:20b-cloud"
)

local_models=(
    "qwen2.5-coder:1.5b"
    "nomic-embed-text:latest"
    "qwen3-embedding:latest"
    "hf.co/dat-lequoc/Fast-Apply-1.5B-v1.0_GGUF:latest"
    "dengcao/Qwen3-Reranker-8B:Q3_K_M"
    "nate/instinct"
)

check_list()
{
    local _model="$1"
   
    if  ollama ls | grep -q "$_model";then
        echo -e "'$_model' is already downloaded, skipping"
        return 0
    else
        echo -e "'$_model' is NOT downloaded"
        return 1
    fi
}

dl_model()
{
    echo -e "Pulling Model: $1"

    # Check if model is already downloaded
    if ! check_list "$1"; then
        echo -e "Downloading Model: $1"
        ollama pull "$1"
        echo -e "Finished Pulling Model: $1"
    fi
}

download_models()
{
    echo -e "--------------------------------------"
    echo -e "Downloading Cloud Models"
    echo -e "--------------------------------------"
    for model in "${cloud_models[@]}";do
        dl_model "$model"
    done;

    echo -e "--------------------------------------"
    echo -e "Downloading Local Models"
    echo -e "--------------------------------------"
    for model in "${local_models[@]}";do
        dl_model "$model"
    done

    echo -e "--------------------------------------"
    echo -e " Finished Downloading models"
    echo -e "--------------------------------------"
}

install_ollama()
{
    log_info "Installing Ollama"
    curl -fsSL https://ollama.com/install.sh | sh
}

download_models

# Login
log_info "$0 Completed Successfully"

echo
echo "Before you can use cloud models you must login to your account by running:"
echo "ollama signin"
echo

