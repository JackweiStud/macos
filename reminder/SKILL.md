---
name: macos-reminder-cli
description: 通过命令行管理 macOS 系统提醒事项（Reminders.app），支持增删改查、关键字搜索、多维度消歧和重名碰撞检测。当用户说"添加提醒"、"创建reminder"、"查看待办"、"完成任务"、"删除提醒"、"更新提醒"、"清理已完成"、"提醒事项"、"待办事项"、"todo"时使用。
---

# macOS Reminder CLI (mrc)

通过 Shell + AppleScript 直接操控 macOS 原生 Reminders.app，所有操作返回结构化 JSON。

## 何时使用

当用户提到或暗示以下需求时使用：`提醒/提醒事项/待办/任务/todo/清单/list`，或明确说 `Reminders.app`、`reminder/reminders` 的增删改查、完成、清理等操作。

## 前置条件

- **macOS** 系统
- **jq** 已安装（`brew install jq`）
- 终端已授予"提醒事项"访问权限（首次运行时系统会弹窗）
- **时间推断**：仅传 `--time` 不传 `--date` 时，默认用“本地日期 + 本地时区”推断

## 入口脚本

```bash
REMINDER_SH="/Users/jackwl/Code/allSkills/macos/reminder/reminder.sh"
```

可选：在当前目录运行时也可使用 `REMINDER_SH="$(pwd)/reminder.sh"`。

所有命令均通过此入口调用，格式：`bash $REMINDER_SH <action> [options]`

---

## 命令参考

### 1. 列出所有清单

```bash
bash $REMINDER_SH lists
```

**输出示例：**
```json
{"status":"success","action":"lists","count":3,"lists":["Reminders","工作","购物"]}
```

### 2. 创建提醒

```bash
bash $REMINDER_SH create --name "任务名称" [--date YYYY-MM-DD] [--time HH:MM] [--list "清单名"] [--notes "备注"]
```

| 参数 | 必填 | 默认值 | 说明 |
|------|------|--------|------|
| `--name` | ✅ | — | 提醒名称 |
| `--date` | ❌ | 无（仅提供 time 时自动用今天） | 日期，格式 `YYYY-MM-DD` |
| `--time` | ❌ | `09:00`（当 date 存在时） | 时间，格式 `HH:MM` |
| `--list` | ❌ | `Reminders` | 目标清单名称 |
| `--notes` | ❌ | 空 | 备注内容 |

**智能日期推断：** 仅传 `--time` 不传 `--date` 时，自动使用今天日期。

**输出示例：**
```json
{
  "status": "success",
  "action": "create",
  "reminder": {
    "id": "x-apple-reminder://...",
    "name": "买牛奶",
    "due_date": "2026-02-15T18:00:00",
    "list": "Reminders",
    "notes": "",
    "completed": false
  }
}
```

### 3. 查询提醒

```bash
bash $REMINDER_SH list [--list "清单名"] [--completed false|true|all] [--search "关键字"]
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--list` | 全部清单 | 筛选特定清单 |
| `--completed` | `false` | `false`=未完成, `true`=已完成, `all`=全部 |
| `--search` | 无 | 标题关键字搜索（在 AppleScript 层过滤，减少输出量） |

**输出示例：**
```json
{
  "status": "success",
  "action": "list",
  "count": 2,
  "reminders": [
    {"id":"...","name":"提交周报","due_date":"2026-02-10T17:00:00","list":"工作","notes":"","completed":false},
    {"id":"...","name":"买菜","due_date":"2026-02-11T09:00:00","list":"购物","notes":"","completed":false}
  ]
}
```

结果按 `due_date` 从近到远排序，无日期的排在最后。

### 4. 标记完成

```bash
# 方式一：通过 ID（最精准）
bash $REMINDER_SH complete --id "x-apple-reminder://..."

# 方式二：通过标题
bash $REMINDER_SH complete --title "任务名" [--list "清单名"]

# 方式三：多维度消歧（标题+时间定位）
bash $REMINDER_SH complete --title "任务名" [--match-date "YYYY-MM-DD"] [--match-time "HH:MM"]
```

**同名处理：** 若标题匹配到多条且未用消歧参数，返回 `candidates` 列表供确认。

### 5. 更新提醒

```bash
# 通过 ID
bash $REMINDER_SH update --id "x-apple-reminder://..." [--name "新名称"] [--date YYYY-MM-DD] [--time HH:MM] [--notes "新备注"]

# 通过标题
bash $REMINDER_SH update --title "旧名称" [--list "清单名"] [--name "新名称"] [--date ...] [--time ...] [--notes ...]

# 多维度消歧
bash $REMINDER_SH update --title "任务名" --match-date "YYYY-MM-DD" --match-time "HH:MM" [--name ...] [--date ...] [--time ...]
```

| 定位参数 | 说明 |
|---------|------|
| `--id` | 精确 ID 定位 |
| `--title` | 标题定位（大小写不敏感） |
| `--list` | 辅助定位清单 |
| `--match-date` | 消歧：匹配原到期日期 |
| `--match-time` | 消歧：匹配原到期时间 |

| 修改参数 | 说明 |
|---------|------|
| `--name` | 新标题 |
| `--date` | 新日期 |
| `--time` | 新时间 |
| `--notes` | 新备注 |

**重名碰撞检测：** 改名时若新名称已存在，返回 `"reason":"collision"` 错误。使用 `--force` 强制覆盖（先删同名再改名）。

### 6. 删除提醒

```bash
# 通过 ID
bash $REMINDER_SH delete --id "x-apple-reminder://..."

# 通过标题
bash $REMINDER_SH delete --title "任务名" [--list "清单名"]

# 多维度消歧
bash $REMINDER_SH delete --title "任务名" [--match-date "YYYY-MM-DD"] [--match-time "HH:MM"]
```

### 7. 清理已完成

```bash
# 清理所有已完成任务
bash $REMINDER_SH cleanup

# 仅清理特定清单
bash $REMINDER_SH cleanup --list "购物"
```

---

## 多维度消歧机制

当同名任务存在多条时，无需先 list 查 ID，直接用时间维度精准定位：

```bash
# 场景：两个"去领快递"，分别在 15:00 和 16:00
bash $REMINDER_SH complete --title "去领快递" --match-time "15:00"

# 场景：同名任务跨日期
bash $REMINDER_SH delete --title "每日站会" --match-date "2026-02-11" --match-time "09:00"
```

**支持消歧的操作：** `complete`、`update`、`delete`

---

## 歧义处理流程（LLM 必须遵守）

当返回 `reason: "ambiguous"` 且包含 `candidates` 时：

1. 先向用户确认目标项（展示候选的 `name`、`due_date`、`list`）。
2. 用户确认后再执行 `complete/update/delete`，并补齐 `--match-date/--match-time` 或 `--id`。

禁止在存在歧义时直接选择候选项。

---

## JSON 输出规范

所有命令返回 JSON，关键字段：

| 字段 | 含义 |
|------|------|
| `status` | `"success"` 或 `"error"` |
| `action` | 操作类型（`create`/`list`/`complete`/`update`/`delete`/`cleanup`/`lists`） |
| `message` | 错误时的详细信息 |
| `reason` | 特殊错误原因（如 `"collision"`、`"ambiguous"`） |
| `candidates` | 消歧失败时返回的候选列表 |
| `reminder` | 单条操作的提醒对象 |
| `reminders` | 列表查询的提醒数组 |

**提醒对象结构：**
```json
{
  "id": "x-apple-reminder://...",
  "name": "任务名",
  "due_date": "2026-02-15T18:00:00",
  "list": "清单名",
  "notes": "备注",
  "completed": false
}
```

---

## 错误响应处理（LLM 必须遵守）

当 `status: "error"`：

- 直接回显 `message`。
- 判断是否缺少定位信息（如 `--list`、`--match-date`、`--match-time` 或 `--id`），并向用户明确索要补充信息。

---

## 典型 LLM 工作流

### 工作流 A：创建提醒（最常用）

```bash
bash $REMINDER_SH create --name "提交周报" --date 2026-02-20 --time 17:00 --list "工作"
```

### 工作流 B：查询 → 完成

```bash
# 1. 查询待办
bash $REMINDER_SH list --search "周报"

# 2. 用返回的 ID 或标题完成
bash $REMINDER_SH complete --title "提交周报"
```

### 工作流 C：处理同名歧义

```bash
# 1. 尝试按标题完成
bash $REMINDER_SH complete --title "去领快递"
# 返回 candidates: [{...15:00...}, {...16:00...}]

# 2. 用时间消歧
bash $REMINDER_SH complete --title "去领快递" --match-time "15:00"
```

### 工作流 D：安全改名

```bash
# 1. 改名（自动碰撞检测）
bash $REMINDER_SH update --title "任务A" --name "任务B"
# 若 "任务B" 已存在 → collision 错误

# 2. 如确认要覆盖
bash $REMINDER_SH update --title "任务A" --name "任务B" --force
```

---

## 注意事项

1. **标题匹配大小写不敏感**：`"buy milk"` 等同于 `"Buy Milk"`
2. **日期格式严格**：必须 `YYYY-MM-DD`，时间必须 `HH:MM`（24小时制）
3. **清单名区分大小写**：清单名需与系统中完全一致
4. **首次运行**：macOS 会弹出权限请求对话框，需手动允许
5. **ID 格式**：`x-apple-reminder://` 开头的 URL 字符串，跨会话稳定

## 不支持/非目标

- 地点提醒
- 优先级
- 附件
