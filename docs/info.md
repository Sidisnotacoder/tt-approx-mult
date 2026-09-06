<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This chip is an 8x8 -> 16-bit multiplier with two selectable compute cores sharing the same silicon:

- An **exact** Dadda-tree multiplier (structural partial-product reduction built from half adders, full
  adders, and exact 4:2 compressor cells).
- An **approximate** multiplier that is structurally identical except that the 6 least-significant reduction
  columns (of 15) use a custom approximate 4:2 compressor instead: its carry output is a 2:1 mux on
  `x1 XOR x2` selecting `x3 AND x4` vs. `x3 OR x4` (instead of exact majority logic), and its sum output is
  forced to 0 whenever `x1 XOR x2` is 0, instead of computing the full 5-input XOR. This trades a bounded,
  measured accuracy loss (1.7-1.9% mean relative error over an exhaustive 65,536-vector sweep) for less
  reduction logic in those columns -- a demonstration of approximate computing, one of the four project
  directions from this lab's arithmetic-circuit tapeout track.

Because `tt_um` only exposes 8 dedicated input pins but an 8x8 multiply needs 16 input bits (plus a
mode-select bit to choose exact vs. approximate), the design uses a free-running 4-phase load/compute/output
protocol driven purely by `clk` (no extra strobe pin needed):

1. **Phase 0 (LOAD_A)**: `ui_in` is latched as operand A. `uio_in[0]` is latched as the mode-select bit
   (0 = exact, 1 = approximate) -- this bit rides in "for free" here because operand B isn't being loaded
   yet, so `uio_in` isn't needed for data during this phase.
2. **Phase 1 (LOAD_B)**: `ui_in` is latched as operand B.
3. **Phase 2 (COMPUTE)**: the selected core's combinational product is registered internally.
4. **Phase 3 (OUTPUT)**: the 16-bit product is driven out, high byte on `uo_out[7:0]`, low byte on
   `uio_out[7:0]` (`uio_oe` is only driven high during this phase; it's an input during phases 0-2).

The phase counter then wraps back to phase 0. One multiplication completes every 4 clock cycles.

## How to test

Drive `ui_in` = operand A and `uio_in[0]` = mode select on one clock edge, `ui_in` = operand B on the next
edge, wait one more cycle for the internal compute register, then read the 16-bit product off
`{uo_out, uio_out}` on the 4th cycle (`uio_oe` reads back as `0xFF` during this phase, confirming the chip is
driving the bidirectional pins). Repeat for the next multiplication. The `test/test.py` cocotb testbench
implements exactly this sequencing: it checks the exact-mode result is bit-exact against `a*b` for directed
corner cases plus ~200 random vectors, and reports the measured mean relative error for the approximate mode
over ~500 random vectors (expected to land in the low single-digit percent range).

## External hardware

None -- this project only needs the standard TinyTapeout PMOD/QSPI test harness to drive `ui_in`/`uio_in`
and observe `uo_out`/`uio_out`.
