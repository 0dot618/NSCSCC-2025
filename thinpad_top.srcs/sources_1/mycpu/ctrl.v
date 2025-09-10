`include "defines.v"

module ctrl (
    input wire clk,
    input wire rst,
    input wire icache_stallreq,
    input wire baseram_stallreq,
    input wire id_stallreq,
    input wire ex_stallreq,
    input wire mem_stallreq,

    output reg [0:5] stallreq
);

	always @ (*) begin
		if(rst) begin
			stallreq <= 6'b000000;
		end else if(mem_stallreq == `Stop) begin
			stallreq <= 6'b111110;
		end else if(ex_stallreq == `Stop) begin
			stallreq <= 6'b111100;			
		end else if(id_stallreq | baseram_stallreq | icache_stallreq == `Stop) begin
			stallreq <= 6'b111000;			
		end else begin
			stallreq <= 6'b000000;
		end
	end

endmodule