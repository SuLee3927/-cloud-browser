# 服务器直跑模式

**不需要家里那台电脑，也不需要隧道** —— 直接把 Chrome 跑在服务器上，暴露一个本机 CDP 端口。

自动化侧的代码**完全不用改**（都是 CDP）：把 `CDP_URL` 从 `http://127.0.0.1:9223` 换成 `http://127.0.0.1:9222` 就行。

## 什么时候用这个模式

| 你的需求 | 选哪个 |
|---|---|
| 要**真实住宅 IP / 真实浏览器指纹**（比如对风控敏感的站点） | 🏠 家庭模式（仓库根目录那套） |
| 只要**某个地域的 IP**，或是纯抓取 / 定时任务 | 🖥️ **服务器模式（本目录）** |
| 不想为这个功能常开一台电脑 | 🖥️ **服务器模式（本目录）** |

## 快速开始

```bash
bash server-only/setup-server-chrome.sh
# 输出里能看到 {"Browser": "Chrome/xxx", ...} 就成功了
node server/cdp-bridge-example.js     # CDP_URL=http://127.0.0.1:9222
```

常驻（开机自启）：把 `cloudbrowser-chrome.service` 改成你的路径，放进 `/etc/systemd/system/`：

```bash
sudo cp server-only/cloudbrowser-chrome.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now cloudbrowser-chrome
```

## 想"看得见"它在干什么（可选）

无头模式没有画面。想看画面有两条路：

1. **截图**：CDP 自带（`Page.captureScreenshot`），让上层 AI 看着图操作——这也是最省资源的方式
2. **真画面（带虚拟显示器）**：

   ```bash
   sudo apt-get install -y xvfb x11vnc novnc
   Xvfb :99 -screen 0 1440x900x24 &
   DISPLAY=:99 google-chrome --remote-debugging-port=9222 --user-data-dir=$HOME/.cloudbrowser-chrome &
   x11vnc -display :99 -localhost -nopw -forever -shared &
   # 再起个 noVNC 就能在浏览器里看了（记得只绑本机 / 走你自己的隧道）
   ```

## 已知限制（重要）

- **机房 IP 会被部分站点识别**：小红书/微博这类对数据中心 IP 敏感，可能出现验证码、限流，甚至封号。要这些场景请用**家庭模式**。
- **无头指纹和真实浏览器有差异**：`--headless=new` 已经比老版本好很多，但仍可被高级风控识别。
- **登录态存在服务器磁盘上**（profile 目录）：重启不丢，但**别把那个目录提交进任何仓库**。

## 安全

- 调试端口只绑 `127.0.0.1` —— **千万别暴露到公网**（CDP 等于浏览器完全控制权）
- 需要远程看画面时，用 SSH 隧道或你已有的反向代理 + 认证，不要直接开端口
