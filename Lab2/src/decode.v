//=============================================================================
// EE108B Lab 2
//
// Decode module. Determines what to do with an instruction.
//=============================================================================

`include "mips_defines.v"

module decode (
    input [31:0] pc,
    input [31:0] instr,
    input [31:0] alu_result,
    input [31:0] rs_data,
    input [31:0] rt_data,

    output wire [4:0] reg_write_addr, // destination register number
    output wire branch_en,            // high when the instruction is a taken branch
    output wire jump_en,              // high when the instruction is j or jal
    output wire jump_reg_en,          // high when the instruction is jr or jalr
    output reg [3:0] alu_opcode,      // see mips_defines.v, chooses the function of the ALU
    output wire [31:0] alu_op_x,      // first operand for ALU
    output wire [31:0] alu_op_y,      // second operand for ALU
    output wire mem_write_en,         // high when the instruction is sw
    output wire mem_read_en,          // high when the instruction is lw
    output wire reg_write_en,         // high when the instruction writes to a register
    output wire [4:0] rs_addr,        // rs register number (already set below)
    output wire [4:0] rt_addr         // rt register number (already set below)
);

//******************************************************************************
// instruction fields
//******************************************************************************

    wire [5:0] op = instr[31:26];
    assign rs_addr = instr[25:21];
    assign rt_addr = instr[20:16];
    wire [4:0] rd_addr = instr[15:11];
    wire [4:0] shamt = instr[10:6];
    wire [5:0] funct = instr[5:0];
    wire [15:0] immediate = instr[15:0];

//******************************************************************************
// branch instructions decode
//******************************************************************************

    // TODO: write logic that decides whether the instruction is a taken branch
    // This should consist of checking whether the instruction is a branch, and
    // checking the appropriate condition for the branch.
    // Remember that the ALU result is an input to the decode module, so you can
    // use it to evaluate the branch condition.

    assign branch_en = 1'b0;

//******************************************************************************
// jump instructions decode
//******************************************************************************

    // TODO: check whether there is a jump or a jump to register and assert
    // jump_en or jump_reg_en high if necessary. Both j and jal should assert
    // jump_en, and both jr and jalr should assert jump_reg_en.

    assign jump_en = 1'b0;
    assign jump_reg_en = 1'b0;

//******************************************************************************
// shift instruction decode
//******************************************************************************

    wire isSLL = (op == `SPECIAL) & (funct == `SLL);
    wire isSRA = (op == `SPECIAL) & (funct == `SRA);
    wire isSRL = (op == `SPECIAL) & (funct == `SRL);
    wire isSLLV = (op == `SPECIAL) & (funct == `SLLV);
    wire isSRAV = (op == `SPECIAL) & (funct == `SRAV);
    wire isSRLV = (op == `SPECIAL) & (funct == `SRLV);
    
    wire isVarShift = isSLLV | isSRAV | isSRLV;
    wire isShift = isSLL | isSRA | isSRL | isVarShift;

//******************************************************************************
// ALU instructions decode / control signal for ALU datapath
//******************************************************************************
    
    // TODO: enumerate the remaining {op, funct} pairs and the corresponding
    // alu operations. Refer to include/mips_defines.v

    always @* begin
        casex({op, funct})
            {`ORI, `DC6}:       alu_opcode = `ALU_OR;
            {`SW, `DC6}:        alu_opcode = `ALU_ADD;
            {`SPECIAL, `SLL}:   alu_opcode = `ALU_SLL;
            default:            alu_opcode = `ALU_PASSX;
    	endcase
    end

//******************************************************************************
// Compute value for 32 bit immediate data
//******************************************************************************

    // TODO: set imm_ext to the appropriate value based on the type of
    // instruction. ORI is covered for you.

    wire [31:0] imm_sign_extend = {{16{immediate[15]}}, immediate};  
    wire [31:0] imm_zero_extend = {16'b0, immediate};	

    reg [31:0] imm_ext;
    always @* begin
        if (op == `ORI)
            imm_ext = imm_zero_extend;
        else
            imm_ext = imm_sign_extend;
    end

//******************************************************************************
// Determine ALU inputs and register writeback address
//******************************************************************************


    // TODO: set alu_op_x and alu_op_y based on the kind of operation that
    // must be performed (and your implementation of the ALU)

    // for shift operations, use either shamt field or lower 5 bits of rs
    // otherwise use rs

    wire [31:0] shift_amount = {27'b0, isVarShift ? rs_data[4:0] : shamt};
    assign alu_op_x = isShift ? shift_amount : rs_data;

    wire use_imm_operand = &{op != `SPECIAL, op != `BNE, op != `BEQ};

    assign alu_op_y = use_imm_operand ? imm_ext : rt_data;
    assign reg_write_addr = use_imm_operand ? rt_addr : rd_addr;
    
    // TODO: assert this signal high when the instruction writes to a register
    // Of the three instructions the starter code supports, only sw doesn't
    // write to a register.
    assign reg_write_en = &{op != `SW, op != `BEQ, op != `BNE, op != `BLEZ, op != `BGTZ, op != `BLTZ_GEZ, op != `J, op != `JAL};
  
//******************************************************************************
// Memory control
//******************************************************************************
    assign mem_write_en = op == `SW;    // write to memory
    assign mem_read_en = op == `LW;     // read from memory

endmodule
