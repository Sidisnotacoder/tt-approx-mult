# SPDX-FileCopyrightText: © 2026 Sid
# SPDX-License-Identifier: Apache-2.0

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# CLOCK_PERIOD in src/config.json is 20ns (50MHz) -- match it here.
CLK_PERIOD_NS = 20


async def multiply(dut, a, b, mode):
    """Drive the 4-phase load/compute/output protocol and return the 16-bit
    product. `mode` = 0 for exact, 1 for approximate."""
    # Phase 0 (LOAD_A): present A and the mode bit.
    dut.ui_in.value = a
    dut.uio_in.value = mode & 0x1
    await ClockCycles(dut.clk, 1)

    # Phase 1 (LOAD_B): present B.
    dut.ui_in.value = b
    await ClockCycles(dut.clk, 1)

    # Phase 2 (COMPUTE).
    await ClockCycles(dut.clk, 1)

    # Phase 3 (OUTPUT): result is now valid and uio_oe should read 0xFF.
    await ClockCycles(dut.clk, 1)
    assert dut.uio_oe.value == 0xFF, f"expected uio_oe=0xFF in OUTPUT phase, got {dut.uio_oe.value}"

    hi = int(dut.uo_out.value)
    lo = int(dut.uio_out.value)
    return (hi << 8) | lo


async def reset(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    # Do NOT await a clock edge here: `phase` is held at LOAD_A (0) through
    # reset, and the first post-reset posedge is the LOAD_A edge -- the
    # caller (multiply()) must set ui_in/uio_in before that edge, which the
    # very first `await ClockCycles` inside multiply() provides.


@cocotb.test()
async def test_exact_mode(dut):
    dut._log.info("Start exact-mode test")
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    await reset(dut)

    directed = [(0, 0), (255, 255), (1, 255), (255, 1), (0xAA, 0x55), (0x55, 0xAA), (128, 128), (1, 1)]
    for a, b in directed:
        got = await multiply(dut, a, b, mode=0)
        expected = a * b
        assert got == expected, f"exact mode mismatch: {a}*{b} = {expected}, got {got}"

    random.seed(1)
    for _ in range(200):
        a = random.randint(0, 255)
        b = random.randint(0, 255)
        got = await multiply(dut, a, b, mode=0)
        expected = a * b
        assert got == expected, f"exact mode mismatch: {a}*{b} = {expected}, got {got}"

    dut._log.info("Exact mode: 208/208 vectors bit-exact")


@cocotb.test()
async def test_approx_mode(dut):
    dut._log.info("Start approximate-mode test")
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    await reset(dut)

    random.seed(2)
    n = 500
    total_rel_err = 0.0
    mismatches = 0
    max_rel_err = 0.0
    for _ in range(n):
        a = random.randint(0, 255)
        b = random.randint(0, 255)
        got = await multiply(dut, a, b, mode=1)
        expected = a * b
        if got != expected:
            mismatches += 1
        if expected != 0:
            rel_err = abs(got - expected) / expected
            total_rel_err += rel_err
            max_rel_err = max(max_rel_err, rel_err)

    mre_pct = 100.0 * total_rel_err / n
    dut._log.info(
        f"Approx mode: {mismatches}/{n} mismatches, MRE={mre_pct:.3f}%, "
        f"max_rel_err={100*max_rel_err:.1f}%"
    )
    # Sanity band around Track A's measured 1.871% MRE -- catches a broken
    # wiring/mode-select (which would give ~0% or >10%), not meant to be a
    # tight bound.
    # Exhaustive 65536-vector sweep measures 5.27% MRE for this design
    # (2-output approximate compressor, threshold=10, + Lower-part-OR Adder);
    # a 500-vector random sample should land close to that.
    assert 3.0 <= mre_pct <= 7.0, f"MRE {mre_pct:.3f}% outside expected 3.0-7.0% band"
