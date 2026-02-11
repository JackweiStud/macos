# macOS Automation Skills

A collection of system-level automation skills for macOS, bridging the gap between LLMs and native applications (Calendar, Reminders) via CLI and AppleScript.

## 🚀 Overview

This project provides a standardized CLI interface for macOS native apps, enabling AI agents to perform complex system operations safely and structurally.

## 🧩 Core Capabilities (Dimensions)

| Dimension | Module | Checkpoints |
|-----------|--------|-------------|
| **Schedule** | `CALENDAR` | • Event CRUD (Create/List/Update/Delete)<br>• Smart Date Inference<br>• Conflict Checks |
| **Tasks** | `reminder` | • Task Management<br>• Multi-dimensional Disambiguation (Title/Time)<br>• Bulk Cleanup |
| **Intelligence** | `antigravity` | • Headless `agy` CLI Automation<br>• News Aggregation<br>• Process Isolation |

---

## 📂 Directory Structure

```
/Users/jackwl/Code/allSkills/macos/
├── CALENDAR/           # macOS Calendar CLI (mcc)
│   ├── calendar.sh     # Main entry point
│   └── SKILL.md        # LLM Instructions
├── reminder/           # macOS Reminder CLI (mrc)
│   ├── reminder.sh     # Main entry point
│   └── SKILL.md        # LLM Instructions
├── antigravity/        # Antigravity AI Automation
│   ├── auto_news_v2.sh # Automated news fetcher
│   └── README.md       # Module documentation
└── README.md           # This file
```

---

## 🛠️ Module Details

### 1. Calendar (mcc)
> **Goal**: Manage schedule and appointments via CLI.

**Usage:**
```bash
# Entry Point
CALENDAR_SH="./CALENDAR/calendar.sh"

# Create Event
bash $CALENDAR_SH create --title "Meeting" --date 2026-02-20 --time 14:00

# List Events
bash $CALENDAR_SH list --days 3
```

**Key Features:**
*   **Structured JSON Output**: All commands return parsable JSON.
*   **Safety**: Destructive actions (delete) require specific IDs.
*   **Privacy**: Local execution via AppleScript.

### 2. Reminder / Planner (mrc)
> **Goal**: Manage todo lists and tasks with high precision.

**Usage:**
```bash
# Entry Point
REMINDER_SH="./reminder/reminder.sh"

# Create Task
bash $REMINDER_SH create --name "Buy Milk" --list "Shopping"

# Complete Task (with disambiguation)
bash $REMINDER_SH complete --title "Buy Milk" --match-time "14:00"
```

**Key Features:**
*   **Disambiguation**: Handles duplicate task names via time matching.
*   **Collision Detection**: Prevents accidental overwrites.
*   **Smart Cleanup**: Tools to clear completed tasks.

### 3. Antigravity Automation
> **Goal**: Execute ephemeral AI tasks in isolated environments.

**Usage:**
```bash
# Run News Fetcher
bash ./antigravity/auto_news_v2.sh
```

**Key Features:**
*   **Process Isolation**: Uses `--user-data-dir` to avoid polluting main browser/app profiles.
*   **Direct Prompt Injection**: Bypasses UI interactions for stability.
*   **Auto-Cleanup**: Self-terminating resources.

---

## 🚦 Quick Start

### Prerequisites
1.  **macOS**: Required for AppleScript support.
2.  **jq**: Required for JSON processing (`brew install jq`).
3.  **Permissions**: First run will trigger macOS accessibility/automation prompts for Calendar/Reminders/System Events.

### Installation
No build required. Scripts are interpreted Bash/AppleScript.
Ensure scripts are executable if needed:
```bash
chmod +x CALENDAR/*.sh reminder/*.sh antigravity/*.sh
```

---

## 🔄 Workflow Example

**Scenario**: "Get the latest AI news and schedule a time to read it."

1.  **Antigravity**: Runs `auto_news_v2.sh` -> generates `ai_news_result.json`.
2.  **Calendar**: Reads JSON -> `bash calendar.sh create --title "Read AI News" ...`.
3.  **Reminder**: `bash reminder.sh create --name "Share AI findings" ...`.

---

## ⚖️ License
Personal Use / MIT
