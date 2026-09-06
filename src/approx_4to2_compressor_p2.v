// 2-output approximate compressor: sum + one carry only (no cin, no cout).
// Dropping the third output (cout) is the structural change that lets this
// cell change the reduction tree's column-height ratio per stage, unlike the
// existing 3-output approx_4to2_compressor which has the same arity as the
// exact cell and therefore cannot change the tree's shape, only its per-cell
// cost. See research/approximate_4to2_compressor_notes.md for the Phase 2
// rationale.
//
// sum   = (x1^x2) | (x3^x4)
// carry = (x1&x2) | (x3&x4)
//
// Truth table vs. the exact 4-input population count (x1+x2+x3+x4, range
// 0..4, truncated here to what a 2-bit {carry,sum} output can represent,
// i.e. compared against the exact count mod 4 with any overflow beyond 3
// being unrepresentable by either the exact 4:2 cell's 2-bit {carry,sum} or
// this cell -- the exact cell handles counts of 4 via its extra cout bit,
// this cell cannot):
//
//  x4 x3 x2 x1 | exact count | exact {carry,sum} (count truncated to 2b) | this cell {carry,sum} | match?
//   0  0  0  0 |      0      |        00                                  |         00            |  yes
//   0  0  0  1 |      1      |        01                                  |         01            |  yes
//   0  0  1  0 |      1      |        01                                  |         01            |  yes
//   0  0  1  1 |      2      |        10                                  |         01            |  NO (carry dropped: x1&x2=1 but x3=x4=0 so this-cell carry=0)
//   0  1  0  0 |      1      |        01                                  |         01            |  yes
//   0  1  0  1 |      2      |        10                                  |         11            |  NO
//   0  1  1  0 |      2      |        10                                  |         11            |  NO
//   0  1  1  1 |      3      |        11                                  |         11            |  yes
//   1  0  0  0 |      1      |        01                                  |         01            |  yes
//   1  0  0  1 |      2      |        10                                  |         11            |  NO
//   1  0  1  0 |      2      |        10                                  |         11            |  NO
//   1  0  1  1 |      3      |        11                                  |         11            |  yes
//   1  1  0  0 |      2      |        10                                  |         01            |  NO (symmetric to the 0011 case)
//   1  1  0  1 |      3      |        11                                  |         11            |  yes
//   1  1  1  0 |      3      |        11                                  |         11            |  yes
//   1  1  1  1 |      4      |        00 (cout=1, dropped here)           |         11            |  NO
//
// 9/16 exact, 7/16 erroneous (all off-by-one-count errors except the all-1s
// case, which this cell reports as 3 instead of 4 since it has no cout to
// carry the extra weight). Mean absolute count error over all 16 combos:
// 6/16 = 0.375 counts, vs. the original 3-output approx_4to2_compressor's
// reported 1.0 LSB mean absolute error at the cell level (see Phase 1 notes)
// -- this cell is both cheaper (2 gates for sum, 2 for carry vs. the
// AND/OR-mux+XOR-gated structure of the 3-output cell) and more accurate
// per-cell, while additionally changing the tree's reduction ratio (the
// real source of structural savings -- see Phase 2 notes).
module approx_4to2_compressor_p2(
    input  wire x1,
    input  wire x2,
    input  wire x3,
    input  wire x4,
    output wire sum,
    output wire carry
);
    assign sum   = (x1 ^ x2) | (x3 ^ x4);
    assign carry = (x1 & x2) | (x3 & x4);
endmodule
