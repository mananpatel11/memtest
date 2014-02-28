`timescale 1ns/1ps

module ids 
   #(
      parameter DATA_WIDTH = 64,
      parameter CTRL_WIDTH = DATA_WIDTH/8,
      parameter UDP_REG_SRC_WIDTH = 2
   )
   (
      input  [DATA_WIDTH-1:0]             in_data,
      input  [CTRL_WIDTH-1:0]             in_ctrl,
      input                               in_wr,
      output                              in_rdy,

      output  [DATA_WIDTH-1:0]             out_data,
      output  [CTRL_WIDTH-1:0]             out_ctrl,
      output                               out_wr,
      input                                out_rdy,
      
      // --- Register interface
      input                               reg_req_in,
      input                               reg_ack_in,
      input                               reg_rd_wr_L_in,
      input  [`UDP_REG_ADDR_WIDTH-1:0]    reg_addr_in,
      input  [`CPCI_NF2_DATA_WIDTH-1:0]   reg_data_in,
      input  [UDP_REG_SRC_WIDTH-1:0]      reg_src_in,

      output                              reg_req_out,
      output                              reg_ack_out,
      output                              reg_rd_wr_L_out,
      output  [`UDP_REG_ADDR_WIDTH-1:0]   reg_addr_out,
      output  [`CPCI_NF2_DATA_WIDTH-1:0]  reg_data_out,
      output  [UDP_REG_SRC_WIDTH-1:0]     reg_src_out,

      // misc
      input                                reset,
      input                                clk
   );

   // Define the log2 function
   // `LOG2_FUNC

   //------------------------- Signals-------------------------------
   
   wire [DATA_WIDTH-1:0]         in_fifo_data;
   wire [CTRL_WIDTH-1:0]         in_fifo_ctrl;

   wire                          in_fifo_nearly_full;
   wire                          in_fifo_empty;

   reg                           in_fifo_rd_en;
   reg                           out_wr_int;

   // software registers 
   wire [31:0]                   pattern_high;
   wire [31:0]                   pattern_low;
   wire [31:0]                   ids_cmd;
   // hardware registers
   reg [31:0]                    matches;
	reg [31:0]                    step_count;

   // internal state
   reg [1:0]                     state, state_next;
   reg [2:0]                     header_counter, header_counter_next;
   reg [63:0]					 out_data_next, out_ctrl_next;
   // local parameter
   parameter                     START = 2'b00;
   parameter                     HEADER = 2'b01;
   parameter                     PAYLOAD = 2'b10;

 
   //------------------------- Local assignments -------------------------------

   assign in_rdy     = out_rdy;
   assign out_wr     = in_wr;
   assign out_data   = in_data;
   assign out_ctrl   = in_ctrl;
	
	
	wire wire1;
      
   //------------------------- Modules-------------------------------
	
	// ids_cmd[0] = reset;
	// ids_cmd[1] = setup_mem;
	// ids_cmd[7:5] = setpvalue
	// ids_cmd[31:22] = address to mem
	debugger db (
	.debug_en					(ids_cmd[3]),
	.stepinto_en				(ids_cmd[4]),
	.stepvalue					(ids_cmd[7:5]),
	.clk_in						(clk),
	.clk_out						(cpu_clk)
	);
	
	unified_memory mem1 (
	.clka							(clk),
	.dina							({pattern_high, pattern_low}),
	.addra						(ids_cmd[31:22]),
	.wea							(ids_cmd[1]),
	.douta						(matches_next),
	.clkb							(clk),
	.dinb							({pattern_high, pattern_low}),
	.addrb						(ids_cmd[31:22]),
	.web							(0),
	.doutb						(wire1)
	);
	
	
	

   generic_regs
   #( 
      .UDP_REG_SRC_WIDTH   (UDP_REG_SRC_WIDTH),
      .TAG                 (`IDS_BLOCK_ADDR),          // Tag -- eg. MODULE_TAG
      .REG_ADDR_WIDTH      (`IDS_REG_ADDR_WIDTH),     // Width of block addresses -- eg. MODULE_REG_ADDR_WIDTH
      .NUM_COUNTERS        (0),                 // Number of counters
      .NUM_SOFTWARE_REGS   (3),                 // Number of sw regs
      .NUM_HARDWARE_REGS   (2)                  // Number of hw regs
   ) module_regs (
      .reg_req_in       (reg_req_in),
      .reg_ack_in       (reg_ack_in),
      .reg_rd_wr_L_in   (reg_rd_wr_L_in),
      .reg_addr_in      (reg_addr_in),
      .reg_data_in      (reg_data_in),
      .reg_src_in       (reg_src_in),

      .reg_req_out      (reg_req_out),
      .reg_ack_out      (reg_ack_out),
      .reg_rd_wr_L_out  (reg_rd_wr_L_out),
      .reg_addr_out     (reg_addr_out),
      .reg_data_out     (reg_data_out),
      .reg_src_out      (reg_src_out),

      // --- counters interface
      .counter_updates  (),
      .counter_decrement(),

      // --- SW regs interface
      .software_regs    ({ids_cmd,pattern_low,pattern_high}),

      // --- HW regs interface
      .hardware_regs    ({matches, step_count}),

      .clk              (clk),
      .reset            (reset)
    );

always @(posedge clk) begin
	if (reset) begin
		matches <= 0;
		step_count <=0;
	end // if(reset)
	else begin
		if (ids_cmd[0]) begin
			matches <= 0;
			end
      else begin
			matches <= matches_next;
			end
		end // if (!reset)
end

always @(posedge cpu_clk) begin		
	if (ids_cmd[0])begin
		step_count <= 0;
	end 
	else begin
		step_count <= step_count + 1;
	end
end



endmodule 
