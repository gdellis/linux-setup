#!/usr/bin/env bash
# set -x

# -----------------------------------
# Setup Directory Variables
# -----------------------------------
# region
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -f "$SCRIPT_DIR/.topdir" ];then
    TOP=$($SCRIPT_DIR)
else
    TOP="$(realpath "$SCRIPT_DIR/..")"
fi

LIB_DIR="$TOP/lib"

# Source Logger
source "$LIB_DIR/logging.sh" || exit 1
# endregion
# -----------------------------------

# Error handling function
handle_error()
{
    local _msg="$1"
    echo -e "[ERROR] $_msg"
    exit 1
}

cloud_models=(
    "qwen3-vl:235b-cloud"
    "qwen3-vl:235b-instruct-cloud"
    "gpt-oss:120b-cloud"
    "gpt-oss:120b-cloud"
    "glm-4.6:cloud"
    "deepseek-v3.1:671b-cloud"
    "minimax-m2:cloud"
    "kimi-k2:1t-cloud"
    "gemini-3-pro-preview:latest"
    "kimi-k2-thinking:cloud"
    "cogito-2.1:671b-cloud"
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
   
    if  ollama ls | grep -q $_model;then
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
        ollama pull $1
        echo -e "Finished Pulling Model: $1"
    fi
}

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

# Login
log_info "$0 Completed Successfully"

echo
echo "Before you can use cloud models you must login to your account by running:"
echo "ollama signin"
echo

