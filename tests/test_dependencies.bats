#!/usr/bin/env bats

# Test dependencies.sh library functionality

setup() {
    # Load the logging library first
    load '../lib/logging.sh'
    
    # Load the dependencies library
    load '../lib/dependencies.sh'
}

# Test command_exists function
@test "command_exists returns success for existing command" {
    run command_exists bash
    [ "$status" -eq 0 ]
}

@test "command_exists returns failure for non-existing command" {
    run command_exists nonexistentcommand123
    [ "$status" -eq 1 ]
}

@test "command_exists handles command with path" {
    run command_exists /bin/bash
    [ "$status" -eq 0 ]
}

# Test check_dependencies function with existing commands
@test "check_dependencies succeeds with all existing commands" {
    run check_dependencies bash sh
    [ "$status" -eq 0 ]
}

@test "check_dependencies fails with some non-existing commands" {
    run check_dependencies bash nonexistentcommand123 sh
    [ "$status" -eq 1 ]
}

@test "check_dependencies outputs error for missing dependencies" {
    run check_dependencies bash nonexistentcommand123 sh
    [ "$status" -eq 1 ]
    # Should contain error message about missing dependencies
    echo "$output" | grep -qi "missing"
}

# Test get_package_manager function
@test "get_package_manager returns a valid package manager" {
    run get_package_manager
    local valid_managers=("nala" "apt-get" "apt" "none")
    local found=0
    for manager in "${valid_managers[@]}"; do
        if [ "$output" = "$manager" ]; then
            found=1
            break
        fi
    done
    [ "$found" -eq 1 ]
}