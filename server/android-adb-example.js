#!/usr/bin/env node
"use strict";

// 最小 Android ADB 示例。默认只连服务器本机的反向隧道，不开放公网端口。
// 用法：
//   ADB_SERVER_SOCKET=tcp:127.0.0.1:5039 node android-adb-example.js devices
//   ADB_SERVER_SOCKET=tcp:127.0.0.1:5039 ANDROID_SERIAL=... node android-adb-example.js screenshot out.png

const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const { writeFile, readFile, unlink } = require("node:fs/promises");
const path = require("node:path");
const os = require("node:os");

const run = promisify(execFile);
const adbBin = process.env.ADB_BIN || "adb";
const serial = process.env.ANDROID_SERIAL || "";
const env = {
  ...process.env,
  ADB_SERVER_SOCKET: process.env.ADB_SERVER_SOCKET || "tcp:127.0.0.1:5039",
};

async function adb(args, timeout = 60_000, needsDevice = true) {
  if (needsDevice && !serial) throw new Error("请设置 ANDROID_SERIAL；多设备环境禁止隐式选设备");
  const prefix = needsDevice ? ["-s", serial] : [];
  const { stdout, stderr } = await run(adbBin, [...prefix, ...args], {
    env, timeout, maxBuffer: 32 * 1024 * 1024,
  });
  return String(stdout || stderr || "").trim();
}

async function main() {
  const [command = "devices", ...args] = process.argv.slice(2);
  if (command === "devices") {
    console.log(await adb(["devices", "-l"], 20_000, false));
    return;
  }
  if (command === "info") {
    const [model, size, focus] = await Promise.all([
      adb(["shell", "getprop", "ro.product.model"]),
      adb(["shell", "wm", "size"]),
      adb(["shell", "dumpsys", "window"]),
    ]);
    const current = /mCurrentFocus=Window\{[^}]*?\s([\w.]+)\/([\w.$]+)/.exec(focus);
    console.log(JSON.stringify({ model, size, foreground: current?.[1] || "" }, null, 2));
    return;
  }
  if (command === "screenshot") {
    const output = path.resolve(args[0] || "android-screen.png");
    const remote = "/data/local/tmp/ai-bridge-screen.png";
    const temp = path.join(os.tmpdir(), `ai-bridge-${Date.now()}.png`);
    try {
      await adb(["shell", "screencap", "-p", remote], 45_000);
      await adb(["pull", remote, temp], 90_000);
      await writeFile(output, await readFile(temp));
      console.log(output);
    } finally {
      await unlink(temp).catch(() => {});
      await adb(["shell", "rm", "-f", remote], 15_000).catch(() => {});
    }
    return;
  }
  if (command === "tap") {
    const [x, y] = args.map(Number);
    if (!Number.isFinite(x) || !Number.isFinite(y)) throw new Error("tap 需要 x y 数字坐标");
    await adb(["shell", "input", "tap", String(Math.round(x)), String(Math.round(y))]);
    return;
  }
  if (command === "push") {
    const [local, remote] = args;
    if (!local || !remote) throw new Error("push 需要本地文件与远端完整路径");
    // 示例故意要求显式远端路径；生产环境应额外限制到专属目录。
    console.log(await adb(["push", path.resolve(local), remote], 180_000));
    return;
  }
  throw new Error(`未知命令：${command}`);
}

main().catch(error => {
  console.error(error.message || error);
  process.exitCode = 1;
});
