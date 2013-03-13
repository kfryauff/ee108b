//=============================================================================
// EE108B
//
// MIPS Memory Module
//=============================================================================

`include "mips_defines.v"

module memory_top (
    input clk,
    input mem_we,
    input [31:0] address,
    input [31:0] mem_write_data,
    input [31:0] controller_data,
    
    output wire [31:0] mem_out,
    output wire display_we,
    output wire [13:0] display_data
);

    wire [31:0] mem_read_data; // data read from dram

    wire isDisplayAddr = address == `DISPLAY_ADDR;
    wire isControllerAddr = address == `CONTROLLER_ADDR;

    wire [`MEM_DEPTH-1:0] mem_word_addr = address[`MEM_DEPTH+1:2];
    wire we = mem_we & (address != `DISPLAY_ADDR);
    dataram dmem (.clk(clk), .addr(mem_word_addr), .din(mem_write_data), .dout(mem_read_data), .we(we));

    assign mem_out = isControllerAddr ? controller_data : mem_read_data;

    assign display_we = isDisplayAddr & mem_we;
    assign display_data = {mem_write_data[18:16], mem_write_data[13:8], mem_write_data[4:0]};

endmodule
