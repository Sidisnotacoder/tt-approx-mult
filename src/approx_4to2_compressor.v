// Approximate 4:2 compressor (AND-OR-recoded carry, MSB-XOR-simplified sum),
// per research/approximate_4to2_compressor_notes.md. cout is kept exact
// (reuses the same two-FA chain as exact_4to2_compressor) to bound
// worst-case error magnitude, matching the base-paper family's practice.
//
// Truth-table deltas vs. exact_4to2_compressor (over all 32 combinations of
// x1,x2,x3,x4,cin):
//   sum:   forced to 0 whenever (x1^x2)==0, instead of computing
//          x1^x2^x3^x4^cin -- cuts the XOR depth from 3 to 1 at the cost of
//          sum errors concentrated in that half of the input space.
//   carry: replaced by a 2:1 mux on (x1^x2) selecting (x3&x4) vs (x3|x4),
//          instead of majority(x1,x2,x3) -- removes one majority gate,
//          errors occur whenever the mux result disagrees with maj(x1,x2,x3).
//   cout:  unchanged (exact).
module approx_4to2_compressor(
    input  wire x1,
    input  wire x2,
    input  wire x3,
    input  wire x4,
    input  wire cin,
    output wire sum,
    output wire carry,
    output wire cout
);
    wire sel;
    wire s1, c1;

    assign sel = x1 ^ x2;

    // Approximate carry: AND/OR-recoded mux instead of maj(x1,x2,x3).
    assign carry = sel ? (x3 & x4) : (x3 | x4);

    // Approximate sum: simplified toward a constant 0 when sel==0.
    assign sum = sel ? (x3 ^ x4 ^ cin) : 1'b0;

    // cout kept exact.
    full_adder u_fa1(.a(x1), .b(x2), .cin(x3), .sum(s1), .cout(c1));
    full_adder u_fa2(.a(s1), .b(x4), .cin(cin), .sum(), .cout(cout));
endmodule
