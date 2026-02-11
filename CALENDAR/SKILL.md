---
name: macos-calendar
description: 通过命令行管理 macOS 系统日历（Calendar.app），支持创建/查询/更新/删除日程及列出日历。当用户提到"日历/日程/会议/安排/行程/约会/预约/创建日程/日历查询/Calendar/Cal/schedule/event/appointment"等需求时使用。
---

# macOS Calendar CLI (mcc)

通过 Shell + AppleScript 直接操控 macOS 原生日历 Calendar.app，所有操作返回结构化 JSON。

## 何时使用

当用户提到或暗示以下需求时使用：`日历/日程/会议/安排/行程/约会/预约/创建日程/日历查询/Calendar/Cal/schedule/event/appointment`，或明确说 Calendar.app 的增删改查。

## 前置条件

- **macOS** 系统
- **jq** 已安装（`brew install jq`）
- 终端已授予"日历"访问权限（首次运行时系统会弹窗）
- **日期/时间格式**：`YYYY-MM-DD` / `HH:MM`（24 小时制）
- **智能日期推断**：当用户未明确日期时，LLM 应自动推断为今天日期并填入 `--date`

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
| `--date` | ✅ | — | 日期 `YYYY-MM-DD`（用户未说日期时 LLM 用今天） |
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

| 定位参数 | 说明 |
|---------|------|
| `--uid` | 事件唯一标识（必填，通过 `list` 查询获取） |

| 修改参数 | 说明 |
|---------|------|
| `--title` | 新标题 |
| `--date` | 新日期 |
| `--time` | 新时间 |
| `--duration` | 新时长（分钟数） |
| `--location` | 新地点 |
| `--notes` | 新备注 |
| `--alarm` | 新提醒（分钟数） |

**输出示例：**
```json
{
  "status": "success",
  "action": "update",
  "event": {
    "uid": "ABC-123-DEF",
    "title": "新标题",
    "start": "2026-02-22T15:30:00",
    "end": "2026-02-22T16:30:00",
    "calendar": "Home",
    "location": "新地点",
    "notes": "新备注",
    "allday": false
  }
}
```

### 5. 删除日程（按 UID）

```bash
bash $CALENDAR_SH delete --uid <event-uid>
```

**输出示例：**
```json
{
  "status": "success",
  "action": "delete",
  "event": {
    "uid": "ABC-123-DEF",
    "title": "被删除的日程",
    "start": "2026-02-20T14:00:00",
    "end": "2026-02-20T14:30:00",
    "calendar": "Home",
    "location": "",
    "notes": "",
    "allday": false
  }
}
```

---

## JSON 输出规范

所有命令返回 JSON，关键字段：

| 字段 | 含义 |
|------|------|
| `status` | `"success"` 或 `"error"` |
| `action` | 操作类型（`create`/`list`/`update`/`delete`/`calendars`） |
| `message` | 错误时的详细信息 |
| `event` | 单条操作（create/update/delete）的事件对象 |
| `events` | 列表查询的事件数组 |
| `count` | 结果数量（list/calendars） |
| `calendars` | 日历列表（calendars 操作） |

**事件对象结构：**
```json
{
  "uid": "唯一标识符",
  "title": "日程标题",
  "start": "2026-02-20T14:00:00",
  "end": "2026-02-20T14:30:00",
  "calendar": "日历名称",
  "location": "地点",
  "notes": "备注",
  "allday": false
}
```

---

## 错误响应处理（LLM 必须遵守）

当 `status: "error"` 时：

1. **直接回显** `message` 字段内容给用户。
2. **判断错误类型**并引导：
   - `Missing required: --title/--date/--time` → 向用户询问缺少的必填信息
   - `Invalid date format` / `Invalid time format` → 提示正确格式 `YYYY-MM-DD` / `HH:MM`
   - `Unknown action` → 检查命令拼写
   - `Event not found with UID` → 建议先用 `list` 查询确认 UID
   - `AppleScript error` → 可能是日历名称不存在，建议先 `calendars` 查看可用日历
3. **不要猜测或伪造成功结果**，必须如实反馈错误。

---

## 典型 LLM 工作流

### 工作流 A：快速创建日程（最常用）

```bash
# 用户说："明天下午两点开会"
# LLM 推断日期为明天，时间为 14:00
bash $CALENDAR_SH create --title "开会" --date 2026-02-12 --time 14:00
```

### 工作流 B：查询 → 更新

```bash
# 1. 先查询目标日程，拿到 UID
bash $CALENDAR_SH list --title "开会" --date 2026-02-12

# 2. 用返回的 UID 更新
bash $CALENDAR_SH update --uid <返回的uid> --time 15:00 --location "会议室B"
```

### 工作流 C：查询 → 安全删除

```bash
# 1. 先查询确认目标
bash $CALENDAR_SH list --title "开会" --date 2026-02-12

# 2. 向用户确认是否删除（必须！）
# 3. 用户确认后执行
bash $CALENDAR_SH delete --uid <返回的uid>
```

### 工作流 D：查询某天日程概览

```bash
# 用户说："今天有什么安排？"
bash $CALENDAR_SH list --date 2026-02-11

# 返回结果后，按时间顺序向用户展示日程列表
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
3. **用户未提供日期时**，LLM 应根据语境自动推断（如"今天"、"明天"、"下周一"），并转换为 `YYYY-MM-DD` 格式传入 `--date`。
4. 仅在用户确认后执行 `delete` 等破坏性操作。
5. 输出必须为脚本返回的 JSON，不要二次包装。
6. 更新/删除操作必须先通过 `list` 获取 `uid`，再执行操作。

---

## 不支持/非目标

- 重复事件（recurring events）的创建与修改
- 参与者/邀请管理
- 跨日历移动事件
- 自然语言日期解析（由 LLM 在调用前完成转换）
- 日历的创建与删除（仅支持列出现有日历）
