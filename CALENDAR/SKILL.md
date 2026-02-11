---
name: macos-calendar
description: 通过命令行管理 macOS 系统日历（Calendar.app），支持创建/查询/更新/删除日程及列出日历。当用户提到“日历/日程/会议/日历查询/创建日程/Calendar/Cal”等需求时使用。
---

# macOS Calendar CLI (mcc)

通过 Shell + AppleScript 直接操控 macOS 原生日历 Calendar.app，所有操作返回结构化 JSON。

## 何时使用
当用户提到或暗示以下需求时使用：`日历/日程/会议/日历查询/创建日程/Calendar/Cal`，或明确说 Calendar.app 的增删改查。

## 前置条件
- **macOS** 系统
- **jq** 已安装（`brew install jq`）
- 终端已授予“日历”访问权限（首次运行时系统会弹窗）
- **日期/时间格式**：`YYYY-MM-DD` / `HH:MM`（24 小时制）

## 入口脚本

```bash
CALENDAR_SH="/Users/jackwl/Code/allSkills/macos/CALENDAR/calendar.sh"
```

所有命令均通过此入口调用，格式：`bash $CALENDAR_SH <action> [options]`

---

## 命令参考

### 1. 列出所有日历

```bash
bash $CALENDAR_SH calendars
```

**输出示例：**
```json
{"status":"success","action":"calendars","count":2,"calendars":[{"name":"Home"},{"name":"Work"}]}
```

### 2. 创建日程

```bash
bash $CALENDAR_SH create --title "开会" --date 2026-02-20 --time 14:00 \
  [--calendar "Home"] [--alarm 15] [--duration 45] [--location "会议室A"] [--notes "带电脑"] [--all-day]
```

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `--title` | ✅ | — | 日程标题 |
| `--date` | ✅ | — | 日期 `YYYY-MM-DD` |
| `--time` | ✅ | — | 时间 `HH:MM` |
| `--calendar` | ❌ | `Home` | 日历名称 |
| `--alarm` | ❌ | `0` | 提前提醒分钟数（0=开始时） |
| `--duration` | ❌ | `30` | 时长（分钟） |
| `--location` | ❌ | 空 | 地点 |
| `--notes` | ❌ | 空 | 备注 |
| `--all-day` | ❌ | `false` | 全天事件 |

**输出示例：**
```json
{
  "status": "success",
  "action": "create",
  "event": {
    "uid": "...",
    "title": "开会",
    "start": "2026-02-20T14:00:00",
    "end": "2026-02-20T14:45:00",
    "calendar": "Home",
    "location": "会议室A",
    "notes": "带电脑",
    "allday": false
  }
}
```

### 3. 查询日程

```bash
# 默认：未来 7 天
bash $CALENDAR_SH list

# 指定日期
bash $CALENDAR_SH list --date 2026-02-20

# 指定范围
bash $CALENDAR_SH list --from 2026-02-20 --to 2026-02-28

# 指定日历
bash $CALENDAR_SH list --from 2026-02-20 --to 2026-02-28 --calendar "Home"

# 标题包含匹配
bash $CALENDAR_SH list --title "开会" --date 2026-02-20

# UID 精确查询
bash $CALENDAR_SH list --uid <event-uid>
```

**输出示例：**
```json
{"status":"success","action":"list","count":1,"events":[{"uid":"...","title":"开会","start":"...","end":"...","calendar":"Home","location":"","notes":"","allday":false}]}
```

### 4. 更新日程（按 UID）

```bash
bash $CALENDAR_SH update --uid <event-uid> [--title "新标题"] [--date 2026-02-22] [--time 15:30] \
  [--duration 60] [--location "新地点"] [--notes "新备注"] [--alarm 10]
```

**说明**：必须提供 `--uid`，且至少更新一个字段。

### 5. 删除日程（按 UID）

```bash
bash $CALENDAR_SH delete --uid <event-uid>
```

---

## 约束与注意事项
- **日期有效性严格校验**：`2026-02-30` 这类日期会直接报错。
- **时间格式严格校验**：仅支持 `00:00` 到 `23:59`。
- `delete` 为永久删除，请谨慎执行。

---

## LLM 执行规范
1. 先确认用户意图与参数（标题/日期/时间/日历等）。
2. 如果缺少必填参数，先向用户询问补齐。
3. 仅在用户确认后执行 `delete` 等破坏性操作。
4. 输出必须为脚本返回的 JSON，不要二次包装。
