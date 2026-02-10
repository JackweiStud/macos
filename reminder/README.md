# macOS 提醒事项 (Reminders) CLI

通过 AppleScript 管理 macOS 原生提醒事项的命令行工具。

## 功能特性

- **创建 (Create)**：创建带有截止日期、时间和备注的新提醒事项。
- **列表 (List)**：按列表名称或完成状态查询提醒事项。
- **清单 (Lists)**：列出所有可用的提醒事项清单（如：提醒、家庭等）。

## 使用方法

使用主入口脚本 `reminder.sh`。

```bash
./reminder.sh [操作] [选项]
```

### 操作详情

#### 1. 创建提醒事项
```bash
./reminder.sh create --name "任务标题" [--date YYYY-MM-DD] [--time HH:MM] [--list "清单名称"] [--notes "详细备注"]
```
- `--name`: (必填) 提醒事项的标题。
- `--date`: 截止日期，格式为 `YYYY-MM-DD`。
- `--time`: 截止时间，格式为 `HH:MM`（若提供了日期，默认时间为 `09:00`）。
- `--list`: 提醒清单名称（默认为 "Reminders"）。
- `--notes`: 提醒事项的详细主体文字。

#### 2. 列出提醒事项
```bash
./reminder.sh list [--list "清单名称"] [--completed true|false|all]
```
- `--list`: 过滤特定清单中的提醒事项。
- `--completed`: 按完成状态过滤（默认为 `false`，即只显示未完成）。使用 `all` 查看所有项。

#### 3. 列出可用清单
```bash
./reminder.sh lists
```

## 项目结构

项目结构如下：
- `reminder.sh`: 主入口脚本。
- `scripts/`: 具体逻辑实现。
  - `create_reminder.sh`: 创建提醒事项的逻辑。
  - `list_reminders.sh`: 查询提醒事项的逻辑。
  - `_common.sh`: 共享的 AppleScript 助手和实用函数。

## 实现细节

- **AppleScript**: 通过 `osascript` 使用 macOS 原生 AppleScript。
- **JSON 输出**: 所有命令均返回 JSON 格式结果，方便程序集成和调用。
- **错误处理**: 已处理 AppleScript 中的保留字冲突等常见问题（详见 `CALENDAR/LESSONS_LEARNED.md`）。
