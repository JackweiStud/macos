#!/bin/bash
# ============================================
# macOS Reminders Tool - Shared Utilities
# ============================================

# --- Dependency Check ---
check_jq() {
    if ! command -v jq &>/dev/null; then
        echo '{"status":"error","action":"system","message":"jq not installed. Run: brew install jq"}'
        exit 1
    fi
}

# --- JSON Output ---
clean_error() {
    local err="$1"
    # Remove "NNN:MMM: execution error: " prefix
    err=$(echo "$err" | sed -E 's/^[0-9]+:[0-9]+: execution error: //')
    # Remove " (-NNNN)" suffix
    err=$(echo "$err" | sed -E 's/ \(-[0-9]+\)$//')
    echo "$err"
}

json_error() {
    local action="$1" message="$2"
    local clean_msg=$(clean_error "$message")
    jq -n --arg a "$action" --arg m "$clean_msg" '{status:"error",action:$a,message:$m}'
    exit 1
}

json_success() {
    local action="$1" message="$2"
    jq -n --arg a "$action" --arg m "$message" '{status:"success",action:$a,message:$m}'
}

# --- Input Validation ---
validate_date() {
    [[ "$1" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$ ]]
}

validate_time() {
    [[ "$1" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]
}

# --- AppleScript String Escaping ---
# 避免使用保留变量名（参考 LESSONS_LEARNED.md）
escape_as() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    echo "$str"
}

# --- Generate AppleScript date construction code ---
# Usage: build_date_as "reminderDate" "2026-02-20" "09:00"
build_date_as() {
    local var="$1" date_str="$2" time_str="${3:-00:00}"
    IFS='-' read -r year month day <<< "$date_str"
    IFS=':' read -r hour minute <<< "$time_str"
    # 使用 10# 前缀避免八进制解释（参考 LESSONS_LEARNED.md）
    month=$((10#$month)); day=$((10#$day))
    hour=$((10#$hour)); minute=$((10#$minute))
    cat <<AS
    set ${var} to current date
    set day of ${var} to 1
    set month of ${var} to ${month}
    set year of ${var} to ${year}
    set day of ${var} to ${day}
    set hours of ${var} to ${hour}
    set minutes of ${var} to ${minute}
    set seconds of ${var} to 0
AS
}

# --- AppleScript helper functions ---
applescript_helpers() {
    cat << 'ASHELP'
on formatDate(d)
    if d is missing value then return ""
    set y to year of d as text
    set m to (month of d as integer) as text
    if (count of characters of m) < 2 then set m to "0" & m
    set dy to day of d as text
    if (count of characters of dy) < 2 then set dy to "0" & dy
    set h to hours of d as text
    if (count of characters of h) < 2 then set h to "0" & h
    set mn to minutes of d as text
    if (count of characters of mn) < 2 then set mn to "0" & mn
    return y & "-" & m & "-" & dy & "T" & h & ":" & mn & ":00"
end formatDate

on cleanText(t)
    if t is missing value then return ""
    set t to t as text
    set oldD to AppleScript's text item delimiters
    set AppleScript's text item delimiters to tab
    set parts to text items of t
    set AppleScript's text item delimiters to " "
    set t to parts as text
    set AppleScript's text item delimiters to return
    set parts to text items of t
    set AppleScript's text item delimiters to linefeed
    set t to parts as text
    set AppleScript's text item delimiters to oldD
    return t
end cleanText

on reminderLine(r, listName)
    tell application "Reminders"
        set rID to r's id
        set rName to my cleanText(r's name)
        set rDue to ""
        try
            set rDue to my formatDate(r's due date)
        end try
        set rNotes to ""
        try
            set rNotes to my cleanText(r's body)
        end try
        set rCompleted to (r's completed as text)
        return rID & tab & rName & tab & rDue & tab & listName & tab & rNotes & tab & rCompleted
    end tell
end reminderLine
ASHELP
}

# --- Parse tab-separated reminder line(s) to JSON ---
reminders_to_json() {
    local action="$1"
    jq -R 'split("\t") | {id:.[0],name:.[1],due_date:(.[2]//null),list:.[3],notes:(.[4]//""),completed:(.[5]=="true")}' \
    | jq -s --arg a "$action" '{status:"success",action:$a,count:length,reminders:.}'
}

reminder_to_json() {
    local action="$1" line="$2"
    echo "$line" | jq -R 'split("\t") | {id:.[0],name:.[1],due_date:(.[2]//null),list:.[3],notes:(.[4]//""),completed:(.[5]=="true")}' \
    | jq --arg a "$action" '{status:"success",action:$a,reminder:.}'
}
