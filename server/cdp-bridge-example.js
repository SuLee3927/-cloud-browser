// 最小示例：服务器侧通过 CDP 操作"云浏览器"（对面家里那台真实 Chrome）
// 依赖：npm i playwright-core
const { chromium } = require('playwright-core');

const CDP = process.env.CDP_URL || 'http://127.0.0.1:9223';

(async () => {
  const browser = await chromium.connectOverCDP(CDP);
  const ctx = browser.contexts()[0];
  const page = ctx.pages()[0] || await ctx.newPage();

  // 打开网页（用的是对面的真实 IP 和登录态）
  await page.goto('https://example.com', { waitUntil: 'load' });
  console.log('标题:', await page.title());

  // 截图：拿去做视觉判断（AI 常用的输入）
  await page.screenshot({ path: '/tmp/shot.jpg', type: 'jpeg', quality: 70 });

  // 点击 / 输入
  // await page.click('text=登录');
  // await page.fill('#username', 'hello');

  // 读正文
  console.log((await page.innerText('body')).slice(0, 300));

  // 注意：千万别调用 browser.close() —— 那会把对面那台电脑上的浏览器关掉
  process.exit(0);
})();
