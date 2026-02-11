#!/bin/bash

# =================配置区域=================
APP_NAME="Antigravity"
RESULT_FILE="ai_news_result.json"
TEMP_PROMPT_FILE="/tmp/agy_prompt.txt"

# 1. 准备 Prompt (直接写入文件，避免复杂的 Shell 转义噩梦)
cat <<'EOF' > "$TEMP_PROMPT_FILE"
【指令：请使用 Fast 模式/快速响应】
请搜索过去 24 小时内全球最重要的 10 条 AI 行业新闻（优先抓取 Twitter/X, Hacker News, Reddit 上的热点）。

要求：
1. 输出语言必须是中文。
2. 结果必须是合法的 JSON 格式（包含 title, summary, url 字段）。
3. 不要输出任何 Markdown 代码块标记（如 ```json），直接输出纯文本 JSON。
4. 将结果写入当前目录下的 ai_news_result.json 文件。
5. 完成后请回复 "DONE"。
EOF

# =========================================

# 2. 清理旧文件
rm -f "$RESULT_FILE"

# 3. 将 Prompt 放入系统剪贴板 (这是最稳健的方式)
cat "$TEMP_PROMPT_FILE" | pbcopy

# 4. 打开 Antigravity
echo "🚀 正在启动 $APP_NAME..."
"$HOME/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity" . &

# 5. 等待编辑器就绪
echo "⏳ 等待编辑器加载 (5秒)..."
sleep 5

# 6. AppleScript 自动化注入 (只负责按键)
echo "🤖 正在注入 AI 任务..."
osascript <<EOF
tell application "$APP_NAME"
    activate
    delay 1
    
    tell application "System Events"
        -- 模拟 Cmd+L 打开 Chat
        keystroke "l" using {command down}
        delay 0.5
        
        -- 模拟 Cmd+V 粘贴 (剪贴板里已经是我们的 Prompt 了)
        keystroke "v" using {command down}
        delay 0.5
        
        -- 发送回车
        key code 36
    end tell
end tell
EOF

echo "⏳ 任务已发送，正在等待 AI 生成 $RESULT_FILE..."

# 7. 监听文件生成 (轮询模式)
TIMEOUT=120
count=0

while [ ! -f "$RESULT_FILE" ]; do
    sleep 1
    ((count++))
    if [ $count -ge $TIMEOUT ]; then
        echo ""
        echo "❌ 超时：AI 未能在 $TIMEOUT 秒内生成文件。"
        echo "请检查 Antigravity 窗口中是否报错，或是否需要人工确认。"
        exit 1
    fi
    # 显示进度条
    echo -ne "."
done

echo ""
echo "✅ 收到 AI 响应！结果如下："
echo "----------------------------------------"
# 使用 jq (如果安装了) 或 python 格式化输出
if command -v jq &> /dev/null; then
    cat "$RESULT_FILE" | jq .
else
    cat "$RESULT_FILE" | python3 -m json.tool
fi
echo "----------------------------------------"
