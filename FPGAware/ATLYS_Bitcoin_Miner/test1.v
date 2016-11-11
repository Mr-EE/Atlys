`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:28:44 06/29/2014
// Design Name:   top
// Module Name:   E:/Home_Projects/Projects/Ates/FPGAware/ATLYS_Bitcoin_Miner/test1.v
// Project Name:  ATLYS_Bitcoin_Miner
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test1;

	// Inputs
	reg clk_in;
	reg rx;

	// Outputs
	wire tx;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clk_in(clk_in), 
		.tx(tx), 
		.rx(rx)
	);

	initial begin
		// Initialize Inputs
		clk_in = 0;
		rx = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

