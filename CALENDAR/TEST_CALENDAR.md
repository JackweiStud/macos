# macOS CALENDAR - Black-box Test Design (calendar.sh)

## 1. 项目文件分析（结构与依赖）
- 入口脚本: `calendar.sh`
  - 根据 action 分发到 `scripts/*.sh` 子命令。
- 核心脚本:
  - `scripts/list_calendars.sh`  获取日历列表
  - `scripts/create_event.sh`    创建日程
  - `scripts/list_events.sh`     查询日程（按日期/范围/UID/标题）
  - `scripts/update_event.sh`    更新日程（按 UID）
  - `scripts/delete_event.sh`    删除日程（按 UID）
- 公共能力: `scripts/_common.sh`
  - jq 依赖检测、错误统一 JSON、日期/时间校验、AppleScript helper、事件 JSON 转换
- 参考/历史: `origindemo/`、`LESSONS_LEARNED.md`、`TEST_REPORT.md`

### 外部依赖/环境假设
- macOS 自带 Calendar.app 可被 AppleScript 调用
- `jq` 已安装
- 允许 AppleScript 权限（“自动化”权限）

### 与提醒事项实现的潜在差异
- 你提到 `reminder/scripts/_common.sh`、`reminder.sh` 已修改实现。
- 目前 `calendar` 与 `reminder` 的 `_common.sh` 在细节上存在差异：
  - `cleanText` 在 reminder 中会把 tab/换行替换为空格；calendar 版本目前对 tab/换行的处理更轻（仅把 tab/换行合并）。
  - reminder 版本对日期缺省处理、大小写匹配、辅助函数更丰富。
- 如果 calendar 需要对齐 reminder 的输入清洗/转义策略，应纳入改进建议。

---

## 2. 黑盒测试目标
- **功能覆盖**: 覆盖每个 action 的主路径与常见错误路径。
- **边界覆盖**: 覆盖日期/时间边界、可选参数边界、空结果、异常输入。
- **输出一致性**: JSON 格式与字段完整性。

---

## 3. 测试前准备
- 说明：所有测试为黑盒验证，不依赖内部实现。
- 运行方式：`bash /Users/jackwl/Code/allSkills/macos/CALENDAR/calendar.sh ...`
- 建议测试日历：准备一个可用日历，如 `Home` 或自建 `QA`。

---

## 4. 功能覆盖测试用例

### 4.1 `calendars` 列表
1. 正常获取
   - 命令: `calendar.sh calendars`
   - 期望: `status=success`，`count>=1`，返回 calendars 数组
2. 依赖缺失（jq）
   - 预置: 临时移除 `jq`（或在无 jq 环境执行）
   - 期望: `status=error`，message 提示安装 jq

### 4.2 `create` 创建
1. 最小必填
   - 命令: `create --title T1 --date 2026-02-20 --time 09:00`
   - 期望: success，返回 event 对象含 uid/title/start/end/calendar
2. 带所有可选字段
   - 命令: `create --title "开会" --date 2026-02-20 --time 14:00 --calendar Home --alarm 15 --duration 45 --location "会议室A" --notes "带电脑"`
   - 期望: success，字段落盘，alarm/notes/location 生效
3. 全天事件
   - 命令: `create --title "全天" --date 2026-02-21 --time 00:00 --all-day`
   - 期望: success，allday=true
4. 缺必填
   - `--title` 缺失
   - `--date` 缺失
   - `--time` 缺失
   - 期望: error，message 指出缺失项
5. 非法日期/时间
   - `--date 2026-13-01`
   - `--date 2026-02-30`
   - `--time 24:00`
   - `--time 09:60`
   - 期望: error
6. 负数/异常 duration/alarm
   - `--duration 0`、`--duration -5`（应回退到默认 30）
   - `--alarm -1`（应回退为 0）
   - 期望: success，end 时间与 alarm 不为非法值
7. 复杂字符
   - title/notes/location 含引号、反斜杠、emoji
   - 期望: 成功创建且内容未破坏

### 4.3 `list` 查询
1. 默认查询（无参数）
   - 命令: `list`
   - 期望: success，返回未来 7 天范围
2. 指定日期
   - `list --date 2026-02-20`
   - 期望: success，事件仅该日期
3. 指定范围
   - `list --from 2026-02-20 --to 2026-02-28`
   - 期望: success，范围内事件
4. 指定日历
   - `list --from ... --to ... --calendar Home`
   - 期望: success，仅该日历事件
5. 按标题包含匹配
   - `list --title "开会" --date 2026-02-20`
   - 期望: success，标题包含匹配
6. 按 UID 查询
   - 先创建事件获取 uid，再 `list --uid <uid>`
   - 期望: success，返回单条 event
7. 无结果
   - 选择无事件日期/范围
   - 期望: success，`count=0`，events 为空数组

### 4.4 `update` 更新
1. 更新标题
   - `update --uid <uid> --title "新标题"`
   - 期望: success，title 更新
2. 更新时间
   - `update --uid <uid> --time 15:30`
   - 期望: start/end 时间更新
3. 更新日期
   - `update --uid <uid> --date 2026-02-22`
4. 更新 duration
   - `update --uid <uid> --duration 60`
   - 期望: end-start=60min
5. 更新 location / notes
   - `update --uid <uid> --location "新地点"`
   - `update --uid <uid> --notes "新备注"`
6. 更新 alarm
   - `update --uid <uid> --alarm 10`
7. 缺 UID
   - `update --title x`
   - 期望: error
8. 无字段更新
   - `update --uid <uid>`
   - 期望: error（No fields to update）
9. 非法日期/时间
   - `--date 2026-02-31` 或 `--time 24:01`
   - 期望: error

### 4.5 `delete` 删除
1. 正常删除
   - `delete --uid <uid>`
   - 期望: success，返回被删 event
2. UID 不存在
   - `delete --uid non-existent-uid`
   - 期望: error

### 4.6 `calendar.sh` 入口
1. Unknown action
   - `calendar.sh foo`
   - 期望: error，提示未知 action
2. 无 action
   - `calendar.sh`
   - 期望: 输出 usage

---

## 5. 边界覆盖测试矩阵

### 日期边界
- 月初/月底: `2026-02-01`, `2026-02-28`
- 闰年日期: `2028-02-29`（校验应通过）
- 非闰年 2/29: `2026-02-29`（应报错）

### 时间边界
- 最小: `00:00`
- 最大: `23:59`
- 非法: `24:00`、`-1:00`、`09:60`

### 字符串边界
- 空字符串（应报错或忽略）
- 长字符串（title/notes/location 超长）
- 含特殊符号/引号/反斜杠

### UID 边界
- 空 UID
- 超长 UID
- 非存在 UID

---

## 6. 黑盒验证要点（输出）
- 所有成功返回为 JSON，结构包含 `status`, `action`。
- `list` 输出包含 `count`、`events`。
- `create/update/delete` 返回单个 `event` 对象。
- `calendars` 返回 `calendars` 数组。

---

## 7. 问题与改进建议

### 问题
1. `calendar` 的 `cleanText` 对 tab/换行处理不够彻底，可能导致 JSON 结构不稳定。
2. `list` 的默认范围依赖 `date -v+7d`，在非 macOS 环境不可用（但此项目定位 macOS）。
3. `create` 中 `--all-day` 仍要求 `--time`，与用户直觉（全日事件不需要时间）可能不一致。
4. 目前 `list` 的标题匹配仅为 `contains`，无大小写选择、精确匹配能力。
5. `update` 对 `--duration` 未验证是否为数值正整数，可能传入非法字符串导致 AppleScript 报错。

### 改进建议
1. 对齐 reminder 的 `_common.sh` 清洗策略（将 tab/换行替换为空格），保证 JSON 输出稳定。
2. `create --all-day` 情况可允许省略 `--time`，默认 `00:00`。
3. 增加输入数值校验（duration/alarm 只允许正整数）。
4. `list` 增加 `--exact-title` 或 `--ignore-case` 选项。
5. 增加 `list --all-day` 过滤参数。

---

## 8. 交付物
- 本测试设计文档即为 `TEST_CALENDAR.md`。
