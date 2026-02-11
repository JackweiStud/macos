# Antigravity AI 自动化脚本

全自动 AI 任务触发器，通过 AppleScript 模拟用户操作，实现脚本 → AI → 结果回传的闭环。

## 📁 文件说明

```
/Users/jackwl/Code/allSkills/macos/antigravity/
├── auto_news_v2.sh      # ⭐ 全自动 AI 新闻获取脚本
├── sample_output.json   # 示例输出结果
└── README.md            # 本文档
```

## 🚀 快速开始

```bash
cd /Users/jackwl/Code/allSkills/macos/antigravity
bash auto_news_v2.sh
```

**运行流程：**
1. ✅ 自动打开 Antigravity
2. ✅ 自动唤起 AI Chat (Cmd+L)
3. ✅ 自动粘贴任务 Prompt
4. ✅ 自动发送回车
5. ⏳ 轮询等待 `ai_news_result.json` 生成
6. 📋 格式化 JSON 输出到控制台

**输出规格：**
- Fast 模式响应
- JSON 格式
- 中文内容
- 10 条 AI 行业新闻

## ⚙️ 脚本配置

修改 `auto_news_v2.sh` 中的以下变量：

```bash
RESULT_FILE="ai_news_result.json"   # 输出文件名
TIMEOUT=120                          # 等待超时时间（秒）
```

修改任务内容（Prompt）：

```bash
cat <<'EOF' > "$TEMP_PROMPT_FILE"
【指令：请使用 Fast 模式/快速响应】
请搜索过去 24 小时内全球最重要的 10 条 AI 行业新闻...
EOF
```

## 🛠️ 环境要求

**必需：**
- macOS 系统
- Antigravity.app 安装于 `~/Applications/`
- Bash Shell

**可选（美化 JSON 输出）：**
```bash
brew install jq
# 或使用系统自带的 Python
```

**权限配置：**
首次运行时 macOS 会提示：
> "Terminal 想要控制此电脑"

**设置：** System Settings → Privacy & Security → Accessibility → 勾选 Terminal

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

## 🔧 自定义任务示例

**获取科技新闻而非 AI 新闻：**

```bash
cat <<'EOF' > "$TEMP_PROMPT_FILE"
【指令：请使用 Fast 模式】
请搜索本周最重要的 5 条科技行业新闻。
要求：
1. 输出中文
2. JSON 格式，包含：标题、摘要、来源、发布时间
3. 保存为 tech_news.json
4. 完成后回复 "DONE"
EOF
```

## 🔄 工作流集成

**Cron 定时任务：**
```bash
crontab -e
# 每天早上 9 点运行
0 9 * * * /bin/bash /Users/jackwl/Code/allSkills/macos/antigravity/auto_news_v2.sh
```

**Git Hook：**
```bash
# .git/hooks/pre-commit
bash /Users/jackwl/Code/allSkills/macos/antigravity/auto_news_v2.sh
```

**Makefile：**
```makefile
ai-news:
	bash /Users/jackwl/Code/allSkills/macos/antigravity/auto_news_v2.sh
```

## ⚠️ 常见问题

**Q: AppleScript 报错 "syntax error"**  
A: 使用剪贴板中转模式，避免直接在脚本中硬编码复杂字符串

**Q: 没有生成结果文件**  
A: 
1. 检查 Antigravity 窗口是否弹出
2. 检查 AI 是否正常响应
3. 增加 `TIMEOUT` 等待时间
4. 查看 Chat 窗口是否有报错

**Q: Cmd+L 快捷键无效**  
A: 
- 尝试改为 `Cmd+I` 或 `Cmd+Shift+K`
- 修改脚本中 `keystroke "l"` 部分

## 🎯 技术原理

```
Bash Script
    ↓
生成 Prompt → 写入剪贴板 (pbcopy)
    ↓
启动 Antigravity (agy)
    ↓
AppleScript 模拟按键
    Cmd+L (唤起 Chat)
    Cmd+V (粘贴 Prompt)
    Return (发送)
    ↓
轮询等待文件生成
    ↓
格式化输出 (jq/python)
```

## 🚀 扩展方向

- [ ] 多代理并行任务
- [ ] Slack/Discord Webhook 推送
- [ ] 任务模板系统
- [ ] 自动重试机制
- [ ] 执行日志审计

## 📄 许可证

MIT License

---
**最后更新：** 2024-02-11  
**作者：** Claude Code (OpenCode)
