# Tests

This directory contains automated tests for the linux-setup project.

## Framework

Tests are written using [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core), a TAP-compliant testing framework for Bash.

## Installation

### Ubuntu/Debian

```bash
sudo apt-get install bats
```

### Alternative: Install from source

```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run all tests

```bash
bats tests/
```

### Run specific test file

```bash
bats tests/test_logging.bats
```

### Run with verbose output

```bash
bats --tap tests/
```

## Test Structure

- `test_logging.bats` - Tests for the shared logging library (`lib/logging.sh`)

## Writing New Tests

Test files should:
1. Use the `.bats` extension
2. Start with `#!/usr/bin/env bats`
3. Use `@test` annotations for each test case
4. Include `setup()` and `teardown()` functions for test initialization and cleanup

Example:

```bash
#!/usr/bin/env bats

setup() {
    # Run before each test
    source "$PROJECT_ROOT/lib/logging.sh"
}

teardown() {
    # Run after each test
    rm -f /tmp/test_*
}

@test "example test" {
    run my_function
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected output" ]]
}
```

## CI/CD Integration

Tests can be integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Run tests
  run: |
    sudo apt-get install -y bats
    bats tests/
```

## Coverage

Currently tested modules:
- ✅ lib/logging.sh (logging functions, backup function, error handling)

To be added:
- Installer script validation
- Template generation
- Configuration parsing
