# macOS Calendar CLI (mcc) 📅

这是一个为 macOS 全面定制的日历命令行工具，允许你直接从终端管理系统自带的日历事件，支持增、删、改、查全流程操作，并提供结构化的 JSON 输出。

## 🚀 核心价值

*   **极速操作**：无需打开臃肿的日历 GUI 界面，几秒钟内完成事件记录。
*   **自动化友好**：纯命令行设计，支持 JSON 输出，可轻松集成到 Raycast、Alfred、快捷指令或 Shell 脚本中。
*   **原生集成**：直接读写 macOS 系统级日历数据库，数据全设备同步。

## ⚠️ 解决的问题

1.  **GUI 干扰**：工作时切换到日历应用容易打断思路。
2.  **批量操作难**：原生应用不支持通过脚本批量创建或查询特定范围的事件。
3.  **信息不透明**：很难从系统中快速导出特定日期范围的 JSON 格式数据。

### 没有这个工具怎么解决？
*   **手动操作**：打开日历 App -> 找到日期 -> 点击创建 -> 填写字段，流程繁琐。
*   **原生 AppleScript**：需要用户编写冗长且晦涩的 AppleScript 代码，处理繁琐的日期格式化和转义逻辑。

## 🛠️ 如何使用

主要入口为 `calendar.sh`。

### 1. 列出所有日历
```bash
./calendar.sh calendars
```

### 2. 创建事件
```bash
./calendar.sh create --title "团队内测" --date 2026-02-20 --time 14:00 --duration 60 --location "会议室A"
```

### 3. 查询事件
```bash
# 查询未来 7 天的所有事件（默认行为）
./calendar.sh list

# 查询特定日期的所有事件
./calendar.sh list --date 2026-02-20

# 查询标题包含“会议”的事件
./calendar.sh list --from 2026-02-01 --to 2026-02-28 --title "会议"
```

### 4. 更新事件
```bash
./calendar.sh update --uid <EVENT_UID> --title "新的会议标题" --time 15:30
```

### 5. 删除事件
```bash
./calendar.sh delete --uid <EVENT_UID>
```

## 🏗️ 技术实现

### 技术栈
*   **Shell (Bash)**：负责参数解析、逻辑控制和流程调度。
*   **AppleScript (osascript)**：负责与 macOS 系统应用 `Calendar.app` 进行底层交互。
*   **JSON (jq)**：负责对输出数据进行结构化和过滤，确保结果机器可读。

### 核心架构
*   `calendar.sh`：调度中控。
*   `scripts/_common.sh`：共享库，处理 AppleScript 日期构造、字符串清洗和 JSON 封装。
*   `scripts/*.sh`：具体的增删改查实现模块。

## 📋 依赖要求
1.  **macOS** 系统（自带 Calendar 应用）。
2.  **jq**：用于 JSON 处理（可通过 `brew install jq` 安装）。
3.  **系统权限**：首次运行需要授予终端控制日历的权限。

## 🔮 未来扩展
- [ ] **自然语言支持**：支持像“明天下午三点开会”这样的自然语言输入。
- [ ] **交互式模式**：提供更友好的交互式命令行界面。
- [ ] **通知集成**：支持通过终端直接触发系统桌面通知。
- [ ] **iCal 支持**：支持通过 .ics 链接或文件导入/导出。
- [ ] **多端同步状态检查**：显示事件是否已同步完成。

---

**由 Antigravity 开发 | 2026**
