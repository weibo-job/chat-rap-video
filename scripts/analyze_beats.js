#!/usr/bin/env node
/**
 * analyze_timeline.js —— BGM 节拍/能量时间轴分析（毫秒级）
 *
 * 用 ffmpeg-static 把音乐转成 16k mono wav，分析能量包络，
 * 输出节拍点列表，供分镜编排做音画对齐。
 *
 * 用法：
 *   node analyze_timeline.js --bgm music.mp3 --out beats.json
 * 输出：
 *   { duration_ms, beats: [{t_ms, energy}] }  (beats 按时间升序)
 */
const path = require('path');
const fs = require('fs');
const { execFileSync } = require('child_process');

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const key = a.slice(2);
      const next = argv[i + 1];
      if (next !== undefined && !next.startsWith('--')) { out[key] = next; i++; }
      else out[key] = true;
    }
  }
  return out;
}

const args = parseArgs(process.argv.slice(2));
const bgm = args.bgm;
const outPath = args.out || './beats.json';
const FFMPEG = process.env.FFMPEG_BIN;
const WINDOW_MS = 50;   // 能量窗口
const RATE = 16000;     // 采样率

if (!bgm || !FFMPEG) { console.error('缺少 --bgm 或 FFMPEG_BIN'); process.exit(1); }

const wavPath = path.join(path.dirname(outPath) || '.', '.tmp_bgm.wav');
try {
  // 1) 转 wav（16k mono 16bit）
  execFileSync(FFMPEG, ['-y', '-i', bgm, '-ar', String(RATE), '-ac', '1', '-f', 'wav', wavPath], { stdio: 'pipe' });

  // 2) 解析 wav（PCM16 LE）
  const buf = fs.readFileSync(wavPath);
  const dataStart = 44; // 标准 wav 头（无扩展 chunk 的一般情况）
  const samples = [];
  for (let i = dataStart; i + 1 < buf.length; i += 2) {
    samples.push(buf.readInt16LE(i) / 32768);
  }
  const samplesPerWindow = Math.floor(RATE * WINDOW_MS / 1000);
  const energies = [];
  for (let i = 0; i < samples.length; i += samplesPerWindow) {
    let sum = 0, n = 0;
    for (let j = i; j < Math.min(i + samplesPerWindow, samples.length); j++) { sum += samples[j] * samples[j]; n++; }
    energies.push({ t_ms: Math.round(i / RATE * 1000), energy: n ? Math.sqrt(sum / n) : 0 });
  }

  // 3) 找局部峰值（能量显著高于局部均值 → 节拍点）
  const window = 6; // 相邻 ±6 个窗口
  const beats = [];
  for (let i = 1; i < energies.length - 1; i++) {
    let localSum = 0, localN = 0;
    for (let j = Math.max(0, i - window); j <= Math.min(energies.length - 1, i + window); j++) { localSum += energies[j].energy; localN++; }
    const localAvg = localSum / localN;
    if (energies[i].energy > localAvg * 1.4 && energies[i].energy > 0.03) {
      beats.push({ t_ms: energies[i].t_ms, energy: Number(energies[i].energy.toFixed(4)) });
    }
  }

  const duration_ms = samples.length ? Math.round(samples.length / RATE * 1000) : 0;
  fs.writeFileSync(outPath, JSON.stringify({ duration_ms, beats, window_ms: WINDOW_MS }, null, 2));
  console.log(JSON.stringify({ ok: true, duration_ms, beats: beats.length, out: outPath }));
} catch (e) {
  console.error('analyze_timeline 失败:', e.message);
  process.exit(1);
} finally {
  try { fs.unlinkSync(wavPath); } catch (_) {}
}
