#!/usr/bin/env bats
# Test suite for lib/logging.sh

setup() {
    # Source the logging library
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    source "$PROJECT_ROOT/lib/logging.sh"

    # Create temporary log file for testing
    export LOG_FILE=$(mktemp)
}

teardown() {
    # Clean up temporary log file
    rm -f "$LOG_FILE"
}

@test "log_info outputs INFO message" {
    run log_info "test message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "INFO" ]]
    [[ "$output" =~ "test message" ]]
}

@test "log_error outputs ERROR message" {
    run log_error "error message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ERROR" ]]
    [[ "$output" =~ "error message" ]]
}

@test "log_success outputs SUCCESS message" {
    run log_success "success message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SUCCESS" ]]
    [[ "$output" =~ "success message" ]]
}

@test "log_warning outputs WARN message" {
    run log_warning "warning message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "WARN" ]]
    [[ "$output" =~ "warning message" ]]
}

@test "log_warn is alias for log_warning" {
    run log_warn "warning message"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "WARN" ]]
}

@test "log writes to LOG_FILE when set" {
    log_info "test log file"
    [ -f "$LOG_FILE" ]
    grep -q "test log file" "$LOG_FILE"
}

@test "log strips ANSI codes from log file" {
    log_info "color test"
    # Log file should not contain ANSI escape sequences
    ! grep -qP '\x1B\[' "$LOG_FILE"
}

@test "backup_file creates backup with timestamp" {
    local test_file=$(mktemp)
    echo "original content" > "$test_file"

    run backup_file "$test_file"
    [ "$status" -eq 0 ]

    # Check that backup file was created
    local backup_count=$(ls -1 "${test_file}.backup."* 2>/dev/null | wc -l)
    [ "$backup_count" -eq 1 ]

    # Cleanup
    rm -f "$test_file" "${test_file}.backup."*
}

@test "backup_file returns 0 when file doesn't exist" {
    run backup_file "/nonexistent/file"
    [ "$status" -eq 0 ]
}

@test "backup_file preserves content" {
    local test_file=$(mktemp)
    echo "test content" > "$test_file"

    backup_file "$test_file"

    # Check backup contains original content
    local backup=$(ls -1 "${test_file}.backup."* | head -1)
    [ "$(cat "$backup")" = "test content" ]

    # Cleanup
    rm -f "$test_file" "${test_file}.backup."*
}

@test "handle_error exits with status 1" {
    run handle_error "test error"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ERROR" ]]
    [[ "$output" =~ "test error" ]]
}
