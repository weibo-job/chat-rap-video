#!/bin/bash
# compose_video.sh —— 把帧序列合成 1080x1920 30fps mp4，混入 BGM
# 用法:
#   bash compose_video.sh --frames <帧目录> --bgm <bgm.mp3> --out <final.mp4>
#
# 音频对齐铁律（2026-08-11 v2 修复）：
#   BGM 必须覆盖视频全程，说唱不许提前结束。
#   - 不用 -shortest（BGM 短于视频时会把音频截断在 BGM 长度处）
#   - BGM 短于视频 → -stream_loop -1 循环补长到视频时长
#   - BGM 长于视频 → 截取到视频时长（人声末尾对齐）
set -euo pipefail
source "$(dirname "$0")/lib.sh"

FRAMES=""; BGM=""; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --frames) FRAMES="$2"; shift 2;;
    --bgm)    BGM="$2"; shift 2;;
    --out)    OUT="$2"; shift 2;;
    *) echo "未知参数 $1"; exit 1;;
  esac
done
[[ -n "$FRAMES" && -n "$OUT" ]] || { echo "缺少 --frames 或 --out"; exit 1; }

# 帧数 → 视频时长（秒）
COUNT=$(ls "$FRAMES"/*.png 2>/dev/null | wc -l | tr -d ' ')
[[ "$COUNT" -gt 0 ]] || { echo "frames 目录为空: $FRAMES"; exit 1; }
FPS=30
VIDEO_DUR=$(awk "BEGIN{printf \"%.2f\", $COUNT/$FPS}")

echo ">> 合成 $COUNT 帧 (≈${VIDEO_DUR}s) → $OUT ..."

if [[ -n "$BGM" && -f "$BGM" ]]; then
  FFMPEG_BIN_DIR=$(dirname "$FFMPEG_BIN")
  FFPROBE_BIN="${FFMPEG_BIN_DIR}/ffprobe"
  if [[ -x "$FFPROBE_BIN" ]]; then
    BGM_DUR=$("$FFPROBE_BIN" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$BGM" 2>/dev/null || echo "?")
  else
    # 兜底：ffmpeg -i 在 pipefail 下会因"无输出文件"返回非零，必须 || true
    BGM_DUR=$("$FFMPEG_BIN" -i "$BGM" 2>&1 | grep -oE 'Duration: [0-9:.]+' | head -1 | sed 's/Duration: //' || echo "?")
  fi
  echo ">> 混入 BGM: $BGM (时长 $BGM_DUR) 视频≈${VIDEO_DUR}s"

  # 音频循环/截取：保证 BGM 覆盖视频全程
  # 短了 → 循环补长；长了 → 截到视频时长
  "$FFMPEG_BIN" -y -framerate "$FPS" -i "$FRAMES/%06d.png" \
    -i "$BGM" \
    -filter_complex "[1:a]aloop=loop=-1:size=2e9[aout]" \
    -map 0:v -map "[aout]" \
    -c:v libx264 -preset medium -crf 21 -pix_fmt yuv420p \
    -c:a aac -b:a 192k \
    -t "$VIDEO_DUR" \
    -movflags +faststart "$OUT" 2>&1 | tail -5
else
  echo ">> (无 BGM，输出无声版)"
  "$FFMPEG_BIN" -y -framerate "$FPS" -i "$FRAMES/%06d.png" \
    -c:v libx264 -preset medium -crf 21 -pix_fmt yuv420p \
    -movflags +faststart "$OUT" 2>&1 | tail -5
fi

echo ">> 完成: $OUT"
"$FFMPEG_BIN" -i "$OUT" 2>&1 | grep -E "Duration|Stream" || true
