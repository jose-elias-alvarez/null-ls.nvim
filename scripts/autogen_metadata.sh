#!/usr/bin/env bash
set -ex

declare -x XDG_DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
declare -x NVIM_PACK_DIR="$XDG_DATA_HOME/nvim/site/pack"

declare -x NULL_LS_DIR="$PWD"

nvim -u NONE --headless \
	--cmd "set rtp+=${NULL_LS_DIR}" \
	+"luafile scripts/autogen_metadata.lua" +q
