---
name: chat-rap-video
title: "chat-rap-video 抖音说唱Rap风格微信聊天视频生成"
description: "输入一个场景想法，一键生成抖音说唱rap风格的微信聊天爆款视频：完整微信界面（状态栏/导航栏/聊天区/输入栏）+上下大黑边+聊天气泡居中+大黄字rapper hook+绿色光柱+文字特写+表情包砸入+stack堆叠。严格参考抖音'用说唱的方式打开和老板的聊天对话框'风格。剧本→BGM(Flova Mureka/Suno)→节拍分析→逐帧渲染→ffmpeg合成→CloudStudio部署手机预览。Codex/WorkBuddy通用。"
triggers:
  - 抖音说唱聊天视频 / rap聊天视频 / 说唱rap微信聊天
  - 用说唱的方式打开聊天对话框
  - 黑人说唱聊天视频 / 玩梗聊天视频
  - 复刻抖音聊天爆款视频 / chat rap video
---

# chat-rap-video —— 抖音说唱Rap风格微信聊天视频生成

## 这是什么

复刻抖音"用说唱的方式打开和老板的聊天对话框"风格（黑人说唱BGM + 微信聊天对话框 + 玩梗）。用户只给一个场景想法（如"便宜运营 vs 怨种老板"、"开放二房能提高出生率？"），本 skill 完成：

```
场景想法
  → ① 剧本生成（冲突/角色/反转 + 元素时间轴 JSON）
  → ② 说唱 BGM（Flova CLI 调 Mureka/Suno；无则本地兜底）
  → ③ BGM 节拍分析（毫秒级）
  → ④ 逐帧渲染（playwright 按节拍时间渲染 HTML 画布）
  → ⑤ ffmpeg 合成成片（9:16 竖屏 1080x1920）
  → ⑥ CloudStudio 部署手机预览（可选，用户要看手机效果时）
```

## 严格参考抖音原版（2026-08-11 v5 实测版）

**先下载参考视频逐帧分析再开工**（用 douyin-download skill 下载到 `~/Desktop/douyin video/`，ffmpeg 每隔 2-5s 抽帧，Read 逐帧看布局/节奏/特效时机）。原版核心特征：

1. **上下大黑边**，中间只显示一条微信聊天截图，不是完整手机界面常驻
2. **每个气泡单独展示**：镜头缩放聚焦到当前气泡，不是整屏聊天记录滚动
3. **hook 大黄字**：黑色背景中央弹出"推进？"级大字（黄底黑描边）
4. **特效层**：绿色光柱、文字特写放大（textzoom）、表情包砸入、stack 堆叠
5. **说唱人声就是聊天文字的演绎**：BGM 带 rapper 人声，唱的就是对话内容
6. **转场快**：消息间隔 1-2s，镜头频繁切换，鼓点带震动

## 视觉规范（**v11 纯聊天条白带版，默认用这个**）

**模板：`assets/chat_template_v11.html`**（v8 大动画系统 + v11 纯聊天条白带布局 + 入场动画 10 种随机 + 表情包，用户 2026-08-12 定稿）

> ⚠️ **v11 相对 v8 的关键差异**：删掉完整微信 UI（状态栏/导航栏/输入栏），每条消息自带白带背景横跨全屏、整段轻微旋转 ±3-5°、多条消息垂直堆叠不同 y、入场/退场动画随机。下表为 v8 时代布局，**以 v11 章节（文末）为准**。

| 元素 | 规范 |
|------|------|
| 画布 | 1080×1920 9:16 竖屏，背景纯黑 #000 |
| **布局（用户 2026-08-11 定稿）** | **聊天框居中，占总画面 40-60%**；**上方 0-40% 是「重点信息区」**——放放大的聊天重点文字（hook/textzoom）和元素动画（表情包/光效），**聊天框内只呈现聊天内容**，两者分离 |
| **UI 生命周期（用户 2026-08-11 定稿）** | **开场 3-5 秒**显示完整微信界面（状态栏+导航栏+输入栏，让人看出"这是微信"）→ **之后 UI 全部淡出隐藏**（`#phone background: transparent`，输入栏 display:none），画面只留「头像+气泡」消息条，干净利落 |
| **消息保留策略（用户 2026-08-11 定稿）** | 画面**保留最近 4-6 条消息**（KEEP_MSGS=6），更早的淡出；**新消息在底部弹出，旧消息往上滑**（每条消息元素自身 translateY(-scrollY)，容器不动），模拟微信滚动记录 |
| 结构 | `#camera`(可缩放/平移) 包 `#phone`(完整微信界面) + 特效层(overlays) |
| 状态栏 | iOS 时间/信号/WiFi/电量（#status-bar） |
| 导航栏 | 返回 + 联系人名 + 三点菜单（#nav-bar） |
| 聊天区 | 消息**稀疏排列**（MSG_GAP=420px），每个镜头只显示当前气泡 |
| 输入栏 | 语音+输入框+表情+加号（#input-bar） |
| 气泡 | 微信经典色：白 #fff(对方)/绿 #95ec69(自己)，PingFang SC 34px，方形圆角头像 |
| 镜头 | `setCameraForMsg(msgIdx, mode, scale)`：焦点 `targetScreenY=1000`（**屏幕居中**，不要放太低！） |
| 镜头模式 | `full`(0.32完整界面，6200px phone 缩放后完整显示；0.78 会裁掉下半) / `bubble`(1.35气泡特写) / `text`(1.55文字特写) |
| 横向偏移 | 右侧消息 `camOffsetX=-220`，左侧 `+220`，防气泡裁切（**左侧用 220，原来 150 太小，左侧气泡会被裁切**） |
| hook | 大黄字 260px #ffe600 + 黑描边，**放上方重点信息区（top 8-35%），不盖聊天框**；背景压暗 dim 0.55 |
| beam | 绿色光柱 #7fff00 从**上方重点区**降下/底部升起，配合爆发词 |
| textzoom | 单字/短语放大特写（180px），**放上方重点信息区**，配 dim 0.4 |
| sticker | 表情包 360px scale+rotate 砸入，**放上方重点信息区（y 100-550）做动画**；支持 `src`(图片) 或 `emoji`(字符) |
| stack | 同条消息重复 N 次纵向堆叠（clone y 偏移 45px，水平错开 25px） |

**脚本里 sticker 的 y 坐标放上方重点区**（~150-550），别放中部跟聊天框重叠。

| 字幕（用户 2026-08-11 定稿） | **根据说唱内容生成字幕，每条 ≤15 字**；说唱内容=聊天文字时，字幕就是聊天文字。v6 模板自带字幕层（#subtitle）：屏幕底部大字白字黑描边，自动跟随当前激活消息（activeEl）的文字（取首行、截断 15 字）。**字幕跟随消息时间轴 = 跟随 whisper 对齐后的人声**（消息 start_ms 已按 whisper 段起点排布，见第 2.5 步），人声唱到哪句字幕正好显示哪句（卡拉 OK 级同步） |
| 情绪动画（用户 2026-08-11 定稿） | **聊天框根据消息情绪做对应动画**（元素可选 `emotion` 字段，默认 normal）：`surprise`惊讶→聊天框裂开抖动（scaleX 震 + 中缝裂缝）、`excited`兴奋→微笑弯曲（下边框变弧）+轻微抖动、`angry`生气→左右晃动+倾斜+红色调、`sad`难过→下沉+压扁+灰调、`laugh`大笑→左右摇摆+弹跳、`zoom`放大强调→整体轻微放大。动画强度随时间衰减，自动复原。**⚠️ 只用 scale + filter 实现，禁止 rotate/translate**（会把 #phone 布局带飞，消息移位/消失） |
| 聊天框动态大小（用户 2026-08-11 定稿） | **聊天框大小不固定不变**：①全局轻微"呼吸"（幅度 0.8%、周期 ~4s 缓慢放大缩小，画面不死板）；②**每条消息进入时轻微放大脉冲**（scale 1→1.03→1，前 450ms，跟说唱节奏同拍）；③情绪动画优先级最高。**不是每时每刻剧烈变**，保持自然节奏感 |
| 气泡尺寸（用户 2026-08-11 定稿） | 聊天条整体**放大 1.5 倍**：气泡文字 50px、头像 126px 方形圆角、气泡间距加大、画面保留 5-6 条。**气泡文本不换行**（脚本生成时 `text.replace(/\n/g,'')` 合并单行） |
| z-index（用户 2026-08-11 定稿） | `#messages` 显式 `z-index:0`，确保导航栏 `#nav-bar`(z-index 50) 永远盖在消息上面——**消息上滑经过导航栏时被裁切隐藏，不能遮住对方昵称栏** |

## 前置依赖（已就绪）

- node 22 (managed) + playwright-core chromium（逐帧截图）
- ffmpeg-static（视频合成）
- **Flova CLI**（说唱BGM，需会员 + credits；装：`curl -fsSL https://cli.flova.ai/install.sh | sh`，登：`flova auth login --no-browser`）
  - Music/Narration: 1-5 credits/首
  - 长音乐用 Mureka，短音乐用 Suno（苍何经验）

## 剧本 JSON 格式（agent 生成）

```json
{
  "title": "开放二房能提高出生率？",
  "header": {"back": "<", "name": "专家老张"},
  "characters": [
    {"id": "expert", "side": "left",  "name": "专家老张"},
    {"id": "me",     "side": "right", "name": "我"}
  ],
  "avatars": {"expert": "expert.png", "me": "me.png"},
  "elements": [
    {"id":"e1","type":"bubble","from":"expert","text":"在？","start_ms":1000,"duration_ms":1200,"camera_mode":"full"},
    {"id":"e2","type":"bubble","from":"me","text":"在呢专家～","start_ms":2200,"duration_ms":1600,"camera_mode":"bubble"},
    {"id":"s1","type":"sticker","src":"loopy.png","start_ms":2400,"x":80,"y":720,"duration_ms":1400},
    {"id":"h1","type":"hook","text":"推进？","start_ms":7300,"duration_ms":1700},
    {"id":"b1","type":"beam","start_ms":12800,"duration_ms":1800},
    {"id":"z1","type":"textzoom","text":"怕？","side":"right","start_ms":12900,"duration_ms":1500},
    {"id":"e9","type":"stack","from":"me","text":"房 教 老！","start_ms":14400,"repeat":3,"step_ms":180,"duration_ms":2400,"camera_mode":"bubble"},
    {"id":"h3","type":"hook","text":"散会！","start_ms":32000,"duration_ms":2600}
  ]
}
```

**元素类型**：`bubble`(聊天气泡,可带 camera_mode + emotion) / `stack`(堆叠ad-lib, repeat+step_ms) / `hook`(大黄字) / `sticker`(表情包, src或emoji + x+y) / `beam`(绿色光柱) / `textzoom`(文字特写, side+text) / `flash`(白条转场)

**铁律**：
- 每条 `start_ms` 落在 BGM 重音/鼓点上；消息 duration 要**无缝衔接**（前一条结束≈后一条开始，避免黑屏空隙）
- **时长 = 内容自然长度（用户 2026-08-11 确认）**：20-35 条元素（不是 8-12 条！），**不为凑 60/90/120 秒而人为拉长 duration/加停顿**；5 幕结构（钩子→铺垫→冲突→反转→爆点）；共鸣点优先；最后一条炸（"散会！/拜拜！"级 hook）
- 剧本 `duration_ms` 总和要覆盖 BGM 全长，别留大段空档
- **说唱词 = 完整聊天文字**：BGM 歌词 = 全部对白逐句按顺序排列，不许跳过或改写（敏感词处理见下）
- **消息文案写作规范（用户 2026-08-11 定稿）**：
  - 两人来回对话，**每轮一方连发 1-3 条**，交替推进
  - **每人总回复 12-15 条**（合计 24-30 条）
  - **每条 ≤12 字（5-10 字最佳）**，口语化、有节奏、句尾尽量押韵，方便 rapper 直接唱；长句拆成多条短句
  - **全片至少 1-2 个梗**（共鸣梗：工资低/被画饼/加班/KPI/年龄焦虑；笑点梗：反转/自嘲/拆穿），最好一个"一句封神"的爆梗结尾
  - 故事线走 5 幕（报价→砍价→画饼→拆穿→跑路），拒绝水话

## 使用流程（agent 按此执行）

所有脚本在 `scripts/`。工作目录建议 `<项目目录>/`，产出放 `out/`。

### ⭐ 第 0 步：对话审阅确认（用户 2026-08-11 定稿，必做！）

**用户给主题后，第一步【只生成完整对话内容】给他审阅，等他确认后再往下跑。** 流程：

1. 按「聊天内容生成规则」生成**完整微信对话**（每人 12-15 条、来回 1-3 条、1-2 个梗、每条 ≤12 字适合说唱）
2. 用聊天窗口格式**在回复里展示完整对话**（标注角色：老板/我，气泡方向），**不要直接生成视频**
3. 明确问用户：「对话确认后我就跑视频」——等他说"确认/可以/OK"再进第 1 步
4. 用户要改：按反馈调整对话，重新展示，再等确认

> 铁律：**未经用户确认对话，禁止继续生成 BGM/渲染/合成**。用户说"直接开干/直接生成视频"时才跳过确认。

### 第 0.5 步：参考原版（可选但推荐）

用户给抖音链接时：用 douyin-download skill 下载 → ffmpeg 抽帧 → Read 逐帧分析布局/节奏/特效 → 严格按原版只换主题和头像。

### 第 1 步：头像/表情包（可选）

- 真实人像头像：ImageGen 生成（"realistic WeChat profile avatar photo..."）→ 存 `assets/expert.png` / `assets/me.png`
- 表情包：ImageGen 生成或 emoji 兜底（模板 sticker 支持 emoji）

### 第 2 步：BGM（说唱人声，**时长 = 内容长度**）

```bash
bash scripts/gen_rap_bgm.sh --prompt "中文说唱 吐槽 快节奏 押韵 魔性洗脑" --long --out out/bgm.mp3
```
- **时长要求（硬指标）**：**BGM 必须 ≥ 视频内容长度**（说唱覆盖全程不提前结束）。BGM 生成时按内容预估时长要求（"约 X 秒"），用 Mureka（长音乐）优先，Suno 短。**若生成版比内容长：可裁剪 BGM 尾部（说唱唱完后的尾奏）到匹配内容长度，但别截到唱段**（用 silencedetect 找尾奏起点再裁）。
- **要 rapper 人声**：prompt 里必须写"必须有真人感强烈的 rapper 人声演唱，不要纯音乐，**人声从第 0 秒就开始唱，禁止任何前奏/纯伴奏 intro，全程都有说唱人声**"（2026-08-12 实测：不强调"0 秒开唱"时 Suno 会加 30s 前奏）。
- **说唱歌词严格按聊天文字**：把**全部对白逐句**写进 prompt 的歌词段落，一条不漏。
- **⚠️ Flova 敏感词坑（实测）**：`开放二房/三胎/出生率/国家政策` 等词直接 20011 拒绝；"三胎"也会连带拒。对策：歌词做必要替换（如"开放二房"→"多一个选择"，"三胎开放"→"这事儿"），**但聊天画面文字严格保留原主题**。生成成功是 2-4 个候选版本，**用 ffprobe 挑时长 ≥ 视频目标时长的那版**。
- **时长校验（生成后必做）**：
  ```bash
  ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 out/bgm.mp3
  ```
  若 < 视频目标时长：① 换更长候选版本；② 或重新生成（加大时长要求）；③ 合成脚本会自动 aloop 循环兜底，但**优先保证原生 BGM 够长**（循环会有接缝）。
- 无 Flova：放音乐到 `config/bgm/` 或加 `--fallback /path/x.mp3`

### 第 2.5 步：whisper 时间戳对齐（**必须！解决说唱/字幕不同步**）

用户反馈"Suno 生成的说唱和视频内容不同步"——根因：
- Suno 默认会加 **前奏/纯伴奏**，说唱从 30s 后才开始（whisper 转写实测确认）
- Suno **自动打乱歌词顺序**，不会严格按输入顺序唱，前 7 条可能完全没唱
- 画面按均匀时间轴排消息，跟说唱真实时间错位

**修复流程（必做）**：**直接用封装好的脚本一键完成（推荐）**：

```bash
bash scripts/whisper_align.sh --bgm out/bgm.mp3 --script script.json --out script_aligned.json
# 脚本自动：whisper 转写 → 打印 segments（核对歌词顺序）→ 重排时间轴
# 渲染时用 script_aligned.json（消息时间轴已对齐人声），字幕自动跟随
```

手工步骤（了解原理，排查时用）：

```bash
# 1) 重新生成 BGM，prompt 强调「人声从第 0 秒开始，禁止前奏，全程说唱」
# 2) whisper 转写拿真实时间戳（PATH 加 ffmpeg-static，否则 whisper 找不到 ffmpeg）
export PATH="$(dirname "$CHAT_RAP_FFMPEG"):$PATH"
HTTPS_PROXY= HTTP_PROXY= https_proxy= http_proxy= \
  $CHAT_RAP_WHISPER bgm.mp3 \
  --language zh --task transcribe --output-format json --output-dir /tmp/whisper \
  --model mlx-community/whisper-small-mlx   # large-v3 缓存缺 weights.npz 时用 small 兜底

# 3) 读 JSON 的 segments 数组，每个 segment 是 {start, end, text}（秒）
# 4) **消息时间轴按段起点重排**：每条 bubble 的 start_ms = 对应段 start * 1000，
#    duration_ms = (end - start) * 1000；字幕自动跟随（模板跟随 activeEl 时间轴）
# 5) **首段 ≤ 2.0s 是硬指标**：whisper 检测首段起点必须 ≤ 2 秒，否则 BGM 不合格需重生成
```

**剧本字段铁律**：
- `from` 字段必须用 CHARACTERS 中的 ID（`'aunt'`/`'me'`/`'expert'`），**绝不能图省事用 emotion 字段**（否则 AVATARS[from] 永远是 undefined，avatar 显示空色块）——2026-08-12 实测踩坑
- emotion 字段用独立 emotion 值（ `'laugh'`/`'zoom'`/`'excited'`/`'angry'`/`'sad'` 等）

### 第 3 步：节拍分析（用于 hook/动画卡点）

```bash
FFMPEG_BIN="$FFMPEG_BIN" "$NODE_BIN" scripts/analyze_beats.js --bgm out/bgm.mp3 --out out/beats.json
```
> 视频总时长 = beats.duration_ms（render_frames 按此渲染帧数）。**BGM 必须 ≥ 此值**，说唱才不提前结束。
> **注意**：消息气泡时间轴用 whisper 段起点（第 2.5 步）对齐人声；节拍只用于 hook 大字/textzoom/sticker 等特效卡重拍。

### 第 4 步：逐帧渲染（**v11 模板，默认**）

```bash
NODE_PATH="$NODE_PATH_DIR" CHROME_BIN="$CHROME_BIN" \
  "$NODE_BIN" scripts/render_frames.js \
  --script script_aligned.json --beats out/beats.json \
  --template "$SKILL_DIR/assets/chat_template_v11.html" \
  --assets ./assets --out out/frames --fps 30
```
> 模板已支持长剧本：`#phone` 高度按消息数动态撑高（25-35 条消息 OK）。
> **v11 特性**：纯聊天条白带（无 UI 元素）+ 入场动画 10 种随机（乘法哈希分散）+ 退场随机 + 大动画系统（每 4 条 fly-in/spin-in/slam/zoom-punch）+ 全屏冲击波/光带 + hook 大弹性 + 表情包（emoji/贴纸混合）。

### 第 5 步：合成成片（音频全程覆盖）

```bash
bash scripts/compose_video.sh --frames out/frames --bgm out/bgm.mp3 --out out/final.mp4
```
> compose_video.sh v2：**不用 -shortest**（那是音频被截断提前结束的元凶）。BGM 短于视频时 `aloop` 循环补长到覆盖全程，BGM 长于视频时 `-t 视频时长` 截取，说唱不会提前消失。

### 第 5.5 步：音频对齐校验（必做！）

```bash
# 视频总时长 vs 音频总时长（应一致）
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 out/final.mp4
# 用 silencedetect 检查音频尾部是否有大段静音（说唱提前消失的迹象）
ffmpeg -i out/final.mp4 -af silencedetect=noise=-40dB:d=2 -f null - 2>&1 | grep silence_end | tail -3
```
- 音频时长 < 视频时长 → 合成脚本未生效，检查 BGM 是否够长
- 尾部大段静音 → 说唱人声提前结束（Suno 生成的歌常有人声少伴奏长的毛病），重新生成并强调"全程人声"

### 第 6 步：关键帧检查（必做！）

120 秒视频按前/中/后段各抽 4-6 张，覆盖每幕开头：

```bash
for t in 2 6 10 14 18 22 26 30 34 38 42 46 50 54 58 62 66 70 74 78 82 86 90 94 98 102 106 110 114 118; do
  ffmpeg -y -ss $t -i out/final.mp4 -vframes 1 -q:v 2 out/check_${t}s.jpg
done
```
Read 抽查 8-12 张关键帧，核对：
- 气泡是否完整（左右裁切 → 调 `camOffsetX`）
- 画面是否居中（太低 → `targetScreenY` 调到 1000）
- hook/beam/sticker/stack 是否正常出现、是否重叠
- 有无黑屏空隙（消息 duration 要衔接上）
- **中后段消息是否还在正常轮换**（120 秒长剧本容易在 1/3 处后消息布局错乱）

### 第 7 步：生成封面图（**必做**，跑完视频自动出，不等用户说）

**跑完视频直接生成封面**（用户 2026-08-11 定稿：给主题 → 跑视频 → 直接出封面 → 聊天框交付）。用 ImageGen 生成 **16:9 横版 + 9:16 竖版** 两张，输出到 `out/cover/`。**封面规范（用户定稿）**：

| 要素 | 要求 |
|------|------|
| 背景 | **纯白**（不是黑红撞色！用户明确要白底） |
| 主体 | 一台超大 iPad **占画面 70-80%**，居中或略偏 |
| iPad 屏幕 | 显示**微信聊天界面**：浅灰背景、左侧白色气泡/右侧绿色气泡、顶部联系人栏、底部输入框 |
| 聊天文字 | **清晰显示视频内容里的聊天信息**（用视频关键台词，如"我们预算就20"/"99一场 童叟无欺"/"我虽然便宜 但我不傻"） |
| 大标题 | iPad 顶部覆盖深色半透明横幅，**巨大黄色粗体中文标题 + 白色描边**（如「便宜主播 VS 抠门老板」） |

**ImageGen prompt 模板**（填实际内容）：
```
视频封面图，{16:9 横版 | 9:16 竖版}，纯白背景。画面中央是一台超大的 iPad 平板电脑，占画面 70%-80%，iPad 屏幕清晰显示微信聊天界面：浅灰背景，左侧白色气泡写着「{老板台词1}」和「{老板台词2}」，右侧绿色气泡写着「{主播台词1}」和「{主播台词2}」，气泡文字清晰可读，顶部联系人栏写着「{联系人名}」，底部有输入框。iPad 顶部覆盖一条深色半透明横幅，上面用巨大的黄色粗体中文大字写「{大标题}」，白色描边，字非常清晰醒目。整体简洁干净，白色背景，高清，对比强烈。
```
尺寸：横版 `1536x1024`，竖版 `1024x1536`，quality=high。

**注意**：
- 每张约 5-10 credits，两张共 10-20，生成前告诉用户。
- AI 生图对**中文气泡文字还原可能不准**（个别字乱码）→ 气泡台词只保留 1-2 条超短句（≤8 字）提升准确率；大标题中文一般较准。

### 第 8 步：聊天框交付（**必做**，一步到位）

**① 保存到桌面（必做，用户 2026-08-12/13 定规矩）**：视频和封面**必须**复制到 `~/Desktop/ai/抖音发视频/<日期>/`（日期格式 YYYY-MM-DD，如 `2026-08-13`）：

```bash
DEST="$HOME/Desktop/ai/抖音发视频/$(date +%Y-%m-%d)"
mkdir -p "$DEST"
cp out/final.mp4 "$DEST/<主题>-<版本说明>-<时长>秒.mp4"   # 例：甲方虐我千百遍-v11表情随机动画版-53秒.mp4
cp out/cover/<16x9封面> "$DEST/封面16x9.png"
cp out/cover/<9x16封面> "$DEST/封面9x16.png"
```

**② 聊天框交付 = present_files 一次传全部**（用户 2026-08-11 定稿：最后在聊天框交付，聊天框里可直接预览）：
- 传入：`out/final.mp4`（视频，聊天框自动播放）+ `out/cover/` 下 16:9、9:16 两张封面
- 顺序：视频放第一（优先展示），封面随后
- 文字说明：**桌面保存路径** + 文件路径 + 视频时长 + 封面要点 + credits 消耗

### 第 9 步：CloudStudio 部署手机预览（可选，用户要看手机效果时）

用户说「发到手机/手机预览」时才部署：
```bash
mkdir -p deploy && cp out/final.mp4 deploy/video.mp4
```
deploy/index.html 用竖屏 video 播放页（autoplay+loop+muted+全屏），然后调 `workbuddy_cloudstudio_deploy`：**先 unpublish 旧部署再 deploy 新目录**，把新 shareLink 发给用户。
> **缓存策略（2026-08-11 实测）**：更新视频后**必须 unpublish 旧部署再 deploy**（同一链接直接覆盖可能被 CDN/浏览器缓存，用户看到旧画面）。用户反馈"还是旧画面"→ 先重新 unpublish+deploy 换新链接，同时提醒用户强制刷新/换新链接，再排查视频本身。

### 一键跑通

```bash
bash scripts/run.sh --script script.json --out ./out [--bgm music.mp3] [--prompt "..."]
```

> **完整流程速览（agent 执行顺序）**：
> 1. 第 0 步：出对话 → 等用户确认
> 2. 第 1 步：头像/表情包（ImageGen + OpenMoji 混合，表情不局限 emoji）
> 3. 第 2 步：Flova 生成 BGM（prompt 强调"人声第 0 秒开唱"）
> 4. **第 2.5 步：`whisper_align.sh` 转写对齐时间轴（必做）**
> 5. 第 3 步：analyze_beats 节拍（hook 卡点用）
> 6. 第 4 步：render_frames（**用对齐后的 script_aligned.json + v11 模板**）
> 7. 第 5/5.5 步：compose + 音频对齐校验
> 8. 第 6 步：关键帧/亮度/DOM 自审
> 9. 第 7 步：封面（16:9 + 9:16）
> 10. 第 8 步：**存桌面 `~/Desktop/ai/抖音发视频/<日期>/`（必做）** + present_files 聊天框交付；用户要手机预览才第 9 步部署

## 执行注意（给 agent）

- **花钱边界**：Flova CLI 需会员（月费真钱）+ credits（1-5/首音乐）。提交生成前必须向用户复述 prompt/模型/预估 credits 再确认。ImageGen 生成头像/表情包每张约 5-10 credits，也要先说。本地 ffmpeg/截图/渲染不花钱。
- **Flova 会员坑**：免费账号有 100 credits 但 `is_vip:false` → CLI 创建项目被拒（`membership_required`）。需买会员才能用 CLI。
- **素材**：avatars/sticker 的 src 图片放 `assets/` 目录，无则模板用 emoji 兜底（sticker 支持 `emoji` 字段）。
- **网络**：Flova/外网访问需 unset 沙箱代理（lib.sh 提供 `unset_proxy`）。
- **渲染耗时**：30fps × 视频时长 = 帧数 ≈ 时长×2 秒/帧渲染（playwright 逐帧截图，长视频耐心等，勿中断）。74s ≈ 2239 帧 ≈ 2 分钟。
- **剧本质量**：20-35 条元素、5 幕结构、共鸣点优先，反转/爆点在最后，这是流量密码。
- **音频 > 视频长度**：说唱人声要覆盖全程，BGM 必须 ≥ 视频时长；人声少伴奏长（Suno 通病）→ 重新生成强调"**人声第 0 秒开唱**"。
- **whisper 转写注意（2026-08-12 实测）**：
  - 模型缓存：`~/.cache/huggingface/hub/models--mlx-community--whisper-*/`，large-v3-mlx 缺 `weights.npz` 无法用，**用 whisper-small-mlx**（含 weights.npz）兜底
  - whisper 依赖 `ffmpeg` 命令 → 必须 `export PATH="$(dirname ffmpeg-static):$PATH"`
  - 转写耗时长（74s 音频 ≈ 2 分 40 秒），后台跑别中断
  - 转写结果 JSON 在 `--output-dir` 下，读 `segments[].{start,end,text}`（秒）
- **v4/v5/v6/v7/v8 演进经验**（改模板时参考）：
  - v4 加了 `#camera` 缩放脉冲/微震，但消息连续排列、镜头死板
  - v5 改为消息稀疏排列 + 每镜头只显示当前气泡 + 镜头缩放聚焦，才真正像原版
  - `#phone` 高度**动态撑高**（按消息数算，6200px 起），120s 长剧本 25-35 条消息 OK
  - 右侧消息 camOffsetX -220、左侧 +220，防气泡裁切
  - compose_video.sh **不用 -shortest**（音频会被截断），用 aloop 循环补长 + `-t 视频时长`
  - **v7（2026-08-12 用户指定参考抖音 https://v.douyin.com/SlIGgVlDbBk/「汽水AI写歌教程」）升级动画风格**：
    - **气泡硬切弹入**（80ms 内）：从 X 轴 ±60px + scale 0.85→1.0 进入，**不淡入**（参考抖音原版）
    - **气泡抖动 + 轻微倾斜**：每条气泡出现后随机微小 wobble（±2px X/Y）+ 整体旋转 ±1.5°
    - **hook/beam 倾斜入场**：hook 大黄字和绿色光柱**初始旋转 ±3°** + 入场后微抖
    - **sticker 横跨黑边**：sticker y 可设 `< 80` 或 `> 1700`，让其超出聊天框（贴上下边缘）
    - **持续 wobble**：相机 `#camera` 每 2s 周期微小 scale 0.99-1.01 + rotate ±0.3°（画面始终有生命感）
    - 节奏收紧：消息 `duration_ms` 建议 1800-2600ms（不超 3000ms）
  - **v8（2026-08-12 用户"动画要有艺术感、幅度要偶尔大"）大动画系统**：
    - **每 4 条消息触发一次大动画**（消息序号 4/8/12/16/20/24...），其余保持 v7 小动画
    - **大动画类型池**（按消息序号轮流）：`fly-in`（屏幕外飞入 ±1100px + 回弹）、`spin-in`（旋转 540° 入场）、`slam`（从下方 900px 砸入 + 弹性 bounce）、`zoom-punch`（大脉冲 0.3→1.0 + 0.12 压扁过冲）
    - **大动画持续 650ms**（比小动画 80ms 长，有镜头感）
    - **全屏冲击波 + 光带同步**（大动画触发时）：`.shockwave` radial gradient 圆环 0.1→14 倍 scale + `.light-sweep` linear gradient 斜扫过
    - **hook 大弹性入场**：大弹性 easeOutElastic + 入场 -14° 倾斜 + scale 0.3→1.15 超调
    - **stack 每层带旋转**（不是只平移）
    - **angry emotion 不用 hue-rotate**（会把绿气泡变黄，v8 改用 saturate 1.2 + brightness 0.92 表达情绪沉重）
  - **保留**（用户已稳定认可）：聊天框居中 + 上方重点区 + UI 淡出 + KEEP_MSGS + 字幕 + 情绪动画 + from 字段铁律 + whisper 对齐
- **逐帧渲染两大致命坑（2026-08-11 实测，全黑元凶）**：
  - ⚠️ **CSS transition 陷阱**：模板元素（.msg/#subtitle/#dim）**不能加 CSS transition**！renderAt 每帧先 reset 再设目标值，transition 导致每帧都在过渡中，截图时 opacity 只有 ~10%，画面几乎不可见（DOM 查 opacity=1 但截图全黑）。动画全部用 JS 按帧算，不要 CSS transition。
  - ⚠️ **容器 transform 移出 overflow 区**：滚动不能 `#messages transform: translateY(-N)`（transform 把容器视觉移出父级 overflow:hidden 裁切区 → 内容全被裁掉，20s 后全黑 YAVG=16）。**滚动要改为每条消息元素自身 translateY(-scrollY)**，容器不动、overflow 正常裁切。
  - 排查手段：playwright 截图 + ffmpeg signalstats 亮度（YAVG=16 全黑 / 200+ 有 UI / 30-60 有消息）+ 红色背景测试（body 设红看截图是否红，判断是截图问题还是元素问题）。
- **交付前自审清单（必做，2026-08-11 定稿）**：
  1. **亮度扫描**：抽 7-10 个时间点（开头/中段/结尾），`ffmpeg crop+signalstats` 测中部和底部区域亮度——全黑=内容没了，全亮=UI 没隐藏
  2. **DOM 扫描**：playwright 逐时间点打印 overlays 子元素（应只有预期 hook/sticker/beam，**无残留元素**）+ 检查 flash-bar 每帧 reset（height=0 opacity=0，防白条残留）
  3. **黑屏检测**：`blackdetect=d=1:pix_th=0.10` 应无输出；**底部区域**单独测（输入栏 display:none 后应全黑，无绿色/灰色残留）
  4. 全部通过再交付
- **用户反馈"旧画面"先怀疑缓存（2026-08-11 实测）**：用户截图说"整个视频都有蓝线/灰底聊天框/绿色底部"，但抽帧验证新视频完全干净 → 结论是他手机/浏览器**缓存的旧版本**。处理：`unpublish` 旧部署 → 重新 `deploy`（换新链接）→ 明确告诉用户"你看到的旧画面是缓存，请用新链接 + 强制刷新"。另外**截图里蓝椭圆+斜线常是 macOS 自带截屏工具画的标注**（圈问题点用），不是视频内容，先抽帧确认再判断。

## v11（2026-08-12 用户指定参考抖音 https://v.douyin.com/AIAF8BFqhT4/「王总又作妖了·律师的真实日常」）纯聊天条白带布局

**核心特征**（参考视频拆解）：
1. **去完整微信 UI**（删 `#status-bar` / `#nav-bar` / `#input-bar`），保留 `#phone` 但背景改 `transparent`（黑底透出）
2. **每条消息元素自带白带背景**：`background:#ededed` + `box-shadow:0 4px 20px rgba(0,0,0,0.3)` + `padding:30px 50px`，整段白带横跨全屏宽度（`left:-40px;right:-40px`）
3. **整段聊天条轻微旋转/倾斜**（入场和停留时 `rotate(±3-5°)` + 持续 wobble）——参考视频核心特征
4. **多条消息垂直堆叠在不同 y 位置**（每条 y 320 + msgIndex*73 % 400 散布），不是单条固定位置
5. **入场/退场随机系统（保留 v10）**：每条消息随机入场方式（天降/左飞/右飞/旋转/砸入/脉冲/默认弹入），退场随机（向左飞走/向右飞走/向下掉落/淡出）
6. **`#messages` 容器全屏覆盖**（top:0 bottom:0，无 UI 偏移）
7. 配套常量：`UI_HIDE_AT=3500` 保留但实际无 UI（兼容）

**默认模板从 v8 升级到 v11**。

**模板文件**：`assets/chat_template_v11.html`

**v11 重建踩坑**（实测）：
- 用 `Edit` 工具的 `new_string` 用 `<omitted>` 占位符会让模型输出真的占位符字符串，导致 JS 报 `Unexpected token '<'` 或常量未定义错误
- **正确做法**：用 Python `text.replace()` 一次性替换多段内容，不留任何 `<omitted>` 占位符
- 重建后必须检查所有引用的常量是否都已定义：`ANIM_IN / UI_HIDE_AT / KEEP_LIMIT / WOBBLE_AMP / ROT_AMP / BIG_EVERY / BIG_ANIM_MS / ENTER_MS / EXIT_MS / ENTER_TYPES / EXIT_TYPES`
- 缺失任何一个常量渲染脚本会直接报 `ReferenceError`

## v11b：表情包 + 入场动画随机化（2026-08-12 用户要求）

**① 入场动画随机化（修重大 bug）**：
- ⚠️ **原 `enterTypeFor` 有数学 bug**：`Math.abs(idx*7+3) % 7` 对任何 idx 恒等于 3 → **所有消息都同一动画**（spin-in）！这是"每条聊天内容动画都一样"的根因
- ✅ 修复：Knuth 乘法哈希 `((idx*2654435761)>>>0) % ENTER_TYPES.length`，连续 idx 均匀分散
- ✅ 入场类型扩到 10 种：`drop-in / fly-left / fly-right / spin-in / slam / zoom-punch / pop / flip-in(翻转) / bounce-in(弹跳) / slide-up(上滑)`
- ✅ 退场类型同步修复 `exitTypeFor`（乘法哈希）

**② 表情包（网络扒）**：
- 来源：**OpenMoji CDN**（618x618 高清）：`https://cdn.jsdelivr.net/gh/hfg-gmuend/openmoji@latest/color/618x618/<HEX>.png`（Twemoji 512px 目录不存在，别用）
- 下载到 `assets/emoji_1Fxxx.png`（注意：zsh 通配符 `emoji_*.png` 会误删大写开头的文件，用完整文件名引用）
- 剧本里 sticker 元素：`{type:'sticker', src:'emoji_1F602.png', start_ms, x, y, duration_ms}`，x/y 放上方重点区（y 100-450）
- 情绪-表情对照（v12 甲方主题实测）：五彩斑斓的黑→1F92F🤯、量子叠加→1F602😂、今晚有命要保→1F611😑、说不上哪不对→1F62D😭、神仙难办→1F928🤨、记得结款→1F44D👍

## v11c：表情包素材库扩充——多样化不局限 emoji（2026-08-12）

**用户要求**：表情不要只局限 emoji，要猫猫狗狗等可爱贴纸、线条人等多样化风格。

**素材库分类**（assets/ 目录）：

| 类型 | 来源 | 文件示例 |
|------|------|---------|
| **emoji 表情** | OpenMoji CDN（618x618 高清）<br/>`https://cdn.jsdelivr.net/gh/hfg-gmuend/openmoji@latest/color/618x618/<HEX>.png` | emoji_1F602.png（笑哭）、emoji_1F92F.png（震惊）<br/>emoji_1F431.png（猫）、emoji_1F436.png（狗）<br/>emoji_1F43C.png（熊猫）、emoji_1F430.png（兔） |
| **线条贴纸风格** | ImageGen 生成（LINE sticker / 微信贴纸风格）<br/>prompt：`WeChat chat sticker meme, cute line-art style [动物/角色], [表情] face, simple flat design like LINE sticker, thick clean outline` | sticker_dog.png（线条小狗·微笑）<br/>sticker_panda.png（熊猫头·震惊）<br/>sticker_shiba.png（柴犬·挑眉）<br/>sticker_cat_cry.png（灰猫·大哭） |
| **网络扒真表情包** | zhaoolee/ChineseBQB（但 >50MB jsDelivr 拒，需直连 GitHub raw 或单文件下载） | （后续补充） |

**实际选用的多元化表情池**：
- 笑/搞笑：😂笑哭、😅尴尬汗、🤯震惊、🫠融化、🐶狗微笑、🐼熊猫头、🐕线条小狗
- 哭/难过：😭大哭、🐱猫猫大哭、🐰兔子难过
- 生气/无语：😑无语、🐒猴子烦躁
- 卖萌/得意：😀微笑、😏得意、🥰可爱、💖爱心
- 疑问/挑眉：🤨挑眉、🐕柴犬挑眉
- 赞同/祝福：👍赞、🙏双手合十、🤟我爱你手势

**使用规则**（以后做视频必须遵守）：
1. **emoji 风格** 和 **贴纸风格** 混合用，不要一条视频全用同一种风格
2. 优先用 **贴纸风格**（线条小狗/熊猫头/柴犬/猫猫等）作为主表情——更可爱、抖音味更足
3. emoji 风格作为**情绪辅助**（震惊🤯、无语😑等抽象情绪）
4. 表情位置：上方重点区（y 100-450），交叉左右（避免遮挡白带）
5. 表情大小：380px × 380px（sticker CSS 默认）
6. 表情入场景点：情绪最强烈处（hook 触发时/对方无语时/自嘲反讽时）

## v11d：表情素材库扩充 v2——高频梗+去水印（2026-08-13 用户"多贴微信表情图"）

**用户反馈**：表情图还是少了，**下次记得多贴一些微信表情图**。这条不重新生成，扩充素材库 + 写规则到 skill。

**表情库扩充**（assets/ 目录，本次新增 24 个）：

| 类型 | 文件 | 来源 | 情绪用途 |
|------|------|------|---------|
| **OpenMoji 高频表情（20 个新增）** | emoji_1F926（捂脸）/1F644（翻白眼）/1FAE0（裂开）/1F975（流汗）/1F923（笑哭变体）/1F973（笑喷）/1F976（开心）/1F97A（疲惫）/1F60B（墨镜笑）/1F60D（戴眼镜笑）/1F617（笑吻）/1F972（笑哭抱头）/1FAD5（捂脸）/1F480（机器人头）/1F514（红色感叹号）/1F525（火苗）/1F4A6（汗滴）/1F6A8（红车）/1F62A（疲惫脸） | OpenMoji CDN（618x618 高清） | 高频微信聊天的梗情绪 |
| **趣味贴纸（4 个新增）** | meme_dog_sweat（柴犬·汗滴尴尬）/meme_panda_shock（熊猫头·震惊张大嘴）/meme_cat_cool（墨镜猫·土豪酷炫）/meme_monkey（捂嘴猴·偷笑） | ImageGen 生成（LINE 贴纸/微信表情风格） | 网络梗图，比 emoji 更出彩 |

**素材库总数**（截至 2026-08-13）：emoji 47 个 + 趣味贴纸 4 个 + 原 sticker 4 个 + loopy/crycat 2 个 ≈ **57 个素材**

**⚠️ 关键问题（2026-08-13 实测）**：ImageGen 生成图片会带"AI生成 WORKBUDDY"水印，下次必须加 `footnote: ""` 参数去除（输出给用户看的水印很丑）。

**表情使用铁律（2026-08-13 用户定稿，必做）**：
1. **每条视频贴 6-10 个表情**（之前 3-6 个太少）——**默认贴 8 个**，覆盖每个 hook 触发点和情绪转折点
2. **emoji + 贴纸混合**：emoji 表情（OpenMoji） + 趣味贴纸（ImageGen/网络梗图）至少各占 1/3
3. **优先使用贴纸风格**（meme_*.png）作为主表情——更可爱、抖音味更足、网络传播力更强
4. 位置：上方重点区（y 100-450），交叉左右（避免遮挡白带）；stack 堆叠时放大 y
5. 大小：380×380px（sticker CSS 默认）
6. **情绪-表情对照表**（以后视频直接查表）：
   - 震惊/惊讶：🤯 emoji_1F92F、🤨 emoji_1F928、meme_panda_shock
   - 笑/搞笑：😂 emoji_1F602、😅 emoji_1F605、meme_dog_sweat、meme_monkey
   - 哭/难过：😭 emoji_1F62D、sticker_cat_cry
   - 无语/翻白眼：😑 emoji_1F611、🙄 emoji_1F644、sticker_shiba
   - 得意/酷炫：😏 emoji_1F60F、meme_cat_cool、sticker_dog
   - 质问/挑眉：🤨 emoji_1F928
   - 赞同/祝福：👍 emoji_1F44D、🙏 emoji_1F64F
   - 生气/裂开：😡 emoji_1F621、🫠 emoji_1FAE0
   - 疲惫/翻车：😩 emoji_1F629、😮‍💨 emoji_1F97A
   - 阴阳怪气/自豪：🙃 emoji_1F643、sticker_shiba
   - 网友梗：🐶 emoji_1F436、🐱 emoji_1F431、🐼 emoji_1F43C、🐒 emoji_1F435
   - 高能量大梗图：💥 emoji_1F525、❗ emoji_1F514

**ImageGen 调用模板（贴纸用，必须加 footnote 去水印）**：
```js
DeferExecuteTool({
  params: {
    prompt: 'Funny meme sticker, [动物/角色] with [表情] face, internet meme style, thick clean outline, flat cartoon, square sticker, white background',
    output_dir: './assets_<unique>',
    quality: 'high',
    size: '1024x1024',
    background: 'transparent',
    footnote: ''  // ← 必加，去掉 AI 生成水印
  }
})
```

**OpenMoji 批量下载脚本**（以后扩充表情库）：
```bash
for emoji in <hex>; do
  curl -fsSL "https://cdn.jsdelivr.net/gh/hfg-gmuend/openmoji@latest/color/618x618/${emoji}.png" \
    -o "assets/emoji_${emoji}.png"
done
```
