// Approximate 4:2 compressor (AND-OR-recoded carry, MSB-XOR-gated sum,
// reused-term cout), per research/approximate_4to2_compressor_notes.md.
//
// Unlike an earlier revision of this cell, `cout` is NOT computed via a
// full-adder cascade -- that reused the exact cell's entire 2-FA structure
// "just to be safe" and ended up strictly larger than the exact cell (extra
// mux/select gates on top of two full adders). This revision drops the FA
// cascade entirely: every output is a small, shallow function of the raw
// inputs, with `and34`/`or34` shared between `carry` and `cout` so the whole
// cell synthesizes smaller and shallower than exact_4to2_compressor's two
// cascaded full adders.
//
// Truth-table deltas vs. exact_4to2_compressor (over all 32 combinations of
// x1,x2,x3,x4,cin):
//   sum:   0 whenever (x1^x2)==0, else x3^x4^cin -- instead of the exact
//          x1^x2^x3^x4^cin.
//   carry: mux(x1^x2): x3&x4 (sel=1) vs x3|x4 (sel=0) -- instead of the exact
//          majority(x1,x2,x3).
//   cout:  simply x3&x4 -- instead of the exact
//          majority(x1^x2^x3, x4, cin). x1, x2, and cin are dropped from
//          cout's logic entirely; this is the cheapest of the three outputs
//          and reuses a term (`and34`) already computed for `carry`.
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
    wire sel;    // x1 ^ x2 -- selects which half of the input space we're in
    wire and34;  // x3 & x4
    wire or34;   // x3 | x4

    assign sel   = x1 ^ x2;
    assign and34 = x3 & x4;
    assign or34  = x3 | x4;

    // carry = sel ? and34 : or34. Since and34 implies or34, this mux
    // collapses to a single extra gate on top of and34/or34.
    assign carry = or34 & (~sel | and34);

    // sum = sel ? (x3^x4^cin) : 0 -- an AND-gated 3-input XOR.
    assign sum = sel & (x3 ^ x4 ^ cin);

    // cout: reuse and34 instead of a second cascaded full adder.
    assign cout = and34;
endmodule
