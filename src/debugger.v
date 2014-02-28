`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:08:49 02/27/2014 
// Design Name: 
// Module Name:    debugger 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debugger(
	 input debug_en,
    input stepinto_en,
    input [2:0] stepvalue,
    input clk_in,
    output reg clk_out
    );

	reg [2:0] count;
	reg clk_sel;
	always@(*)
	begin
	if (debug_en) begin
		case(clk_sel)
			1'b0: clk_out = 1'b0;
			1'b1: clk_out = clk_in;
		endcase
		end // if (debug_en)
	else begin
		clk_out = clk_in;
		end // else
	end
	
	
	always @(posedge clk_in) begin
		if (0 == stepinto_en) begin
			count <= stepvalue;
		end // (0 == stepinto_en)
		else begin 
			if (0 != count) begin
			count <= count - 1;
			clk_sel <= 1;
			end // if (0 != count)
			else begin
			clk_sel <= 0;
			end //else
		end // else if 0 != stepint_en
	end // always

endmodule
