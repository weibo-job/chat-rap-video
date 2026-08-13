#!/usr/bin/env bash
# whisper 时间戳对齐：转写说唱 BGM，拿每句真实时间戳（解决说唱/字幕不同步）
# 用法:
#   bash scripts/whisper_align.sh --bgm out/bgm.mp3 --script script.json [--out script_aligned.json]
# 产出:
#   - <out>.json         剧本：所有 bubble 的 start_ms/duration_ms 按 whisper 段起点重排
#   - 控制台输出 whisper segments（start→end : text），用于核对歌词顺序
#
# 依赖（需自行安装）:
#   - mlx_whisper（Python）：pip install mlx-whisper，模型 mlx-community/whisper-small-mlx
#     （large-v3 缓存缺 weights.npz 会失败，small 稳定）
#   - ffmpeg / ffprobe（whisper 内部调用 ffmpeg）
#   - 环境变量覆盖：CHAT_RAP_WHISPER / CHAT_RAP_NODE_BIN / CHAT_RAP_FFMPEG

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FFSTATIC_DIR="$(dirname "$FFMPEG_BIN")"
PY_BIN="$WHISPER_BIN"
NODE_BIN="$NODE_BIN"
MODEL="${CHAT_RAP_WHISPER_MODEL:-mlx-community/whisper-small-mlx}"
WHISPER_DIR="/tmp/whisper_align"

BGM=""; SCRIPT=""; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bgm) BGM="$2"; shift 2;;
    --script) SCRIPT="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    *) echo "未知参数: $1"; exit 1;;
  esac
done

[[ -z "$BGM" || -z "$SCRIPT" ]] && { echo "必须提供 --bgm 和 --script"; exit 1; }
[[ -z "$OUT" ]] && OUT="${SCRIPT%.json}_aligned.json"
mkdir -p "$WHISPER_DIR"

echo ">> [1/3] whisper 转写 BGM: $BGM (模型 $MODEL)"
command -v "$PY_BIN" >/dev/null 2>&1 || { echo "mlx_whisper 未安装。安装: pip install mlx-whisper 或设置 CHAT_RAP_WHISPER 环境变量"; exit 1; }
export PATH="$FFSTATIC_DIR:$PATH"
HTTPS_PROXY= HTTP_PROXY= https_proxy= http_proxy= "$PY_BIN" "$BGM" \
  --language zh --task transcribe --output-format json \
  --output-dir "$WHISPER_DIR" --model "$MODEL" >/dev/null 2>&1

JSON="$(basename "$BGM" .mp3).json"
[[ -f "$WHISPER_DIR/$JSON" ]] || { echo "转写失败: $WHISPER_DIR/$JSON 不存在"; exit 1; }

echo ">> [2/3] 打印 whisper segments（核对歌词顺序）:"
"$NODE_BIN" -e "
const j = require('$WHISPER_DIR/$JSON');
j.segments.forEach(s => console.log(\`\${s.start.toFixed(1)}s → \${s.end.toFixed(1)}s : \${(s.text||'').replace(/\n/g,'')}\`));
console.log('首段起点:', j.segments[0].start, 's', j.segments[0].start > 2.0 ? '⚠️ 首段 > 2s，BGM 前奏太长不合格！' : '✓ 合格');
"

echo ">> [3/3] 重排剧本时间轴 → $OUT"
"$NODE_BIN" -e "
const fs = require('fs');
const w = require('$WHISPER_DIR/$JSON');
const s = JSON.parse(fs.readFileSync('$SCRIPT', 'utf8'));
const segs = w.segments.map(x => ({start: x.start, end: x.end, text: (x.text||'').replace(/[，。、！？\s]/g,'')}));
// 按对话顺序把 bubble 消息对齐到 whisper 段（第 i 条 bubble ↔ 第 i 个含中文字符的段）
const bubbles = s.elements.filter(e => e.type === 'bubble');
const chineseSegs = segs.filter(x => /[\u4e00-\u9fa5]/.test(x.text));
if(chineseSegs.length < bubbles.length){
  console.error('⚠️ whisper 中文段数('+chineseSegs.length+') < 消息数('+bubbles.length+')，Suno 可能漏唱，需检查');
  process.exit(1);
}
bubbles.forEach((b, i) => {
  const seg = chineseSegs[i];
  b.start_ms = Math.round(seg.start * 1000);
  b.duration_ms = Math.max(800, Math.round((seg.end - seg.start) * 1000));
});
fs.writeFileSync('$OUT', JSON.stringify(s, null, 2));
console.log('已对齐', bubbles.length, '条消息 →', '$OUT');
"
