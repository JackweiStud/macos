# macOS 日历事件创建脚本

用于通过命令行快速创建 macOS 日历事件。

## 快速开始

```bash
# 1. 进入目录
cd /Users/jackwl/Code/allSkills/macos/apptask

# 2. 赋予执行权限
chmod +x create_calendar_event.sh

# 3. 编辑脚本配置参数
# 4. 运行
./create_calendar_event.sh
```

## 参数说明

### 关键参数（必须）

| 参数 | 说明 | 示例 |
|------|------|------|
| `EVENT_TITLE` | 事件标题 | `"开会"` |
| `EVENT_DATE` | 日期 (YYYY-MM-DD) | `"2026-02-20"` |
| `EVENT_TIME` | 时间 (HH:MM) | `"09:00"` |

### 可选参数（有默认值）

| 参数 | 默认值 | 说明 | 示例 |
|------|--------|------|------|
| `CALENDAR_NAME` | `Home` | 日历名称 | `Work` / `learn` |
| `ALARM_MINUTES` | `0` | 提前提醒分钟数 | `15` / `60` |
| `DURATION_MINUTES` | `30` | 持续时长 | `60` / `120` |
| `LOCATION` | `""` | 地点 | `"公司"` |
| `NOTES` | `""` | 备注 | `"记得带身份证"` |
| `IS_ALL_DAY` | `false` | 是否全天事件 | `true` / `false` |

## 使用示例

### 示例 1: 简单事件
```bash
EVENT_TITLE="开会"
EVENT_DATE="2026-02-20"
EVENT_TIME="14:00"
# 其余使用默认值
```

### 示例 2: 完整事件
```bash
EVENT_TITLE="x账号充值--年费"
EVENT_DATE="2026-02-20"
EVENT_TIME="09:00"
CALENDAR_NAME="Home"
ALARM_MINUTES=15
DURATION_MINUTES=30
LOCATION="线上"
NOTES="记得准备付款方式"
```

### 示例 3: 全天事件
```bash
EVENT_TITLE="生日"
EVENT_DATE="2026-03-15"
EVENT_TIME="00:00"
IS_ALL_DAY=true
```

## 技术说明

- 使用 **AppleScript** 与 macOS 日历应用交互
- 通过 **osascript** 命令行工具执行
- 支持任意已存在的日历名称
- 自动处理日期时间格式

## 实现回顾

### 技术栈

| 工具/技术 | 说明 |
|----------|------|
| **AppleScript** | macOS 原生脚本语言 |
| **osascript** | 命令行执行 AppleScript |
| **macOS Calendar App** | 系统内置日历应用 |

### 核心代码

```applescript
-- 创建事件
make new event with properties {
    summary: "标题",
    start date: 开始时间,
    end date: 结束时间
}

-- 添加提醒
make new display alarm with properties {
    trigger interval: 0  -- 0表示事件开始时提醒
}
```

### 注意事项

- **日期格式**: AppleScript 只接受 `February 20, 2026` 格式
- **日历必须存在**: 指定的日历名称必须已存在
- **权限**: 首次运行可能需要授权脚本控制日历

## 常见问题

**Q: 如何查看可用的日历？**
```bash
osascript -e 'tell application "Calendar" to get name of every calendar'
```

**Q: 提醒时间如何设置？**
- `0` = 事件开始时提醒
- `15` = 提前15分钟提醒
- `60` = 提前1小时提醒

**Q: 支持创建重复事件吗？**
当前版本不支持，需要手动在日历应用中设置重复规则。

## 文件结构

```
/Users/jackwl/Code/allSkills/macos/apptask/
├── create_calendar_event.sh    # 主脚本
└── README.md                    # 本文档
```
