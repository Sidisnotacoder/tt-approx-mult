# Local TinyTapeout environment (macOS, Apple Silicon)

Targets the **ttsky26d** shuttle (Sky130A), matching the official GitHub Actions flow.

## Every session

```bash
source env.sh
```

This activates `.venv`, sets `PDK_ROOT=~/.ciel` / `PDK=sky130A`, and starts the Colima Docker VM if needed.

## What's installed

| Tool | Source | Purpose |
|---|---|---|
| Icarus Verilog, Verilator, Yosys | Homebrew | RTL sim, lint, synthesis |
| Surfer | Homebrew | Waveform viewer (`surfer test/tb.fst`) |
| Docker CLI + Colima (6 CPU / 10 GB) | Homebrew | Runs LibreLane's container (OpenROAD, Magic, KLayout, Netgen) |
| Python 3.11 venv (`.venv`) | Homebrew | Same Python version as TT CI |
| LibreLane 3.0.14, cocotb 2.1.0, pytest, klayout (py), tt-support-tools deps | pip | Flow, tests, precheck |
| tt-support-tools | `tt/` (git clone) | `tt_tool.py` |
| Sky130A PDK | ciel, in `~/.ciel` | Fetched automatically by LibreLane |

## Common commands

```bash
# RTL simulation (cocotb)
cd test && make -B

# Harden to GDS locally (same as the CI "gds" job)
./tt/tt_tool.py --create-user-config
./tt/tt_tool.py --harden
./tt/tt_tool.py --print-stats
./tt/tt_tool.py --print-cell-category

# Gate-level simulation after hardening
cp runs/wokwi/final/pnl/tt_um_*.pnl.v test/gate_level_netlist.v
cd test && make -B GATES=yes

# View the layout in KLayout (inside the LibreLane container)
./tt/tt_tool.py --open-in-klayout
```

## Notes

- The project must stay under your home folder. Colima only shares `$HOME` with the LibreLane container.
- Sky130A is enabled in `~/.ciel` at version `8afc8346…`, the version LibreLane 3.0.14 uses. It's needed for `make GATES=yes`.

- The KLayout GUI cask is currently disabled in Homebrew (Gatekeeper), so the desktop app isn't installed. Use `--open-in-klayout` above, or download it yourself from klayout.de.
- `tt/`, `.venv/`, and `runs/` are git-ignored. On a fresh clone, create the venv (Python 3.11, `pip install librelane==3.0.14 cocotb==2.1.0 pytest klayout -r tt/requirements.txt`) and re-run:
  `git clone https://github.com/TinyTapeout/tt-support-tools tt`
- Colima keeps running in the background; `colima stop` frees its RAM.
