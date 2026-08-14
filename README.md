# 🎤 chat-rap-video

**Generate viral Douyin-style "rap chat" videos** — a WeChat chat interface comes alive with a rap vocal performing the conversation, complete with meme stickers, big yellow hook text, and beat-synced animations.

Replicates the popular Douyin (Chinese TikTok) format *"用说唱的方式打开和老板的聊天对话框"* ("Open the chat with your boss in rap").

> 中文介绍见 [README.zh-CN.md](README.zh-CN.md)

## ✨ What it does

Give it a scenario idea (e.g. *"cheap streamer vs stingy boss"*, *"relatives pressuring a single woman to marry"*), and it produces a complete 9:16 vertical short video:

| Step | What |
|------|------|
| ① Script | Generates a WeChat-style dialogue (2-3 characters, punchlines, hooks) with a timed element JSON |
| ② BGM | Generates a rap/electronic vocal track from the exact chat lines (Flova Mureka/Suno, or local fallback) |
| ③ Beat analysis | Detects ms-level beats for animation sync |
| ④ Frame render | Renders every frame with Playwright against an HTML canvas (WeChat UI + white chat strips + memes + effects) |
| ⑤ Compose | ffmpeg merges frames + audio into a 1080×1920 30fps MP4 |
| ⑥ (Optional) | Deploy a mobile preview page |

## 🎬 Visual style

- **v11 default template**: pure chat-strip layout — each message is a white band spanning the screen with slight rotation, random entry/exit animations (10 types), big yellow hook text, emoji + sticker memes, subtitles synced to the vocal via whisper timestamps.
- Layout rules: message band centered (40-60% of frame), upper area reserved for hook text / memes / effects, subtitles ≤15 chars per line.

## 📦 Installation

Requires: **Node.js 18+**, **ffmpeg**, **Playwright chromium**, and optionally **mlx-whisper** (Python) + **Flova CLI**.

```bash
# 1. Clone
git clone https://github.com/weibo-job/chat-rap-video.git
cd chat-rap-video

# 2. Node deps (playwright + ffmpeg-static)
npm install            # playwright-core ffmpeg-static
npx playwright install chromium

# 3. Optional: MLX whisper for vocal-timestamp alignment (Python)
pip install mlx-whisper

# 4. Optional: Flova CLI for real rap BGM (paid, ~1-5 credits/song)
curl -fsSL https://cli.flova.ai/install.sh | sh && flova auth login --no-browser
```

## ⚙️ Environment variables (paths auto-detect, override when needed)

| Variable | Purpose |
|----------|---------|
| `CHAT_RAP_NODE_BIN` | Node.js executable path |
| `CHAT_RAP_NODE_PATH` | Node modules parent dir (for NODE_PATH) |
| `CHAT_RAP_FFMPEG` | ffmpeg executable path |
| `CHAT_RAP_CHROME` | Chromium executable path (playwright render) |
| `CHAT_RAP_WHISPER` | mlx_whisper executable path |

All paths fall back to auto-detection (`command -v`) and common default locations.

## 🚀 Quick start

### Step 1: Write the script (the core input)

```json
{
  "title": "Cheap Streamer vs Boss",
  "header": {"back": "<", "name": "The Boss"},
  "characters": [
    {"id": "boss", "side": "left", "name": "Boss"},
    {"id": "me",   "side": "right", "name": "Me"}
  ],
  "avatars": {"boss": "boss.png", "me": "me.png"},
  "elements": [
    {"id": "e1", "type": "bubble", "from": "boss", "text": "在？主图再改改", "start_ms": 1200, "duration_ms": 2000, "emotion": "normal", "camera_mode": "bubble"},
    {"id": "e2", "type": "bubble", "from": "me", "text": "老板凌晨两点 我在做梦", "start_ms": 3400, "duration_ms": 2200, "emotion": "laugh", "camera_mode": "bubble"},
    {"id": "h1", "type": "hook", "text": "五彩斑斓的黑", "start_ms": 5600, "duration_ms": 1800},
    {"id": "s1", "type": "sticker", "src": "meme_panda_shock.png", "start_ms": 5800, "x": 640, "y": 180, "duration_ms": 2000}
  ]
}
```

Element types: `bubble` / `stack` / `hook` / `sticker` / `beam` / `textzoom` / `flash`.
Put avatars & sticker images in `assets/` (or alongside the script in an `assets/` folder).

### Step 2: Generate BGM (optional but recommended)

```bash
bash scripts/gen_rap_bgm.sh --prompt "中文说唱 吐槽老板 节奏快 押韵 魔性" --long --out out/bgm.mp3
```

### Step 3: Align vocal timestamps (optional, fixes audio/subtitle sync)

```bash
bash scripts/whisper_align.sh --bgm out/bgm.mp3 --script script.json --out script_aligned.json
```

### Step 4: Analyze beats + render + compose (one-shot)

```bash
bash scripts/run.sh --script script.json --out ./out [--bgm out/bgm.mp3]
# or step-by-step:
FFMPEG_BIN=$(command -v ffmpeg) node scripts/analyze_beats.js --bgm out/bgm.mp3 --out out/beats.json
NODE_PATH=$(npm root -g) CHROME_BIN="$CHROME_BIN" node scripts/render_frames.js \
  --script script.json --beats out/beats.json \
  --template assets/chat_template_v11.html --assets ./assets \
  --out out/frames --fps 30
bash scripts/compose_video.sh --frames out/frames --bgm out/bgm.mp3 --out out/final.mp4
```

Result: `out/final.mp4` — 1080×1920, 9:16 vertical, ready for Douyin/TikTok.

## 🧠 Proven workflow tips (hard-won lessons)

- **Vocal must start at 0s**: always prompt the music model for "vocal from second 0, no intro" — Suno adds 30s intros by default.
- **Verify lyrics with whisper**: never trust duration alone; transcribe and check the full lyric sequence (a 60s "la-la-la" track happens).
- **No `-shortest` in compose**: loop the BGM with `aloop` if shorter than the video, else the rap cuts off early.
- **No CSS transitions in templates**: per-frame rendering resets opacity every frame; transitions make frames nearly invisible. All animation must be JS-computed.
- **No container `transform` for scrolling**: moving the message container out of `overflow:hidden` blackens everything after ~20s. Scroll each message element instead.
- **Randomize entry animations with a real hash**: `(idx*2654435761)>>>0 % len` — naive `(idx*7+3)%7` always equals 3 → every message uses the same animation.
- **ImageGen watermarks**: add `footnote: ""` to strip the "AI-generated" watermark.

## 📁 Repository layout

```
chat-rap-video/
├── SKILL.md                  # Skill definition (agent-readable instructions)
├── prompts/
│   └── script_generator.md   # Script-writing rules & story structure
├── scripts/
│   ├── lib.sh                # Path resolution (env vars + auto-detect)
│   ├── gen_rap_bgm.sh        # BGM generation (Flova / local fallback)
│   ├── whisper_align.sh      # Vocal-timestamp alignment (sync fix)
│   ├── analyze_beats.js      # Beat analysis
│   ├── render_frames.js      # Playwright frame rendering
│   ├── compose_video.sh      # ffmpeg merge
│   └── run.sh                # One-shot pipeline
├── assets/
│   ├── chat_template_v11.html  # Default template (chat-strip layout)
│   └── chat_template_v5..v10   # Historical templates
└── examples/
    └── script.example.json   # Example script
```

## 🤝 Contributing

PRs welcome! Ideas: more entry/exit animations, more meme stickers, TikTok export presets, English UI theme.

## 📄 License

[MIT](LICENSE) — free to use, modify and distribute.

---

*Built by iterating with real Douyin reference videos. Animations and layout follow actual viral formats — not just "AI vibes".*
