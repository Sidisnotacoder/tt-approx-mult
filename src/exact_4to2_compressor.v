// Exact 4:2 compressor built from two cascaded full adders (3:2 compressors).
// x1+x2+x3+x4+cin = sum + 2*(carry+cout)
module exact_4to2_compressor(
    input  wire x1,
    input  wire x2,
    input  wire x3,
    input  wire x4,
    input  wire cin,
    output wire sum,
    output wire carry,
    output wire cout
);
    wire s1, c1;

    full_adder u_fa1(.a(x1), .b(x2), .cin(x3), .sum(s1), .cout(c1));
    full_adder u_fa2(.a(s1), .b(x4), .cin(cin), .sum(sum), .cout(cout));

    assign carry = c1;
endmodule
