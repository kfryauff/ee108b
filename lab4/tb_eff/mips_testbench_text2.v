//******************************************************************************
// EE108B MIPS Verilog model
// Lab 4 Cache Efficiency
// mips_testbench.v
//******************************************************************************

`include "dvi_defines.v"
`include "mips_defines.v"

module mips_testbench();

    wire select;
    wire chip_hsync, chip_vsync, chip_data_enable, chip_reset;
    wire [11:0] chip_data;
    wire scl, sda;
    wire [3:0] leds;
    wire xclk, xclk_n;
    reg [15:0] mem_count, dram_count, cache_count;
   
    
    reg clk, rst, play;
    
    initial clk = 0;
    
    initial begin
       $dumpfile("mipstest.vcd");
       $dumpvars(0, mips_testbench);
       mem_count=0;
       dram_count=0;
       cache_count=0;
       
       
        rst = 0;
        #10;
        rst = 1;
        #10;
        rst = 0; play = 1;
        #10;
        play = 0;
        #500000;
       	$display("Total Reads: %d\nCache Hits: %d\nRemainder: %d",
		 mem_count,
		 cache_count,
		 mem_count-cache_count
		 );
        $stop;
    end

    always begin
        #20
        if (dut.cpu.en) begin
            if (dut.cpu.instr != `NOP) begin
                if (dut.cpu.m_stage.re) begin
		   mem_count=mem_count+1;
		//end
	       //if (dut.cpu.m_stage.data_cache.dram.re &&
	       //dut.cpu.m_stage.data_cache.dram.latency_done) begin
	       if (~dut.cpu.m_stage.data_cache.dram.re) begin
		      cache_count=cache_count+1;
	       end
		end  
	   
            end
                //$display("pc: %d, nop", dut.cpu.pc[10:0]);
        end
    end
    
    always
        #5 clk = ~clk;

    
    mips_top dut (
        .clk(clk),
        .chip_hsync(chip_hsync),
        .chip_vsync(chip_vsync),
        .chip_data(chip_data),
        .chip_reset(chip_reset),
        .chip_data_enable(chip_data_enable),
        .xclk(xclk),
        .xclk_n(xclk_n),
        .sw(8'b0),
        .left_btn(play),
        .center_btn(1'b0),
        .right_btn(1'b0),
        .top_btn(rst),
        .bottom_btn(1'b0),
        .leds(leds),
        .scl(scl),
        .sda(sda)
    );

endmodule
