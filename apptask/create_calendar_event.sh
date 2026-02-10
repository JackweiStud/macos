#!/bin/bash

# ============================================
# macOS 日历事件创建 - 通用脚本
# ============================================

# ---- 用户配置区 ----
# 【关键参数 - 必须填写】
EVENT_TITLE="聚会"           # 做什么
EVENT_DATE="2026-02-21"        # 日期 (YYYY-MM-DD)
EVENT_TIME="08:00"             # 时间 (HH:MM)

# 【可选参数 - 不填则用默认值】
CALENDAR_NAME="learn"           # 日历名称 (默认: Home、Work、learn)
ALARM_MINUTES=15                # 提前提醒分钟数 (默认: 0 = 事件开始时)
DURATION_MINUTES=30            # 持续时长 (默认: 30分钟)
LOCATION="小红书"                    # 地点 (默认: 空)
NOTES="带上外套"                       # 备注 (默认: 空)
IS_ALL_DAY=false               # 是否全天事件 (默认: false)

# ---- 脚本执行区 ----
# 解析日期时间以确保格式正确
IFS='-' read -r E_Year E_Month E_Day <<< "$EVENT_DATE"
IFS=':' read -r E_Hour E_Minute <<< "$EVENT_TIME"

osascript << EOF
tell application "Calendar"
    activate
    
    -- 设置日期时间
    -- 设置日期时间 (Robust Construction)
    set eventDate to current date
    set day of eventDate to 1
    set month of eventDate to $E_Month
    set year of eventDate to $E_Year
    set day of eventDate to $E_Day
    set hours of eventDate to $E_Hour
    set minutes of eventDate to $E_Minute
    set seconds of eventDate to 0
    set endDate to eventDate + ($DURATION_MINUTES * minutes)
    
    -- 选择日历
    tell calendar "$CALENDAR_NAME"
        -- 创建事件
        set newEvent to make new event with properties {summary:"$EVENT_TITLE", start date:eventDate, end date:endDate, allday event:$IS_ALL_DAY}
        
        -- 添加地点（如果有）
        if "$LOCATION" is not "" then
            set location of newEvent to "$LOCATION"
        end if
        
        -- 添加备注（如果有）
        if "$NOTES" is not "" then
            set description of newEvent to "$NOTES"
        end if
        
        -- 添加提醒
        if $ALARM_MINUTES > 0 then
            make new display alarm at end of newEvent with properties {trigger interval:-($ALARM_MINUTES * minutes)}
        else
            make new display alarm at end of newEvent with properties {trigger interval:0}
        end if
        
        return "✅ 创建成功: " & (summary of newEvent) & " | 时间: " & (start date of newEvent)
    end tell
end tell
EOF
