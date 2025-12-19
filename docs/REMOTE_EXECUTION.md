# Running Installers Remotely

The installer scripts in this repository can be run directly from the internet using curl, without needing to download the entire repository first.

You can also run the TUI menus directly:

```bash
# Run the bash TUI menu directly
bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) menu

# Run the Python TUI menu directly
bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu

# Run the Python TUI menu with custom repository
REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu
```

## How It Works

Each installer script can detect whether it's running locally or remotely. When run remotely:

1. The script detects it's running from a temporary location
2. It sources the required library files directly from the GitHub repository
3. It executes the installation logic as normal

The Python menu works similarly but can also discover and run installers from remote repositories.

## Usage Examples

### Run VS Code Installer Remotely

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/installers/setup_vscode.sh)
```

### Run Neovim Installer Remotely

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/installers/setup_neovim.sh)
```

### Run with Options

You can pass options just like you would locally:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/linux-setup/main/installers/setup_vscode.sh) --yes
```

## For Script Developers

When you create a new installer with `./installers/new_installer.sh`, it will automatically include remote execution capability.

The template includes:

1. A function to detect if running locally or remotely
2. A function to source libraries appropriately
3. Usage instructions in the script header

## Benefits

- **No repository download required**: Users can run specific installers directly
- **Always up-to-date**: Scripts are downloaded fresh from the repository
- **Consistent functionality**: Remote execution provides the same features as local execution
- **Easy sharing**: Simple one-liner commands for users

## Requirements

- **curl** must be installed on the system
- **Internet connectivity** to download library files
- **bash** shell (version 4.0 or higher)

## How to Set Up for Your Repository

To make this work with your own repository, you can either:

1. Set environment variables before running the scripts:
   ```bash
   export REPO_USER="your-github-username"
   export REPO_NAME="your-repo-name"
   export REPO_BRANCH="main"  # optional, defaults to main
   ```

2. Or set them inline when running scripts:
   ```bash
   REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) setup_vscode.sh
   ```

3. Or let the scripts prompt you for the repository information (if not set)

This approach makes the scripts much more flexible and eliminates the need to modify the source code for different repositories.

## Security Considerations

- Only run scripts from trusted sources
- Review scripts before running them remotely
- Remote execution requires the same sudo permissions as local execution
- All logging and error handling works the same as local execution

## Troubleshooting

If remote execution fails:

1. Check internet connectivity
2. Verify the script URL is correct
3. Ensure curl is installed: `sudo apt-get install curl`
4. Check that the repository and file paths are correct

Example error message:
```
ERROR: Failed to source logging.sh from remote repository
```

This indicates the script couldn't download the library files, likely due to network issues or incorrect repository paths.