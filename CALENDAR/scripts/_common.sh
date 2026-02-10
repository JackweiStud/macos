#!/bin/bash
# ============================================
# macOS Calendar Tool - Shared Utilities
# ============================================

# --- Dependency Check ---
check_jq() {
    if ! command -v jq &>/dev/null; then
        echo '{"status":"error","action":"system","message":"jq not installed. Run: brew install jq"}'
        exit 1
    fi
}

# --- JSON Output ---
json_error() {
    local action="$1" message="$2"
    jq -n --arg a "$action" --arg m "$message" '{status:"error",action:$a,message:$m}'
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
escape_as() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    echo "$str"
}

# --- Generate AppleScript date construction code ---
# Usage: build_date_as "eventDate" "2026-02-20" "09:00"
build_date_as() {
    local var="$1" date_str="$2" time_str="${3:-00:00}"
    IFS='-' read -r year month day <<< "$date_str"
    IFS=':' read -r hour minute <<< "$time_str"
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

# --- AppleScript helper functions (embed in osascript heredocs) ---
applescript_helpers() {
    cat << 'ASHELP'
on formatDate(d)
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

on eventLine(e, calName)
    tell application "Calendar"
        set eUID to uid of e
        set eSummary to my cleanText(summary of e)
        set sd to e's start date
        set ed to e's end date
        set eStart to my formatDate(sd)
        set eEnd to my formatDate(ed)
        set eLoc to ""
        try
            set eLoc to my cleanText(location of e)
        end try
        set eNotes to ""
        try
            set eNotes to my cleanText(description of e)
        end try
        set eAllDay to e's allday event as text
        return eUID & tab & eSummary & tab & eStart & tab & eEnd & tab & calName & tab & eLoc & tab & eNotes & tab & eAllDay
    end tell
end eventLine
ASHELP
}

# --- Parse tab-separated event line(s) to JSON via jq ---
events_to_json() {
    local action="$1"
    jq -R 'split("\t") | {uid:.[0],title:.[1],start:.[2],end:.[3],calendar:.[4],location:(.[5]//""),notes:(.[6]//""),allday:(.[7]=="true")}' \
    | jq -s --arg a "$action" '{status:"success",action:$a,count:length,events:.}'
}

event_to_json() {
    local action="$1" line="$2"
    echo "$line" | jq -R 'split("\t") | {uid:.[0],title:.[1],start:.[2],end:.[3],calendar:.[4],location:(.[5]//""),notes:(.[6]//""),allday:(.[7]=="true")}' \
    | jq --arg a "$action" '{status:"success",action:$a,event:.}'
}
