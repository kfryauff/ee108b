//=============================================================================
// EE108B Lab 2
//
// Instruction fetch module. Maintains PC and updates it. Reads from the
// instruction ROM.
//=============================================================================

module instruction_fetch (
    input clk,
    input memclk,
    input rst,
    input en,
    input [31:0] jr_pc,
    input jump_branch,
    input jump_target,
    input jump_reg,
    input [31:0] pc_id,
    input [25:0] target_id,
    input trap,
    input [31:0] trap_pc,
     
    output [31:0] pc,
    output [31:0] instr
);


    wire [31:0] pc_id_p4 = pc_id + 3'h4;
    wire [31:0] b_addr = pc_id_p4 + {{14{target_id[15]}}, target_id[15:0], 2'b0};
    wire [31:0] j_addr = {pc_id_p4[31:28], target_id, 2'b0};

    reg [31:0] pc_next;

    always @* begin
        if (jump_branch)
            pc_next = b_addr;
        else if (jump_target)
            pc_next = j_addr;
        else if (jump_reg)
            pc_next = jr_pc;
        else if (trap)
            pc_next = trap_pc;
        else
            pc_next = pc + 3'h4;
    end

    dffare #(32) pc_reg (.clk(clk), .r(rst), .en(en), .d(pc_next), .q(pc));

    irom instr_rom (
        .clk    (memclk),
        .addr   (pc[10:2]),
        .dout   (instr)
    );

endmodule 
