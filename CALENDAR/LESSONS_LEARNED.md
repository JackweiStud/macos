# macOS Calendar AppleScript 开发问题总结

> 本文档总结了使用 AppleScript 开发 macOS 日历增删改查功能时遇到的所有问题、根本原因和解决方案。

## 📋 目录

- [问题清单](#问题清单)
- [详细分析](#详细分析)
- [最佳实践 Checklist](#最佳实践-checklist)
- [调试技巧](#调试技巧)

---

## 问题清单

| # | 问题类型 | 严重程度 | 状态 |
|---|---------|---------|------|
| 1 | AppleScript 时间单位语法错误 | 🔴 高 | ✅ 已解决 |
| 2 | Bash 保留变量冲突 | 🟡 中 | ✅ 已解决 |
| 3 | AppleScript 属性名保留字冲突 | 🔴 高 | ✅ 已解决 |
| 4 | 转义字符处理错误 | 🟡 中 | ✅ 已解决 |

---

## 详细分析

### 问题 #1: AppleScript 时间单位语法错误

#### 🔍 问题现象
```applescript
set endDate to eventDate + ($DURATION * minutes)
```
**错误信息**:
```
1168:1172: syntax error: Expected end of line, etc. but found class name. (-2741)
```

#### 🎯 根本原因
- 初始认为 `minutes` 是 AppleScript 的时间常量，可以直接用于算术运算
- 实际上在某些上下文中，`minutes` 既是日期属性（如 `minutes of date`），又是时间单位常量
- 当在同一作用域中同时使用 `set minutes of eventDate to 0` 和 `$DURATION * minutes` 时，编译器会混淆

#### ✅ 解决方案
**方案 1**: 使用秒数代替（推荐）
```applescript
set endDate to eventDate + ($DURATION * 60)  # 转换为秒
```

**方案 2**: 使用 `minutes` 常量（需确保无冲突）
```applescript
set endDate to eventDate + (30 * minutes)  # 仅在不设置 minutes 属性时使用
```

#### 📝 经验教训
- ⚠️ 避免在同一作用域中混用属性名和常量名
- ✅ 优先使用明确的单位（秒数），避免歧义
- ✅ AppleScript 的时间运算：`1 * hours = 3600 秒`, `1 * minutes = 60 秒`

---

### 问题 #2: Bash 保留变量冲突

#### 🔍 问题现象
```bash
UID=""  # 用于存储事件 UID
```
**错误信息**:
```
line 11: UID: readonly variable
```

#### 🎯 根本原因
- `UID` 是 Bash 的内置只读环境变量，表示当前用户的 User ID
- 尝试修改 `UID` 会导致脚本失败

#### ✅ 解决方案
```bash
# ❌ 错误
UID=""

# ✅ 正确
EVENT_UID=""
```

#### 📝 经验教训
- ⚠️ **Bash 常见保留变量**:
  - `UID` - 用户 ID
  - `EUID` - 有效用户 ID
  - `PPID` - 父进程 ID
  - `PWD` - 当前工作目录
  - `OLDPWD` - 上一个工作目录
  - `RANDOM` - 随机数
  - `SECONDS` - 脚本运行秒数
- ✅ 使用描述性前缀避免冲突（如 `EVENT_UID`, `USER_INPUT` 等）
- ✅ 使用 `readonly` 命令查看所有只读变量：`readonly -p`

---

### 问题 #3: AppleScript 属性名保留字冲突

#### 🔍 问题现象

**场景 1**: 在函数内部访问属性
```applescript
on eventLine(e, calName)
    set sd to start date of e  # ❌ 错误
    set ed to end date of e    # ❌ 错误
end eventLine
```
**错误信息**:
```
103:107: syntax error: Expected end of line, etc. but found class name. (-2741)
```

**场景 2**: 设置属性时使用管道符转义
```applescript
set |start date| of targetEvent to eventDate  # ❌ 错误
```
**错误信息**:
```
256:305: execution error: Can't make |start date| ... into type specifier. (-1700)
```

#### 🎯 根本原因

1. **保留字冲突**:
   - `date` 是 AppleScript 的保留字/类名
   - `event` 是 AppleScript 的保留字/类名
   - 当属性名包含保留字（如 `start date`, `end date`, `allday event`）时，编译器会产生歧义

2. **上下文依赖**:
   - 在 `tell application "Calendar"` 块**内部**：可以直接使用 `start date of e`
   - 在**函数内部**（非 tell 块）：`start date of e` 会导致语法错误
   - **设置属性**时：不能使用管道符转义 `|start date|`
   - **读取属性**时（在函数内）：需要特殊处理

#### ✅ 解决方案

**方案 1**: 在函数内使用 `tell` 块 + 所有格语法（推荐）
```applescript
on eventLine(e, calName)
    tell application "Calendar"
        set eUID to uid of e
        set sd to e's start date      # ✅ 使用所有格语法
        set ed to e's end date        # ✅ 使用所有格语法
        set eAllDay to e's allday event as text
        return eUID & tab & sd & tab & ed
    end tell
end eventLine
```

**方案 2**: 在 tell 块内直接访问（用于非函数代码）
```applescript
tell application "Calendar"
    repeat with cal in calendars
        set matched to (every event of cal whose uid = targetUID)
        if (count of matched) > 0 then
            set targetEvent to item 1 of matched
            # ✅ 在 tell 块内，直接访问属性
            set sd to start date of targetEvent
            set ed to end date of targetEvent
            # ✅ 设置属性时不使用管道符
            set start date of targetEvent to newDate
            set end date of targetEvent to newEndDate
        end if
    end repeat
end tell
```

**方案 3**: 使用管道符转义（仅用于读取，不推荐）
```applescript
# ⚠️ 仅在特定情况下使用
set sd to |start date| of e  # 读取时可用
set |start date| of e to d   # ❌ 设置时不可用
```

#### 📝 经验教训

**属性访问规则总结**:

| 上下文 | 读取属性 | 设置属性 | 示例 |
|--------|---------|---------|------|
| `tell` 块内 | ✅ 直接访问 | ✅ 直接设置 | `start date of e` |
| 函数内（有 `tell` 块） | ✅ 所有格语法 | ✅ 直接设置 | `e's start date` |
| 函数内（无 `tell` 块） | ❌ 语法错误 | ❌ 语法错误 | - |
| Properties 字典 | ✅ 直接使用 | ✅ 直接使用 | `{start date:d}` |

**常见保留字属性**:
- `start date` / `end date` - 包含保留字 `date`
- `allday event` - 包含保留字 `event`
- `text item delimiters` - 包含保留字 `text`

**最佳实践**:
1. ✅ **优先使用所有格语法**: `e's start date` 比 `start date of e` 更安全
2. ✅ **在函数内使用 `tell` 块**: 确保 AppleScript 对象在正确的上下文中
3. ✅ **设置属性时不使用转义**: `set start date of e to d`（不是 `set |start date| of e to d`）
4. ✅ **在 `properties` 字典中直接使用**: `{start date:d, end date:ed}`
5. ⚠️ **避免使用管道符转义**: 除非绝对必要，否则不使用 `|property name|`

---

### 问题 #4: 转义字符处理错误

#### 🔍 问题现象
```applescript
set AppleScript's text item delimiters to "\\n"
```
在 heredoc 中定义为：
```bash
cat << 'ASHELP'
set AppleScript's text item delimiters to "\\n"
ASHELP
```

#### 🎯 根本原因
- 在 Bash heredoc 中，`\\n` 会被保留为字面量 `\n`（两个字符）
- 但在某些情况下，我们写成了 `\\\\n`（四个反斜杠），导致 AppleScript 接收到 `\\n`（字面量反斜杠 + n）

#### ✅ 解决方案

**方案 1**: 使用 AppleScript 内置常量（推荐）
```applescript
set AppleScript's text item delimiters to linefeed  # ✅ 换行符
set AppleScript's text item delimiters to return    # ✅ 回车符
set AppleScript's text item delimiters to tab       # ✅ 制表符
```

**方案 2**: 正确的转义
```bash
# 在单引号 heredoc 中
cat << 'EOF'
set AppleScript's text item delimiters to "\\n"  # 生成 \n
EOF

# 在双引号 heredoc 中
cat << EOF
set AppleScript's text item delimiters to "\\\\n"  # 生成 \n
EOF
```

#### 📝 经验教训
- ✅ **优先使用 AppleScript 内置常量**: `linefeed`, `return`, `tab`, `space`
- ✅ **使用单引号 heredoc**: `<< 'EOF'` 避免 shell 变量展开
- ⚠️ **注意转义层级**: Shell → AppleScript 有两层转义
- ✅ **测试特殊字符**: 使用 `hexdump` 或 `od` 检查实际字符

---

## 最佳实践 Checklist

### ✅ AppleScript 编码规范

- [ ] **时间运算**: 使用秒数 `* 60` 而不是 `* minutes`
- [ ] **属性访问**: 在函数内使用所有格语法 `e's property`
- [ ] **Tell 块**: 函数内部访问 Calendar 对象时使用 `tell application "Calendar"`
- [ ] **属性设置**: 直接使用属性名，不使用管道符转义
- [ ] **特殊字符**: 使用内置常量 `linefeed`, `return`, `tab`
- [ ] **错误处理**: 避免空 `try` 块吞掉错误，至少记录日志

### ✅ Bash 脚本规范

- [ ] **变量命名**: 避免使用 Bash 保留变量（`UID`, `PWD`, `RANDOM` 等）
- [ ] **Heredoc**: 使用单引号 `<< 'EOF'` 避免变量展开
- [ ] **函数调用**: 确保 `source` 的函数在正确的作用域中
- [ ] **错误检查**: 使用 `[ $? -ne 0 ]` 检查命令执行状态
- [ ] **参数验证**: 验证必需参数，提供清晰的错误信息

### ✅ 调试规范

- [ ] **保存中间结果**: 将生成的 AppleScript 保存到文件以便检查
- [ ] **逐步测试**: 从简单的 AppleScript 开始，逐步增加复杂度
- [ ] **错误定位**: 使用字节偏移量定位语法错误的具体位置
- [ ] **隔离测试**: 单独测试函数，确认功能正确后再集成
- [ ] **移除 try 块**: 调试时临时移除 `try` 块，查看真实错误

---

## 调试技巧

### 1. 查看生成的 AppleScript

```bash
# 方法 1: 保存到文件
cat > /tmp/test.applescript << 'EOF'
$(applescript_helpers)
tell application "Calendar"
    # your code
end tell
EOF
cat /tmp/test.applescript  # 检查生成的代码

# 方法 2: 直接输出
echo "$(applescript_helpers)" | head -50
```

### 2. 定位语法错误位置

```bash
# AppleScript 错误通常给出字节偏移量
# 例如: "1168:1172: syntax error"
# 使用 awk 找到对应的行

awk 'BEGIN{c=0} {
    for(i=1;i<=length($0)+1;i++){
        c++; 
        if(c==1168){
            print NR": char "i" -> "$0; 
            exit
        }
    }
}' /tmp/test.applescript
```

### 3. 测试 AppleScript 片段

```bash
# 快速测试小片段
osascript << 'EOF'
tell application "Calendar"
    tell calendar "Home"
        return count of events
    end tell
end tell
EOF
```

### 4. 检查 Bash 变量

```bash
# 查看只读变量
readonly -p

# 检查变量是否已定义
echo "UID=$UID"  # 会显示当前用户 ID

# 测试变量赋值
UID="test" 2>&1  # 会报错: readonly variable
```

### 5. 验证转义字符

```bash
# 使用 hexdump 查看实际字符
echo "\\n" | hexdump -C
echo "\\\\n" | hexdump -C

# 或使用 od
echo "\\n" | od -c
```

---

## 常见错误速查表

| 错误信息 | 可能原因 | 解决方案 |
|---------|---------|---------|
| `Expected end of line, etc. but found class name` | 属性名包含保留字 | 使用所有格语法或 tell 块 |
| `Can't make ... into type specifier` | 设置属性时使用了管道符 | 移除管道符，直接使用属性名 |
| `readonly variable` | 使用了 Bash 保留变量 | 重命名变量，添加前缀 |
| `Event not found with UID` | UID 变量被覆盖为用户 ID | 使用 `EVENT_UID` 代替 `UID` |
| 返回空字符串 | `try` 块吞掉了错误 | 移除 `try` 块或添加错误处理 |
| 嵌套 tell 块无输出 | 上下文冲突 | 确保函数内有正确的 tell 块 |

---

## 参考资源

### AppleScript 文档
- [AppleScript Language Guide](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/)
- [Calendar Suite Dictionary](https://developer.apple.com/library/archive/documentation/AppleScript/Reference/StdSuites/Calendar_Suite/)

### Bash 文档
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/bash.html)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)

### 调试工具
- `osascript` - 执行 AppleScript
- `osacompile` - 编译 AppleScript
- `hexdump` / `od` - 查看字节内容
- `jq` - JSON 处理

---

## 版本历史

| 版本 | 日期 | 变更说明 |
|------|------|---------|
| 1.0 | 2026-02-10 | 初始版本，总结所有已知问题 |

---

## 贡献

如果发现新的问题或有更好的解决方案，请更新本文档。

**文档维护者**: 开发团队  
**最后更新**: 2026-02-10
