---
invokable: true
---

Review this code for potential issues, including:

1. **Bash Scripting Best Practices**:
   - Proper use of `set -euo pipefail` for error handling
   - Correct variable scoping (readonly for constants, local for function variables)
   - Proper sourcing of shared libraries from `lib/` directory
   - Appropriate error handling with traps and cleanup functions
   - Safe file operations with proper backup before modification

2. **Dependency Management**:
   - Proper integration with `lib/dependencies.sh` functions
   - Correct use of `check_binary`, `install_package`, and other dependency functions
   - Appropriate fallback mechanisms for different Linux distributions

3. **Logging Standards**:
   - Consistent use of logging functions from `lib/logging.sh`
   - Proper log levels (log_info, log_warn, log_error, log_success)
   - Correct setup of log directories and file paths
   - Dual output to both terminal (with colors) and log files (without colors)

4. **Installer Script Structure**:
   - Following the template pattern from `installers/template.tpl`
   - Proper metadata in script headers (Description, Category, Usage)
   - Correct command-line argument parsing for non-interactive mode
   - Appropriate directory management and cleanup

5. **Security Considerations**:
   - No hardcoded secrets or credentials
   - Proper handling of sudo privileges with user prompts
   - Safe download and verification of external packages
   - Appropriate file permissions on created files

6. **User Experience**:
   - Clear and helpful error messages
   - Proper progress indication for long-running operations
   - Non-interactive mode support with -y/--yes flags
   - Helpful usage documentation in --help output

7. **Code Quality**:
   - ShellCheck compliance with no errors or warnings
   - Consistent code formatting and indentation
   - Descriptive function and variable names
   - Appropriate comments for complex logic

8. **Cross-Platform Compatibility**:
   - Proper detection and handling of different Linux distributions
   - Fallback mechanisms for missing dependencies
   - Appropriate use of distribution-specific package managers

Provide specific, actionable feedback for improvements.