# Source this file before working on the project:  source env.sh
_TT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

source "$_TT_ROOT/.venv/bin/activate"

export PDK_ROOT="$HOME/.ciel"
export PDK=sky130A
export PATH="$HOME/.local/riscv/bin:/opt/homebrew/bin:$PATH"

# Make sure the Docker VM (used by LibreLane --dockerized) is running
if ! docker info >/dev/null 2>&1; then
  echo "[env] Starting Colima Docker VM..."
  colima start >/dev/null 2>&1 || echo "[env] WARNING: colima failed to start"
fi

echo "[env] TinyTapeout env ready: PDK=$PDK PDK_ROOT=$PDK_ROOT ($(python --version))"
