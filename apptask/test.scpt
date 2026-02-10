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
    set AppleScript's text item delimiters to "\\n"
    set t to parts as text
    set AppleScript's text item delimiters to oldD
    return t
end cleanText

on eventLine(e, calName)
    set eUID to uid of e
    set eSummary to my cleanText(summary of e)
    set sd to start date of e
    set ed to end date of e
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
    set eAllDay to allday event of e as text
    return eUID & tab & eSummary & tab & eStart & tab & eEnd & tab & calName & tab & eLoc & tab & eNotes & tab & eAllDay
end eventLine

tell application "Calendar"
    set eventDate to current date
    set day of eventDate to 1
    set month of eventDate to 2
    set year of eventDate to 2026
    set day of eventDate to 15
    set hours of eventDate to 10
    set minutes of eventDate to 0
    set seconds of eventDate to 0
    set endDate to eventDate + (60 * minutes)

    tell calendar "Home"
        set newEvent to make new event with properties {summary:"测试会议", start date:eventDate, end date:endDate, allday event:false}

        if "会议室A" is not "" then
            set location of newEvent to "会议室A"
        end if

        if "这是一个测试事件" is not "" then
            set description of newEvent to "这是一个测试事件"
        end if

        if 15 > 0 then
            make new display alarm at end of newEvent with properties {trigger interval:-(15 * 60)}
        else
            make new display alarm at end of newEvent with properties {trigger interval:0}
        end if

        return my eventLine(newEvent, "Home")
    end tell
end tell
