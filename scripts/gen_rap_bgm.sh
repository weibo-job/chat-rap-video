#!/bin/bash
# gen_rap_bgm.sh —— 抖音说唱Rap BGM 生成（Flova CLI 适配）
#
# 来源优先级：
#   1) Flova CLI（文章原方案说唱BGM，必装）：检测到 → 引导走 Mureka（长说唱）/ Suno（短说唱）
#   2) 本地 BGM 兜底：config/bgm/*.mp3
#
# 用法:
#   bash gen_rap_bgm.sh --prompt "黑人说唱 吐槽老板 节奏快 押韵 魔性" --out bgm.mp3 [--long|--short]
#
# 注意：Flova 生成音乐真实扣费 → 本脚本检测到 flova 后会输出确认提示，
#       不会自动调用模型；agent 需把 prompt/模型/预估费用复述给用户确认后再提交。
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PROMPT=""; MODE="short"; OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt) PROMPT="$2"; shift 2;;
    --long) MODE="long"; shift;;
    --short) MODE="short"; shift;;
    --out) OUT="$2"; shift 2;;
    *) echo "未知参数 $1"; exit 1;;
  esac
done
[[ -n "$PROMPT" && -n "$OUT" ]] || { echo "缺少 --prompt 或 --out"; exit 1; }

BGM_DIR="$SKILL_DIR/config/bgm"
mkdir -p "$BGM_DIR"

# 1) Flova CLI 优先（说唱BGM推荐走 Flova 的 Mureka/Suno）
if command -v flova >/dev/null 2>&1; then
  MODEL=$([ "$MODE" = long ] && echo "Mureka" || echo "Suno")
  echo "============================================================"
  echo "[Flova 路径] 检测到 Flova CLI"
  echo "  prompt: $PROMPT"
  echo "  模型:   $MODEL  ($( [ "$MODE" = long ] && echo "长说唱" || echo "短说唱" ))"
  echo "  输出:   $OUT"
  echo "============================================================"
  echo "⚠️  Flova 生成音乐会真实扣费，请按以下步骤："
  echo "  1) 先把上面的 prompt/模型/预估费用复述给用户，等他确认"
  echo "  2) 用户确认后，按 ~/.flova/SKILL.md 走 Flova 创建音乐项目 + 提交"
  echo "  3) 生成完成后把音频文件保存到: $OUT"
  echo "  4) 然后继续 chat-rap-video 的 render_frames / compose_video 步骤"
  echo "============================================================"
  exit 2   # 2 = 需要 agent + 用户确认后手动走 Flova
fi

# 2) 本地 BGM 兜底（说唱风味不会很准，但能跑通）
CAND=$(ls "$BGM_DIR"/*.mp3 "$BGM_DIR"/*.wav 2>/dev/null | head -1 || true)
if [[ -n "$CAND" ]]; then
  cp "$CAND" "$OUT"
  echo ">> 使用本地 BGM: $CAND → $OUT (无说唱风味，建议改用 Flova)"
  exit 0
fi

echo ">> 未检测到 Flova CLI，本地也无 BGM。请："
echo "   1) 安装 Flova CLI: curl -fsSL https://cli.flova.ai/install.sh | sh 并登录"
echo "   2) 或放一个音乐文件到 $BGM_DIR/"
exit 1