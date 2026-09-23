# ☁️ Cloud Browser Bridge · 云浏览器桥

把**你家/内网里的真实浏览器**变成**服务器上的 AI 可以远程操控的浏览器**——
真实住宅 IP、真实浏览器指纹、登录态存在本机，重启不丢。

## 它解决什么问题

很多网站对"机房 IP + 无头浏览器"很不友好：风控、验证码、登录态秒踢。
如果换成**你家里那台电脑上的真实 Chrome**去访问，这些问题大多消失——
但家里没有公网 IP，服务器主动敲不进门。

这个项目的做法：用一条**反向 SSH 隧道**把方向反过来。

```
   你家 Windows                          你的服务器
  ┌────────────────┐                    ┌──────────────────────┐
  │  真实 Chrome   │                    │  AI / 自动化脚本     │
  │  (独立 profile)│                    │          │           │
  │      │ CDP     │                    │          ▼           │
  │      ▼         │  ssh -R 反向隧道    │  http://127.0.0.1:9223
  │   9222 端口  ──┼───────────────────▶│   (Chrome 调试端口)  │
  └────────────────┘  由家里主动连出去   └──────────────────────┘
```

- **浏览器跑在你家**：真实 IP、真实指纹、登录态在本地 profile 里（重启不丢）
- **服务器只负责指挥**：通过 Chrome DevTools Protocol (CDP) 读页面、点击、输入、截图
- **隧道由家里连出去**（`ssh -R`）：家里不需要公网 IP，也不用开任何端口

## 目录

| 路径 | 说明 |
|---|---|
| `windows/home-bridge.cmd` | 家里那台的主程序：拉起专用 Chrome + 建反向隧道 + 断线自动重连 |
| `windows/start-hidden.vbs` | 后台静默启动（配合开机自启） |
| `windows/启动步骤.md` | 一步步的安装与排障备忘（照着做即可） |
| `server/cdp-bridge-example.js` | 服务器侧最小示例：连上 CDP 并操作页面 |
| `server/authorized_keys.example` | 服务器侧把钥匙限制成"只能转发端口"的写法 |

## 快速开始

### 一、家里（Windows）

1. 把 `windows/` 里的两个文件拷到同一个文件夹，例如 `C:\cloud-browser\`
2. 生成一把**专用密钥**（别用你平时的登录密钥）：

   ```powershell
   ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\cloudbrowser" -N '""' -C cloud-browser
   type "$env:USERPROFILE\.ssh\cloudbrowser.pub"
   ```

3. 把公钥贴到服务器的 `~/.ssh/authorized_keys`（写法见 `server/authorized_keys.example`）
4. 用记事本打开 `home-bridge.cmd`，把 `SERVER`、`PORT`、`KEY` 三行改成你自己的
5. 双击 `start-hidden.vbs` 跑起来（想排查问题就双击 `home-bridge.cmd`，有窗口能看到日志）

### 二、服务器

```bash
ss -ltn | grep 9223          # 能看到监听 = 隧道通了
npm i playwright-core
node server/cdp-bridge-example.js
```

## 安全设计

- 隧道把 Chrome 调试端口绑到**服务器本机**（`GatewayPorts no`），外网碰不到
- 那把钥匙在服务器侧被限制成 `command="/bin/false",no-pty`——**拿到也只能转发端口，开不了 shell**
- Chrome 用**独立 profile**（`--user-data-dir`），和你日常浏览器的账号/书签/密码完全隔离
- CDP 端口只监听 `127.0.0.1`，且只经隧道可达

## 注意事项

- **Windows 电源设置**：插电时永不睡眠，否则人会断线（`windows/启动步骤.md` 里有命令）
- **开机自启**：把 `start-hidden.vbs` 的快捷方式丢进 `Win+R → shell:startup`
- **电脑睡了/关了 = 浏览器不在线**，这是预期行为，醒来自动恢复
- ⚠️ 别把服务器地址、私钥、真实账号信息提交进这个仓库

## License

MIT
