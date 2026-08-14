# chat-rap-video —— 抖音说唱Rap风格微信聊天视频生成器

输入一个场景想法，一键生成抖音爆款「说唱打开微信聊天」风格的 9:16 竖屏短视频：微信聊天界面 + 说唱人声演绎对话 + 表情包 + 大黄字 hook + 卡点动画。

## ✨ 功能

| 步骤 | 说明 |
|------|------|
| ① 剧本 | 自动生成 2-3 人微信对话（梗点/钩子/情绪），输出带时间轴的元素 JSON |
| ② BGM | 用对话原话生成说唱/电子人声（Flova Mureka/Suno，或本地兜底） |
| ③ 节拍分析 | 毫秒级检测鼓点，动画卡点 |
| ④ 逐帧渲染 | Playwright 按节拍渲染 HTML 画布（微信界面 + 白色聊天条 + 表情 + 特效） |
| ⑤ 合成 | ffmpeg 合并帧 + 音频 → 1080×1920 30fps MP4 |
| ⑥ 可选 | 部署手机预览页 |

## 🎬 视觉风格

- **v11 默认模板**：纯聊天条布局——每条消息是横跨全屏的白色条带，带轻微旋转；10 种随机入场/退场动画；黄色大号 hook 文字；emoji + 贴纸表情；字幕通过 whisper 时间戳与人声严格同步。
- 布局规则：聊天条居中（占画面 40-60%），上方区域放 hook 大字/表情/特效，字幕每条 ≤15 字。

## 📦 安装

需要：**Node.js 18+**、**ffmpeg**、**Playwright chromium**，可选 **mlx-whisper**（Python）+ **Flova CLI**。

```bash
git clone https://github.com/weibo-job/chat-rap-video.git && cd chat-rap-video
npm install && npx playwright install chromium
pip install mlx-whisper        # 可选：说唱时间戳对齐
curl -fsSL https://cli.flova.ai/install.sh | sh && flova auth login --no-browser  # 可选：付费说唱BGM
```

## ⚙️ 环境变量（路径自动探测，需要时覆盖）

| 变量 | 用途 |
|------|------|
| `CHAT_RAP_NODE_BIN` | Node.js 可执行文件路径 |
| `CHAT_RAP_NODE_PATH` | Node 模块目录（NODE_PATH 用） |
| `CHAT_RAP_FFMPEG` | ffmpeg 可执行文件路径 |
| `CHAT_RAP_CHROME` | Chromium 可执行文件路径（渲染用） |
| `CHAT_RAP_WHISPER` | mlx_whisper 可执行文件路径 |

所有路径优先读环境变量，其次 `command -v` 自动探测，再回退常见默认位置。

## 🚀 快速开始

### 第 1 步：写剧本（核心输入）

见 [examples/script.example.json](examples/script.example.json)。元素类型：`bubble` / `stack` / `hook` / `sticker` / `beam` / `textzoom` / `flash`。头像和表情图放 `assets/` 或剧本旁的 `assets/` 目录。

### 第 2 步：生成 BGM（可选但推荐）

```bash
bash scripts/gen_rap_bgm.sh --prompt "中文说唱 吐槽老板 节奏快 押韵 魔性" --long --out out/bgm.mp3
```

### 第 3 步：whisper 时间戳对齐（修复音画不同步，强烈推荐）

```bash
bash scripts/whisper_align.sh --bgm out/bgm.mp3 --script script.json --out script_aligned.json
```

### 第 4 步：一键跑通

```bash
bash scripts/run.sh --script script.json --out ./out [--bgm out/bgm.mp3]
```

产物：`out/final.mp4` — 1080×1920 竖屏，可直接发抖音。

## 🧠 实战经验（踩坑总结）

- **人声必须 0 秒开始**：prompt 强调"人声从第 0 秒开唱，禁止前奏"——Suno 默认会加 30s 前奏
- **whisper 验证歌词**：不能只看时长，必须转写确认歌词顺序完整（遇到过 60s 纯"哎哎哎"哼唱）
- **合成禁用 `-shortest`**：BGM 短于视频用 `aloop` 循环补长，否则说唱被截断
- **模板禁用 CSS transition**：逐帧渲染每帧重置 opacity，transition 会让画面几乎不可见；动画全部用 JS 按帧算
- **滚动禁用容器 transform**：消息容器移出 `overflow:hidden` 裁切区会导致 20s 后全黑；改为每条消息元素自身滚动
- **入场动画随机用乘法哈希**：`(idx*2654435761)>>>0 % len`——naive 的 `(idx*7+3)%7` 恒等于 3，所有消息同一动画
- **ImageGen 去水印**：生成贴纸加 `footnote: ""` 参数

## 📁 仓库结构

```
chat-rap-video/
├── SKILL.md                  # Skill 定义（agent 可读指令）
├── prompts/
│   └── script_generator.md   # 剧本写作规则与故事结构
├── scripts/
│   ├── lib.sh                # 路径解析（环境变量 + 自动探测）
│   ├── gen_rap_bgm.sh        # BGM 生成
│   ├── whisper_align.sh      # 说唱时间戳对齐
│   ├── analyze_beats.js      # 节拍分析
│   ├── render_frames.js      # Playwright 逐帧渲染
│   ├── compose_video.sh      # ffmpeg 合成
│   └── run.sh                # 一键流水线
├── assets/
│   ├── chat_template_v11.html  # 默认模板（聊天条布局）
│   └── chat_template_v5..v10   # 历史模板
└── examples/
    └── script.example.json   # 示例剧本
```

## 📄 License

[MIT](LICENSE) — 自由使用、修改、分发。
