#!/bin/bash

# ================================================================
# Antigravity AI 自动新闻获取脚本 v3
# 混合方案：agy CLI 开新窗口 + AppleScript 注入 Prompt
# 特性：独立新窗口、不干扰已有窗口、保护剪贴板、完成后自动关闭
# ================================================================

set -euo pipefail

# =================配置区域=================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULT_FILE="${SCRIPT_DIR}/ai_news_result.json"
TEMP_PROMPT_FILE="/tmp/agy_prompt_$$.txt"
TEMP_CLIPBOARD_FILE="/tmp/agy_clipboard_backup_$$.txt"
TIMEOUT=180
# =========================================

# 1. 准备 Prompt（写入临时文件，避免 shell 特殊字符问题）
cat <<'PROMPT_EOF' > "$TEMP_PROMPT_FILE"
【指令：请使用 Fast 模式/快速响应】
请搜索过去 24 小时内全球最重要的 10 条 AI 行业新闻（优先抓取 Twitter/X, Hacker News, Reddit 上的热点）。

要求：
1. 输出语言必须是中文。
2. 结果必须是合法的 JSON 格式（包含 title, summary, url 字段）。
3. 不要输出任何 Markdown 代码块标记，直接输出纯文本 JSON。
4. 将结果写入当前目录下的 ai_news_result.json 文件。
5. 完成后请回复 "DONE"。
PROMPT_EOF

# 2. 清理旧文件
rm -f "$RESULT_FILE"

# 3. 备份用户当前剪贴板内容
pbpaste > "$TEMP_CLIPBOARD_FILE" 2>/dev/null || true

# 4. 记录当前 Antigravity 窗口数量
BEFORE_WIN_COUNT=$(osascript -e '
    try
        tell application "System Events"
            if exists process "Antigravity" then
                return count of windows of process "Antigravity"
            else
                return 0
            end if
        end tell
    on error
        return 0
    end try
' 2>/dev/null || echo "0")

echo "📊 当前已有 Antigravity 窗口: ${BEFORE_WIN_COUNT} 个"

# 5. 打开带工作目录的新窗口
echo "🚀 正在打开 Antigravity 新窗口..."
agy --new-window "$SCRIPT_DIR" &
AGY_PID=$!

# 等待新窗口出现
echo "⏳ 等待新窗口加载..."
for i in $(seq 1 20); do
    sleep 1
    CUR_COUNT=$(osascript -e '
        tell application "System Events"
            if exists process "Antigravity" then
                return count of windows of process "Antigravity"
            else
                return 0
            end if
        end tell
    ' 2>/dev/null || echo "0")
    if [ "$CUR_COUNT" -gt "$BEFORE_WIN_COUNT" ]; then
        echo "   ✅ 新窗口已出现 (${i}s)"
        break
    fi
    echo -ne "."
done

# 额外等待让编辑器完全初始化
sleep 3

# 6. 将 Prompt 写入剪贴板
cat "$TEMP_PROMPT_FILE" | pbcopy

# 7. AppleScript 自动化：在新窗口中打开 Chat 并注入 Prompt
echo "🤖 正在注入 AI 任务..."
osascript <<'APPLESCRIPT'
tell application "Antigravity" to activate
delay 0.5

tell application "System Events"
    tell process "Antigravity"
        -- Cmd+L 打开 Chat 输入框
        keystroke "l" using {command down}
        delay 1
        
        -- Cmd+V 粘贴 Prompt
        keystroke "v" using {command down}
        delay 0.5
        
        -- 按回车发送
        key code 36
    end tell
end tell
APPLESCRIPT

echo "   ✅ Prompt 已发送"

# 8. 立即恢复用户原始剪贴板内容
if [ -f "$TEMP_CLIPBOARD_FILE" ] && [ -s "$TEMP_CLIPBOARD_FILE" ]; then
    pbcopy < "$TEMP_CLIPBOARD_FILE"
    echo "   📋 用户剪贴板已恢复"
fi

echo "⏳ 正在等待 AI 生成 ${RESULT_FILE}..."

# 9. 轮询等待结果文件生成
count=0
while [ ! -f "$RESULT_FILE" ]; do
    sleep 1
    count=$((count + 1))
    if [ $count -ge $TIMEOUT ]; then
        echo ""
        echo "❌ 超时：AI 未能在 ${TIMEOUT} 秒内生成文件。"
        echo "   请检查 Antigravity 新窗口中的 Chat 面板。"
        break
    fi
    if [ $((count % 10)) -eq 0 ]; then
        echo "   ⏳ 已等待 ${count}s / ${TIMEOUT}s ..."
    else
        printf "."
    fi
done

echo ""

# 10. 输出结果
if [ -f "$RESULT_FILE" ]; then
    echo "✅ 收到 AI 响应！结果如下："
    echo "========================================"
    if command -v jq > /dev/null 2>&1; then
        jq . "$RESULT_FILE"
    else
        python3 -m json.tool "$RESULT_FILE"
    fi
    echo "========================================"
    EXIT_CODE=0
else
    echo "❌ 未找到结果文件 ${RESULT_FILE}"
    EXIT_CODE=1
fi

# 11. 关闭新开的 Antigravity 窗口
echo "🧹 正在关闭自动化窗口..."

CURRENT_WIN_COUNT=$(osascript -e '
    tell application "System Events"
        if exists process "Antigravity" then
            return count of windows of process "Antigravity"
        else
            return 0
        end if
    end tell
' 2>/dev/null || echo "0")

if [ "$CURRENT_WIN_COUNT" -gt "$BEFORE_WIN_COUNT" ]; then
    # Cmd+Shift+W 关闭整个窗口（Cmd+W 只关闭标签页）
    osascript <<'APPLESCRIPT'
tell application "Antigravity" to activate
delay 0.3
tell application "System Events"
    keystroke "w" using {command down, shift down}
end tell
APPLESCRIPT

    sleep 1

    FINAL_COUNT=$(osascript -e '
        tell application "System Events"
            if exists process "Antigravity" then
                return count of windows of process "Antigravity"
            else
                return 0
            end if
        end tell
    ' 2>/dev/null || echo "0")

    if [ "$FINAL_COUNT" -le "$BEFORE_WIN_COUNT" ]; then
        echo "   ✅ 自动化窗口已关闭"
    else
        echo "   ⚠️  窗口可能未关闭，请手动处理"
    fi
else
    echo "   ℹ️  未检测到多余窗口"
fi

# 12. 清理临时文件
rm -f "$TEMP_PROMPT_FILE" "$TEMP_CLIPBOARD_FILE"
kill "$AGY_PID" 2>/dev/null || true
wait "$AGY_PID" 2>/dev/null || true

echo "✅ 自动化流程完成。"
exit "${EXIT_CODE}"
