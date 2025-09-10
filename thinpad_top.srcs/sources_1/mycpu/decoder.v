// Ó²¼ş½âÂëÆ÷Ä£¿é
module decoder_6_64(
    input  wire [5:0] in,
    output wire [63:0] out
);
    assign out = 64'b1 << in;
endmodule

module decoder_5_32(
    input  wire [4:0] in,
    output wire [31:0] out
);
    assign out = 32'b1 << in;
endmodule