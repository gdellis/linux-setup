# Remote Execution Branch Detection Solution

## Problem Description

When running the Python menu from a non-main branch (e.g., `remote-exec`), the installer scripts couldn't find the required library files because they were still looking on the `main` branch instead of the current branch.

This happened because:
1. The Python menu correctly detected it was running remotely and passed environment variables
2. However, the installer scripts used default branch values unless explicitly overridden
3. Without explicit branch specification, installers defaulted to the `main` branch

## Solution

There are two ways to solve this issue:

### Solution 1: Explicitly Set the REPO_BRANCH Environment Variable

```bash
REPO_BRANCH=remote-exec bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/remote-exec/bootstrap.sh) python-menu
```

### Solution 2: Use Full Environment Variable Specification

```bash
REPO_USER=gdellis REPO_NAME=linux-setup REPO_BRANCH=remote-exec bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/remote-exec/bootstrap.sh) python-menu
```

## How It Works

1. **Environment Variable Propagation**: The Python menu now properly passes all environment variables (`REPO_USER`, `REPO_NAME`, `REPO_BRANCH`) to remotely executed installers

2. **Default Values**: All scripts now have sensible defaults:
   - `REPO_USER`: gdellis
   - `REPO_NAME`: linux-setup
   - `REPO_BRANCH`: main

3. **Override Capability**: Users can override any or all of these values as needed

## Best Practices

1. **For Main Branch Usage**: No environment variables needed
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu
   ```

2. **For Custom Repositories**: Set REPO_USER and REPO_NAME
   ```bash
   REPO_USER=myuser REPO_NAME=myrepo bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/main/bootstrap.sh) python-menu
   ```

3. **For Feature Branches**: Set all three variables
   ```bash
   REPO_USER=gdellis REPO_NAME=linux-setup REPO_BRANCH=feature-branch bash <(curl -fsSL https://raw.githubusercontent.com/gdellis/linux-setup/feature-branch/bootstrap.sh) python-menu
   ```

## Future Improvements

While the current implementation works well, future enhancements could include:

1. **Automatic Branch Detection**: Scripts could attempt to detect the branch from the URL they were downloaded from
2. **GitHub API Integration**: Use the GitHub API to dynamically discover available installers
3. **Enhanced Error Handling**: More detailed error messages when remote resources cannot be found

## Testing Your Implementation

To verify your remote execution setup works correctly:

1. Test with default settings:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/bootstrap.sh) python-menu
   ```

2. Test with custom branch:
   ```bash
   REPO_USER=yourusername REPO_NAME=yourrepo REPO_BRANCH=yourbranch bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/yourbranch/bootstrap.sh) python-menu
   ```

3. Verify installers work:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/installers/setup_vscode.sh)
   ```

4. Verify bootstrap script works:
   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/bootstrap.sh) setup_vscode.sh
   ```