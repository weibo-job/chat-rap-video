#!/bin/bash
# run.sh —— 一键跑通 chat-rap-video 全流程
#
# 用法:
#   bash run.sh --script script.json --out ./out \
#               [--prompt "黑人说唱 吐槽老板"] \
#               [--bgm music.mp3]
#
# 流程：
#   1) BGM（--bgm 直接用；否则 gen_rap_bgm.sh 走 Flova/本地兜底）
#   2) 节拍分析
#   3) 逐帧渲染
#   4) ffmpeg 合成
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export NODE_PATH="$NODE_PATH_DIR"

SCRIPT=""; OUT=""; BGM=""; PROMPT="黑人说唱 吐槽老板 节奏快 押韵 魔性洗脑"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --script) SCRIPT="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    --bgm) BGM="$2"; shift 2;;
    --prompt) PROMPT="$2"; shift 2;;
    *) echo "未知参数 $1"; exit 1;;
  esac
done
[[ -n "$SCRIPT" && -n "$OUT" ]] || { echo "缺少 --script 和 --out"; exit 1; }
mkdir -p "$OUT"

# 1) BGM
if [[ -z "$BGM" ]]; then
  echo "== [1/4] 生成说唱 BGM（走 Flova/本地兜底） =="
  if bash "$SCRIPT_DIR/gen_rap_bgm.sh" --prompt "$PROMPT" --short --out "$OUT/bgm.mp3" >/dev/null 2>&1; then
    BGM="$OUT/bgm.mp3"
  else
    echo "   ⚠️  BGM 未生成（Flova 需用户确认 / 本地无 BGM），先出无声版"
  fi
fi
[[ -f "$BGM" ]] || BGM=""

# 2) 节拍
echo "== [2/4] 节拍分析 =="
if [[ -n "$BGM" ]]; then
  FFMPEG_BIN="$FFMPEG_BIN" "$NODE_BIN" "$SCRIPT_DIR/analyze_beats.js" --bgm "$BGM" --out "$OUT/beats.json"
else
  # 无 BGM 时用脚本里元素最晚时间 + 兜底节奏
  DURATION=$("$NODE_BIN" -e "const fs=require('fs'); const s=JSON.parse(fs.readFileSync('$SCRIPT','utf8')); const ms=(s.elements||[]).reduce((m,e)=>Math.max(m,(e.start_ms||0)+(e.repeat? (e.repeat-1)*(e.step_ms||150) : 0)), 0); console.log(Math.max(20000, ms+5000));")
  echo "{\"duration_ms\":$DURATION,\"beats\":[]}" > "$OUT/beats.json"
  echo "   (无 BGM，duration_ms=$DURATION ms)"
fi

# 3) 逐帧渲染
echo "== [3/4] 逐帧渲染 =="
ASSETS_DIR="$(dirname "$SCRIPT")/assets"
[[ -d "$ASSETS_DIR" ]] || ASSETS_DIR=""
"$NODE_BIN" "$SCRIPT_DIR/render_frames.js" \
  --script "$SCRIPT" --beats "$OUT/beats.json" \
  --template "$SKILL_DIR/assets/chat_template_v11.html" \
  --assets "$ASSETS_DIR" \
  --out "$OUT/frames" --fps 30

# 4) 合成
echo "== [4/4] 合成成片 =="
if [[ -n "$BGM" ]]; then
  bash "$SCRIPT_DIR/compose_video.sh" --frames "$OUT/frames" --bgm "$BGM" --out "$OUT/final.mp4"
else
  bash "$SCRIPT_DIR/compose_video.sh" --frames "$OUT/frames" --out "$OUT/final.mp4"
fi

echo ""
echo "✅ 完成！成片: $OUT/final.mp4"
[[ -n "$BGM" ]] || echo "   (无声版 — 配上 Flova 说唱BGM 后会更有抖音味儿)"