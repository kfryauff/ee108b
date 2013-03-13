//=============================================================================
// EE108B Lab 3
//
// MIPS CPU Module. Contains the five stages in the single-cycle MIPS CPU.
//=============================================================================

module mips_cpu (
    input clk,
    input memclk,
    input rst,
    input en,
    input trap,
    input [31:0] controller_data,
    output [13:0] display_data,
    output display_we
);

    wire [31:0] pc_if, pc_id;
    wire [31:0] instr_if, instr_id;
    wire jump_branch_id, jump_target_id, jump_reg_id;
    wire [4:0] rs_addr_id, rt_addr_id;
    wire [31:0] rs_data_id, rt_data_id;
    wire [31:0] mem_write_data_id, mem_write_data_ex, mem_write_data_mem;
    wire [31:0] jr_pc_id;
    wire [4:0] reg_write_addr_id, reg_write_addr_ex, reg_write_addr_mem, reg_write_addr_wb;
    wire [31:0] mem_out;
    wire [31:0] reg_write_data_mem, reg_write_data_wb;
    wire reg_we_id, reg_we_ex, reg_we_mem, reg_we_wb;
    wire [3:0] alu_opcode_id, alu_opcode_ex;
    wire [31:0] alu_op_x_id, alu_op_y_id, alu_op_x_ex, alu_op_y_ex;
    wire [31:0] alu_result_ex, alu_result_mem;
    wire mem_we_id, mem_we_ex, mem_we_mem;
    wire mem_read_id, mem_read_ex, mem_read_mem;
    wire alu_overflow;
    
    wire stall;
    wire en_if = ~stall & en;
    wire rst_id = stall & en;

    instruction_fetch if_stage (
        .clk            (clk),
        .memclk         (memclk),
        .rst            (rst), 
        .en             (en_if),
        .jump_branch    (jump_branch_id),
        .jump_target    (jump_target_id),
        .jump_reg       (jump_reg_id),
        .jr_pc          (jr_pc_id),
        .pc_id          (pc_id),
        .target_id      (instr_id[25:0]),
        .trap           (trap | alu_overflow),
        .trap_pc        (32'd2000),

        .pc             (pc_if),
        .instr          (instr_if)
    );

    // needed for D stage
    dffare #(32) pc_if2id (.clk(clk), .r(rst), .en(en_if), .d(pc_if), .q(pc_id)); 
    dffare #(32) instr_if2id (.clk(clk), .r(rst), .en(en_if), .d(instr_if), .q(instr_id)); 

    decode d_stage (
        // inputs
        .pc                 (pc_id),
        .instr              (instr_id),
        .rs_data_in         (rs_data_id),
        .rt_data_in         (rt_data_id),

        .reg_write_addr     (reg_write_addr_id),
        .jump_branch        (jump_branch_id),
        .jump_target        (jump_target_id),
        .jump_reg           (jump_reg_id),
        .jr_pc              (jr_pc_id),
        .alu_opcode         (alu_opcode_id),
        .alu_op_x           (alu_op_x_id),
        .alu_op_y           (alu_op_y_id),
        .mem_we             (mem_we_id),
        .mem_write_data     (mem_write_data_id),
        .mem_read           (mem_read_id),
        .reg_we             (reg_we_id),
        .rs_addr            (rs_addr_id),
        .rt_addr            (rt_addr_id),
        .stall              (stall),   // Connect additional inputs to the
                                       // decode module to enable forwarding
                                       // and stalling.
                                       // The signals you need have already
                                       // been declared elsewhere in mips_cpu
	// conditions to check for forwarding
    	.reg_we_ex	    (reg_we_ex),
    	.reg_write_addr_ex  (reg_write_addr_ex),	// also used for stalling check
    	.reg_we_mem	    (reg_we_mem),
    	.reg_write_addr_mem (reg_write_addr_mem),
    	// data to forward
    	.alu_result_ex	    (alu_result_ex),
    	.reg_write_data_mem (reg_write_data_mem),

    	// conditions to check for stalls
    	.mem_read_ex	    (mem_read_ex)
    );

    // needed for X stage
    dffarre #(32) alu_op_x_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(alu_op_x_id), .q(alu_op_x_ex));
    dffarre #(32) alu_op_y_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(alu_op_y_id), .q(alu_op_y_ex));
    dffarre #(4) alu_opcode_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(alu_opcode_id), .q(alu_opcode_ex));

    // needed for M stage
    dffarre #(32) mem_write_data_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(mem_write_data_id), .q(mem_write_data_ex));
    dffarre mem_we_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(mem_we_id), .q(mem_we_ex));
    dffarre mem_read_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(mem_read_id), .q(mem_read_ex));

    // needed for W stage
    dffarre #(5) reg_write_addr_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(reg_write_addr_id), .q(reg_write_addr_ex));
    dffarre reg_we_id2ex (.clk(clk), .ar(rst), .r(rst_id), .en(en), .d(reg_we_id), .q(reg_we_ex));

    alu x_stage (
        .alu_opcode     (alu_opcode_ex),
        .alu_op_x       (alu_op_x_ex),
        .alu_op_y       (alu_op_y_ex),

        .alu_result     (alu_result_ex),
        .alu_overflow   (alu_overflow) // maybe do something creative with this
    );

    // needed for M stage
    dffare #(32) alu_result_ex2mem (.clk(clk), .r(rst), .en(en), .d(alu_result_ex), .q(alu_result_mem));
    dffare #(32) mem_write_data_ex2mem (.clk(clk), .r(rst), .en(en), .d(mem_write_data_ex), .q(mem_write_data_mem));
    dffare mem_read_ex2mem (.clk(clk), .r(rst), .en(en), .d(mem_read_ex), .q(mem_read_mem));
    dffare mem_we_ex2mem (.clk(clk), .r(rst), .en(en), .d(mem_we_ex), .q(mem_we_mem));

    // needed for W stage
    dffare #(5) reg_write_addr_ex2mem (.clk(clk), .r(rst), .en(en), .d(reg_write_addr_ex), .q(reg_write_addr_mem));
    dffare reg_we_ex2mem (.clk(clk), .r(rst), .en(en), .d(reg_we_ex), .q(reg_we_mem));

    memory_top m_stage (
        .clk            (memclk),
        .mem_we         (en & mem_we_mem),
        .address        (alu_result_mem), 
        .mem_write_data (mem_write_data_mem),
        .controller_data(controller_data),

        .mem_out        (mem_out),
        .display_we     (display_we),
        .display_data   (display_data)
    );

    assign reg_write_data_mem = mem_read_mem ? mem_out : alu_result_mem;

    // needed for W stage
    dffare #(32) reg_write_data_mem2wb (.clk(clk), .r(rst), .en(en), .d(reg_write_data_mem), .q(reg_write_data_wb));
    dffare #(5) reg_write_addr_mem2wb (.clk(clk), .r(rst), .en(en), .d(reg_write_addr_mem), .q(reg_write_addr_wb));
    dffare reg_we_mem2wb (.clk(clk), .r(rst), .en(en), .d(reg_we_mem), .q(reg_we_wb));

    regfile w_stage (
        .clk            (clk),
        .memclk         (memclk),
        .en             (en),
        .reg_write_data (reg_write_data_wb),
        .reg_write_addr (reg_write_addr_wb),
        .reg_we         (reg_we_wb),
        .rs_addr        (rs_addr_id),
        .rt_addr        (rt_addr_id),

        .rs_data        (rs_data_id),
        .rt_data        (rt_data_id)
    );

endmodule
