# Antigravity AI 自动化脚本

使用 `agy chat` CLI 命令实现全自动 AI 任务触发，Prompt 直传、进程隔离、自动清理。

## 📁 文件说明

```
/Users/jackwl/Code/allSkills/macos/antigravity/
├── auto_news_v2.sh      # ⭐ 全自动 AI 新闻获取脚本 (v3, agy chat)
├── sample_output.json   # 示例输出结果
└── README.md            # 本文档
```

## 🚀 快速开始

```bash
cd /Users/jackwl/Code/allSkills/macos/antigravity
bash auto_news_v2.sh
```

**运行流程：**
1. ✅ 创建隔离 `--user-data-dir`（不干扰已打开的 Antigravity）
2. ✅ `agy chat -n` 打开全新独立窗口
3. ✅ Prompt 通过 CLI 参数直传（不使用剪贴板，不操作已有窗口）
4. ⏳ 轮询等待 `ai_news_result.json` 生成
5. 📋 格式化 JSON 输出到控制台
6. 🧹 自动关闭新开的 Antigravity 实例 + 清理临时目录

**输出规格：**
- Fast 模式响应
- JSON 格式
- 中文内容
- 10 条 AI 行业新闻

## ⚙️ 脚本配置

修改 `auto_news_v2.sh` 中的以下变量：

```bash
RESULT_FILE="${SCRIPT_DIR}/ai_news_result.json"  # 输出文件（绝对路径）
TIMEOUT=180                                       # 等待超时时间（秒）
```

修改任务内容直接编辑脚本中的 `PROMPT` 变量。

## 🛠️ 环境要求

**必需：**
- macOS 系统
- `agy` CLI 已安装（Antigravity 自带，通常位于 `~/.antigravity/antigravity/bin/agy`）
- Bash Shell

**可选（美化 JSON 输出）：**
```bash
brew install jq
# 或使用系统自带的 Python
```

## 📝 示例输出

```json
{
  "news": [
    {
      "title": "OpenAI 发布 GPT-5 预览版",
      "summary": "OpenAI 在其年度开发者大会上展示了 GPT-5 的早期版本...",
      "url": "https://example.com/news1"
    },
    {
      "title": "Google DeepMind 新突破",
      "summary": "DeepMind 团队在蛋白质折叠预测方面取得重大进展...",
      "url": "https://example.com/news2"
    }
  ],
  "generated_at": "2024-02-11T10:30:00Z"
}
```

## 🔄 工作流集成

**Cron 定时任务：**
```bash
crontab -e
# 每天早上 9 点运行
0 9 * * * /bin/bash /Users/jackwl/Code/allSkills/macos/antigravity/auto_news_v2.sh
```

**Makefile：**
```makefile
ai-news:
	bash /Users/jackwl/Code/allSkills/macos/antigravity/auto_news_v2.sh
```

## ⚠️ 常见问题

**Q: 没有生成结果文件**
A:
1. 确认 `agy` 命令可用：`agy --version`
2. 增加 `TIMEOUT` 等待时间
3. 手动运行 `agy chat -n "你好"` 测试 CLI 是否正常

**Q: 多个 Antigravity 实例冲突**
A: 脚本使用 `--user-data-dir /tmp/agy_isolated_$$` 创建完全隔离的实例，不会影响已打开的窗口。`$$` 是当前进程 PID，每次运行都不同。

**Q: 脚本结束后 Antigravity 没关闭**
A: 脚本通过 PID 差集检测新进程并 `kill`。如有残留，执行：
```bash
# 查看所有 Antigravity 进程
ps aux | grep Antigravity
# 手动清理隔离数据目录
rm -rf /tmp/agy_isolated_*
```

## 🎯 技术原理

```
Bash Script
    ↓
准备 Prompt → 写入临时文件 → 读取为变量
    ↓
记录当前 Antigravity 窗口数 (System Events)
    ↓
agy chat --new-window "$PROMPT"
    → 打开独立 Antigravity 新窗口
    → Prompt 通过 CLI 参数直传 (不占用剪贴板)
    → 共享用户已有配置和 API Key
    ↓
轮询等待 ai_news_result.json 生成
    ↓
格式化输出 (jq/python)
    ↓
比对窗口数 → 关闭多出的新窗口 (System Events)
清理临时文件
```

## 🚀 扩展方向

- [ ] 多代理并行任务（每个任务独立 user-data-dir）
- [ ] Slack/Discord Webhook 推送
- [ ] 任务模板系统
- [ ] 自动重试机制
- [ ] 执行日志审计

## 📄 许可证

MIT License

---
**最后更新：** 2026-02-11
**作者：** Antigravity AI
