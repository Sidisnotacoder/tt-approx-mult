/*
 * Copyright (c) 2026 Sid
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Approximate vs. exact 8x8 multiplier demo.
//
// Only 8 dedicated input pins exist but an 8x8 multiply needs 16 operand
// bits plus a 1-bit exact/approximate mode select, so operands are loaded
// over a free-running 4-phase protocol (no external strobe pin needed --
// phases are implicit, driven purely by clk):
//   phase 0 (LOAD_A):  a_reg <= ui_in; mode_reg <= uio_in[0] (free during
//                       this phase since B isn't being loaded yet).
//   phase 1 (LOAD_B):  b_reg <= ui_in.
//   phase 2 (COMPUTE): p_reg <= mode_reg ? product_approx : product_exact.
//   phase 3 (OUTPUT):  uio_oe driven high; product held on uo_out/uio_out.
// One multiply completes every 4 clock cycles (4-cycle latency).
module tt_um_sidisnotacoder_approx_mult (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  localparam LOAD_A  = 2'd0;
  localparam LOAD_B  = 2'd1;
  localparam COMPUTE = 2'd2;
  localparam OUTPUT  = 2'd3;

  reg [1:0]  phase;
  reg [7:0]  a_reg, b_reg;
  reg        mode_reg;
  reg [15:0] p_reg;

  wire [15:0] product_exact;
  wire [15:0] product_approx;

  dadda_multiplier_8x8_true4to2 u_exact (
      .a(a_reg),
      .b(b_reg),
      .p(product_exact)
  );

  dadda_multiplier_8x8_approx_p2_t10_loa u_approx (
      .a(a_reg),
      .b(b_reg),
      .p(product_approx)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      phase    <= LOAD_A;
      a_reg    <= 8'd0;
      b_reg    <= 8'd0;
      mode_reg <= 1'b0;
      p_reg    <= 16'd0;
    end else begin
      case (phase)
        LOAD_A: begin
          a_reg    <= ui_in;
          mode_reg <= uio_in[0];
        end
        LOAD_B: begin
          b_reg <= ui_in;
        end
        COMPUTE: begin
          p_reg <= mode_reg ? product_approx : product_exact;
        end
        default: begin
          // OUTPUT: nothing to latch, just hold p_reg.
        end
      endcase
      phase <= phase + 2'd1;
    end
  end

  assign uo_out  = p_reg[15:8];
  assign uio_out = p_reg[7:0];
  assign uio_oe  = (phase == OUTPUT) ? 8'hFF : 8'h00;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
