#!/usr/bin/env node
/**
 * render_frames.js —— 按 BGM 节拍时间逐帧渲染 chat-rap-video 画布
 *
 * 输入：
 *   --script    剧本 JSON（必填）
 *   --beats     beats.json（必填，决定总时长和帧数）
 *   --template  HTML 模板（默认 assets/chat_template_v11.html）
 *   --assets    资源目录（头像/表情包/名片图片）
 *   --out       帧序列输出目录
 *   --fps       帧率（默认 30）
 *
 * 输出：
 *   out/000001.png ... NNNNNN.png
 */
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright-core');

function parseArgs(argv){
  const out = {};
  for (let i = 0; i < argv.length; i++){
    const a = argv[i];
    if (a.startsWith('--')){
      const key = a.slice(2);
      const next = argv[i+1];
      if (next !== undefined && !next.startsWith('--')){ out[key] = next; i++; }
      else out[key] = true;
    }
  }
  return out;
}

const args = parseArgs(process.argv.slice(2));
if (!args.script || !args.beats || !args.out){
  console.error('缺少 --script / --beats / --out');
  process.exit(1);
}

const script = JSON.parse(fs.readFileSync(args.script, 'utf8'));
const beats  = JSON.parse(fs.readFileSync(args.beats, 'utf8'));
const tplPath = args.template || path.join(__dirname, '..', 'assets', 'chat_template_v11.html');
const htmlTpl = fs.readFileSync(tplPath, 'utf8');
const assetsDir = args.assets || path.join(path.dirname(args.script), 'assets');
const outDir = args.out;
const fps = Number(args.fps || 30);
const CHROME = process.env.CHROME_BIN;

fs.mkdirSync(outDir, { recursive: true });

// 加载资源 → data URI 注入到页面
const assetsMap = {};
function tryLoad(rel){
  const p = path.isAbsolute(rel) ? rel : path.join(assetsDir, rel);
  if (fs.existsSync(p)){
    const ext = path.extname(p).slice(1).toLowerCase();
    const mime = ext === 'jpg' || ext === 'jpeg' ? 'image/jpeg'
              : ext === 'webp' ? 'image/webp'
              : ext === 'gif'  ? 'image/gif'
              : 'image/png';
    const b64 = fs.readFileSync(p).toString('base64');
    assetsMap[rel] = `data:${mime};base64,${b64}`;
    return true;
  }
  return false;
}
const avatars = script.avatars || {};
Object.entries(avatars).forEach(([k, fname]) => { tryLoad(fname); });
(script.elements || []).forEach(el => {
  if ((el.type === 'sticker' || el.type === 'nametag') && el.src){
    tryLoad(el.src);
  }
});

// 把剧本和资源以 addInitScript 注入（在 setContent 前注入，window 上可用）
const scriptJson = JSON.stringify(script);
const assetsJson = JSON.stringify(assetsMap);

(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, headless: true });
  const ctx = await browser.newContext({
    viewport: { width: 1080, height: 1920 },
    deviceScaleFactor: 1
  });

  await ctx.addInitScript(({s, a}) => {
    window.__SCRIPT__ = s;
    window.__ASSETS__ = a;
    window.__CURRENT_MS__ = 0;
  }, { s: script, a: assetsMap });

  const page = await ctx.newPage();
  await page.setContent(htmlTpl, { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => typeof window.renderAt === 'function', { timeout: 5000 });
  await page.waitForTimeout(150);

  const durationMs = beats.duration_ms || script.duration_ms || 30000;
  const totalFrames = Math.ceil(durationMs / 1000 * fps);
  console.log(`>> render ${totalFrames} frames @ ${fps}fps  duration=${(durationMs/1000).toFixed(2)}s`);

  const t0 = Date.now();
  for (let i = 0; i < totalFrames; i++){
    const currentMs = Math.round(i / fps * 1000);
    await page.evaluate((ms) => {
      window.__CURRENT_MS__ = ms;
      window.renderAt(ms);
    }, currentMs);
    // 极短等待确保 transform 应用
    await page.waitForTimeout(18);
    const idx = String(i + 1).padStart(6, '0');
    await page.screenshot({ path: path.join(outDir, `${idx}.png`), type: 'png', omitBackground: false });
    if ((i+1) % 30 === 0 || i === totalFrames - 1){
      const elapsed = ((Date.now()-t0)/1000).toFixed(1);
      console.log(`   [${i+1}/${totalFrames}]  ${elapsed}s`);
    }
  }

  await browser.close();
  const total = ((Date.now()-t0)/1000).toFixed(1);
  console.log(JSON.stringify({ ok: true, frames: totalFrames, out: outDir, seconds: Number(total) }));
})().catch(e => { console.error('render_frames 失败:', e.message); process.exit(1); });