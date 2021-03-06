`include "mips_defines.v"

module dataram (addr, clk, din, dout, we);

input [`MEM_DEPTH-1:0] addr;
input clk;
input [31:0] din;
input we;
output reg [31:0] dout;

    reg [31:0] mem [2**`MEM_DEPTH-1:0];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        dout <= mem[addr];
    end
    
endmodule
