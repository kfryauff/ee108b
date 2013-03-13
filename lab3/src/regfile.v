//=============================================================================
// EE108B Lab 2
//
// MIPS Register File Module
//=============================================================================

module regfile (
    input clk,
    input memclk,
    input en,
    input [31:0] reg_write_data,
    input [4:0] reg_write_addr,
    input reg_we,
    input [4:0] rs_addr,
    input [4:0] rt_addr,

    output reg [31:0] rs_data,
    output reg [31:0] rt_data
);

    reg [31:0] regs [31:0];

    always @(posedge clk)
        if (reg_we & en)
            regs[reg_write_addr] <= reg_write_data;

    // internally forwarded writes
    // if we write and read the same register in the same cycle, we get
    // the latest data
    always @(posedge memclk) begin

        if (rs_addr == 5'd0)
            rs_data <= 32'd0;
        else if (reg_we & (rs_addr == reg_write_addr))
            rs_data <= reg_write_data;
        else
            rs_data <= regs[rs_addr];

        if (rt_addr == 5'd0)
            rt_data <= 32'd0;
        else if (reg_we & (rt_addr == reg_write_addr))
            rt_data <= reg_write_data;
        else
            rt_data <= regs[rt_addr];

    end

endmodule
