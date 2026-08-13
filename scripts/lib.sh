#!/bin/bash
# chat-rap-video 公共环境配置
# 用法: source "$(dirname "$0")/lib.sh"
#
# 路径解析优先级（开源版）：
#   1) 环境变量（最高优先级，用户可自定义）：
#      CHAT_RAP_NODE_BIN   Node.js 可执行文件路径
#      CHAT_RAP_NODE_PATH   Node 模块目录（node_modules 父级，用于 NODE_PATH）
#      CHAT_RAP_FFMPEG     ffmpeg 可执行文件路径
#      CHAT_RAP_CHROME     Chromium 可执行文件路径（playwright 渲染用）
#      CHAT_RAP_WHISPER    mlx_whisper 可执行文件路径
#   2) 自动探测（PATH 中的 node / ffmpeg / ffprobe / mlx_whisper）
#   3) 常见默认路径（macOS 开发环境）

# skill 根目录（自动定位：lib.sh 的上一级）
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---- Node.js ----
if [[ -n "${CHAT_RAP_NODE_BIN:-}" ]]; then
  NODE_BIN="$CHAT_RAP_NODE_BIN"
elif command -v node >/dev/null 2>&1; then
  NODE_BIN="$(command -v node)"
else
  NODE_BIN="/usr/local/bin/node"
fi

# ---- Node 模块目录（node_modules 父级）----
if [[ -n "${CHAT_RAP_NODE_PATH:-}" ]]; then
  NODE_PATH_DIR="$CHAT_RAP_NODE_PATH"
elif [[ -d "$SKILL_DIR/node_modules" ]]; then
  NODE_PATH_DIR="$SKILL_DIR"
else
  # 尝试从 node 可执行文件反推（macOS Homebrew/managed 场景）
  NODE_ROOT="$(dirname "$(dirname "$NODE_BIN")")"
  for cand in "$NODE_ROOT/lib/node_modules" "$(npm root -g 2>/dev/null)"; do
    if [[ -n "$cand" && -d "$cand" ]]; then NODE_PATH_DIR="$(dirname "$cand")"; break; fi
  done
  [[ -n "${NODE_PATH_DIR:-}" ]] || NODE_PATH_DIR="$SKILL_DIR"
fi

# ---- ffmpeg / ffprobe ----
if [[ -n "${CHAT_RAP_FFMPEG:-}" ]]; then
  FFMPEG_BIN="$CHAT_RAP_FFMPEG"
elif command -v ffmpeg >/dev/null 2>&1; then
  FFMPEG_BIN="$(command -v ffmpeg)"
else
  # 常见默认路径（ffmpeg-static 内置二进制）
  for cand in \
    "$SKILL_DIR/node_modules/ffmpeg-static/ffmpeg" \
    "$(npm root -g 2>/dev/null)/ffmpeg-static/ffmpeg"; do
    if [[ -n "$cand" && -x "$cand" ]]; then FFMPEG_BIN="$cand"; break; fi
  done
  [[ -n "${FFMPEG_BIN:-}" ]] || FFMPEG_BIN="ffmpeg"
fi
FFPROBE_BIN="$(dirname "$FFMPEG_BIN")/ffprobe"
[[ -x "$FFPROBE_BIN" ]] || FFPROBE_BIN="ffprobe"

# ---- Chromium（playwright 逐帧渲染）----
if [[ -n "${CHAT_RAP_CHROME:-}" ]]; then
  CHROME_BIN="$CHAT_RAP_CHROME"
elif [[ -n "${PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH:-}" ]]; then
  CHROME_BIN="$PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH"
else
  CHROME_BIN=""
  # 常见缓存路径（macOS / Linux）
  for cand in \
    "$HOME/Library/Caches/ms-playwright"/chrome-mac*/chrome-mac*/"Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
    "$HOME/.cache/ms-playwright"/chrome-*/chrome-linux*/chrome \
    "$HOME/.cache/ms-playwright"/chromium-*/chrome-linux*/chrome; do
    if [[ -n "$cand" && -x "$cand" ]]; then CHROME_BIN="$cand"; break; fi
  done
fi

# ---- mlx_whisper（说唱时间戳对齐，可选）----
if [[ -n "${CHAT_RAP_WHISPER:-}" ]]; then
  WHISPER_BIN="$CHAT_RAP_WHISPER"
elif command -v mlx_whisper >/dev/null 2>&1; then
  WHISPER_BIN="$(command -v mlx_whisper)"
else
  WHISPER_BIN="mlx_whisper"   # 不存在时 whisper_align.sh 会报错并提示安装
fi

# 沙箱/代理环境：直连外网时 unset 代理变量
unset_proxy() {
  export HTTPS_PROXY= HTTP_PROXY= https_proxy= http_proxy= ALL_PROXY= all_proxy=
}

run_node() {
  NODE_PATH="$NODE_PATH_DIR" "$NODE_BIN" "$@"
}
