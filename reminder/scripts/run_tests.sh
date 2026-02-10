#!/bin/bash
# ============================================
# macOS Reminders CLI Stress Test Suite - v2
# ============================================

REMINDER_BIN="./reminder.sh"
TEST_LIST="Reminders" # Use existing list
RESULTS_FILE="test_results_v2.jsonl"

echo "Initializing Test Environment: List=$TEST_LIST"
rm -f "$RESULTS_FILE"

# Helper for running commands and logging JSON results
run_test() {
    local name="$1"
    local cmd="$2"
    echo "Running: $name..."
    local output=$(eval "$cmd")
    echo "{\"test_name\":\"$name\", \"command\":\"$cmd\", \"output\":$output}" >> "$RESULTS_FILE"
}

# 1. Discovery
run_test "JSON Protocol Check (Lists)" "$REMINDER_BIN lists"

# 2. Creation
run_test "Create Reminder Alpha" "$REMINDER_BIN create --name 'Alpha Test' --list '$TEST_LIST' --date '2026-12-25' --time '10:00'"

# 3. Disambiguation Test
run_test "Create Repeat One" "$REMINDER_BIN create --name 'Repeat' --list '$TEST_LIST' --time '12:00'"
run_test "Create Repeat Two" "$REMINDER_BIN create --name 'Repeat' --list '$TEST_LIST' --time '14:00'"
run_test "Disambiguate by Time (Complete)" "$REMINDER_BIN complete --title 'Repeat' --time '12:00' --list '$TEST_LIST'"

# 4. Search and List
run_test "Search Keyword" "$REMINDER_BIN list --search 'Alpha' --list '$TEST_LIST'"

# 5. Update
run_test "Update Title" "$REMINDER_BIN update --title 'Alpha Test' --name 'Alpha Updated' --list '$TEST_LIST'"

# 6. Cleanup (List-wide)
run_test "Cleanup List" "$REMINDER_BIN cleanup --list '$TEST_LIST'"

echo "Testing Complete. Results saved to $RESULTS_FILE"
