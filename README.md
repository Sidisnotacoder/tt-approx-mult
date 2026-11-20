![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Approximate vs. Exact 8x8 Multiplier

A Tiny Tapeout (Sky130, single 1x1 tile) chip that puts two 8x8 → 16-bit Dadda
multipliers side by side: one **exact**, one **approximate**. A mode bit picks
which one computes each product, so the same silicon shows the accuracy vs.
area/speed/power trade-off of approximate computing.

- Datasheet, pinout and test procedure: [docs/info.md](docs/info.md)
- Local environment: [SETUP.md](SETUP.md)

## Architecture

| Core | Partial-product reduction | Final adder |
|---|---|---|
| Exact (`dadda_multiplier_8x8_true4to2`) | Dadda tree with true 4:2 compressors. Each `cin` takes a real 5th same-weight bit, so nothing constant-folds away. | Kogge-Stone parallel-prefix |
| Approximate (`dadda_multiplier_8x8_approx_p2_t10_loa`) | Same tree, but the 10 least-significant of 15 columns use a 2-output approximate compressor: `sum = (x1^x2) \| (x3^x4)`, `carry = (x1&x2) \| (x3&x4)`, no `cout` | Kogge-Stone, with a Lower-part-OR Adder on the low bits |

| File | Role |
|---|---|
| `src/project.v` | Top level `tt_um_sidisnotacoder_approx_mult`: 4-phase load/compute/output sequencer, mode mux |
| `src/dadda_multiplier_8x8_true4to2.v` | Exact multiplier core |
| `src/dadda_multiplier_8x8_approx_p2_t10_loa.v` | Approximate multiplier core |
| `src/exact_4to2_compressor.v` | Exact 4:2 compressor cell |
| `src/approx_4to2_compressor_p2.v` | 2-output approximate compressor cell |
| `src/full_adder.v`, `src/half_adder.v` | Basic cells |

### Measured results (approximate vs. exact core)

| Metric | Result |
|---|---|
| Mean relative error (exhaustive, 65,536 vectors) | 5.27 % |
| Area (sky130_fd_sc_hd) | ~31 % smaller |
| Minimum clock period | ~27 % faster |
| Power (activity-based) | ~20 % lower |

## Pin protocol

Only 8 dedicated inputs exist, but a multiply needs 16 operand bits plus a mode
bit. A free-running 2-bit phase counter (reset to 0) sequences each operation,
so one product comes out every 4 clocks:

| Phase | Name | Action |
|---|---|---|
| 0 | LOAD_A | `ui_in` → A, `uio_in[0]` → mode (0 = exact, 1 = approximate) |
| 1 | LOAD_B | `ui_in` → B |
| 2 | COMPUTE | Selected core's product is registered |
| 3 | OUTPUT | `uo_out` = product[15:8], `uio_out` = product[7:0], `uio_oe` = 0xFF |

The chip drives every `uio` pin in phase 3, so the host must release `uio[0]`
after phase 0.

## Verification

| What | How | Result |
|---|---|---|
| Exact mode | cocotb (`cd test && make`): 8 corner cases + 200 random vectors | bit-exact |
| Approximate mode | cocotb: 500 random vectors, MRE checked in a 3–7 % band | pass |
| Gate level | same tests on the hardened netlist (`make GATES=yes`) | pass |
| Physical | LibreLane flow via `tt_tool.py --harden`: DRC, LVS, timing at 50 MHz | clean |

## Build and test locally

```bash
source env.sh
cd test && make -B                # RTL simulation
cd .. && ./tt/tt_tool.py --create-user-config && ./tt/tt_tool.py --harden
./tt/tt_tool.py --print-stats
cp runs/wokwi/final/pnl/tt_um_*.pnl.v test/gate_level_netlist.v
cd test && make -B GATES=yes      # gate-level simulation
```

## Repository layout

```
src/    RTL + LibreLane config      test/   cocotb testbench
docs/   datasheet (info.md)         info.yaml  Tiny Tapeout project metadata
```

## Authors and credits

- Siddharth Senthil Kumar, Department of Electronics and Communication Engineering
- Shiven Singh, Department of Electronics and Telecommunication Engineering
- Guided by Shylashree N

RV College of Engineering (RVCE), Bengaluru.

We gratefully acknowledge the Center of Excellence (CoE) in Integrated Circuits and Systems (ICAS) and the Department of Electronics and Communication Engineering (ECE) for providing the necessary resources and guidance.

Special thanks to Dr. H V Ravish Aradhya (HoD - ECE), Dr. K R Usha Rani (Associate Dean - PG), Dr. K. S. Geetha (Vice Principal) and Dr. K. N. Subramanya (Principal) for their constant encouragement and support in facilitating this Tiny Tapeout SKY26E submission.

## About Tiny Tapeout

[Tiny Tapeout](https://tinytapeout.com) is an educational project that makes it
easier and cheaper than ever to get digital and analog designs manufactured on a
real chip.
