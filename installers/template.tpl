# ------------------------------------------------------------
# region Script Setup
# ------------------------------------------------------------
# Uncomment for verbose debugging
# set -x 

# ------------------------------------------------------------
# Setup Directory Variables
# ------------------------------------------------------------
# region
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# ------------------------------------------------------------
# region Determine top‑level directory
# ------------------------------------------------------------
# 1️⃣ Prefer Git if we are inside a repo
TOP="$(git rev-parse --show-toplevel 2>/dev/null)"

# 2️⃣ If not a Git repo, look for a known marker (e.g., .topdir)
if [[ -z "$TOP" ]]; then
  # Resolve the directory where this script resides
  SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

  # Walk upward until we find .topdir or stop at /
  DIR="$SCRIPT_DIR"
  while [[ "$DIR" != "/" ]]; do
    if [[ -f "$DIR/.topdir" ]]; then
      TOP="$DIR"
      break
    fi
    DIR="$(dirname "$DIR")"
  done
fi

# 3️⃣ Give up with a clear error if we still have no root
if [[ -z "$TOP" ]]; then
  echo "❌  Unable to locate project root. Ensure you are inside a Git repo or that a .topdir file exists."
  exit 1
fi

export TOP
log_info "(setup_bash.sh) Project root resolved to: $TOP"
# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

# ------------------------------------------------------------
# region Setup Logger
# ------------------------------------------------------------
LIB_DIR="$TOP/lib"

# Source Logger
source "$LIB_DIR/logging.sh" || exit 1
# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------

# ------------------------------------------------------------
# endregion
# ------------------------------------------------------------