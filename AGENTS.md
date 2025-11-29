# Repository Overview

## Project Description
- **What this project does**: Automates the setup of a Linux development environment with customized bash configuration, CLI tools, and AI model management
- **Main purpose and goals**: 
  - Streamline bash environment setup with aliases, prompt customization, and logging
  - Automate installation and configuration of development tools
  - Manage Ollama AI models for local and cloud inference
- **Key technologies used**: Bash scripting, TOML configuration, Ollama AI models, Starship prompt

## Architecture Overview
- **High-level architecture**: Modular bash scripts that handle different aspects of system setup
- **Main components and their relationships**:
  - `setup_bash.sh`: Main script for bash environment configuration
  - `logging.sh`: Centralized logging functions
  - `setup_ollama.sh`: AI model management
  - Bash configuration files (`.bashrc`, `.bash_aliases`)
  - Configuration files (`.config.toml`)
- **Data flow and system interactions**: 
  - Scripts backup existing configurations before applying changes
  - Symbolic links are created to reference the new configuration files
  - Ollama models are downloaded based on predefined lists

## Directory Structure
- **Important directories and their purposes**:
  - `bash/`: Contains bash configuration files (`.bashrc`, `.bash_aliases`)
  - `.continue/`: Continue CLI configuration and rules
  - `backups/`: Stores backups of original configuration files
- **Key files and configuration**:
  - `setup_bash.sh`: Main bash setup script with backup and symlink creation
  - `setup_ollama.sh`: Ollama model management script
  - `logging.sh`: Shared logging functions
  - `setup_config.toml`: Configuration for auto-executed tools
- **Entry points and main modules**:
  - `setup_bash.sh`: Entry point for bash environment setup
  - `setup_ollama.sh`: Entry point for AI model setup

## Development Workflow
- **How to build/run the project**: 
  - Execute `./setup_bash.sh` to configure bash environment
  - Run `./setup_ollama.sh` to download AI models
- **Testing approach**: 
  - Manual validation of bash configuration after setup
  - Verification of symbolic links creation
  - Model availability checks with Ollama
- **Development environment setup**: 
  - Requires bash shell environment
  - Dependencies: curl, starship, ollama (for AI components)
- **Lint and format commands**: 
  - No specific linter configured, but general shellcheck practices apply
  - Scripts follow standard bash conventions with error handling