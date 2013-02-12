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
    //**branch_en, jump_en, jump_reg_en changed from wires to registers
    output reg branch_en,             // high when the instruction is a taken branch
    output reg jump_en,              // high when the instruction is j or jal
    output reg jump_reg_en,          // high when the instruction is jr or jalr
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

    always @* begin
        casex(op)
            `BEQ:	begin
				if (alu_result == 32'b0)
					branch_en = 1'b1;
			end
            `BNE:	begin
				if (alu_result != 32'b0)
					branch_en = 1'b1;
			end
	    `BLEZ:	begin
				if (alu_result <= 32'b0)
					branch_en = 1'b1;
			end
	    `BGTZ:	begin
				if (alu_result > 32'b0)
					branch_en = 1'b1;
			end
	    `BLTZ_GEZ:	begin		// BLTZ, BGEZ, BLTZAL, BGEZAL - these are dependent on $rt
				if (rt_addr == `BLTZ || rt_addr == `BLTZAL) begin
					if (alu_result < 32'b0)
						branch_en = 1'b1;
				end
				if (rt_addr == `BGEZ || rt_addr == `BGEZAL) begin
					if (alu_result >= 32'b0)
						branch_en = 1'b1;
				end
			end
            default:    branch_en = 1'b0;
    	endcase
    end

    //assign branch_en = 1'b0;

//******************************************************************************
// jump instructions decode
//******************************************************************************

    // TODO: check whether there is a jump or a jump to register and assert
    // jump_en or jump_reg_en high if necessary. Both j and jal should assert
    // jump_en, and both jr and jalr should assert jump_reg_en.
    always @* begin
        casex({op, funct})
	    {`J, `DC6}:		jump_en = 1'b1;
            {`J, `JR}:		jump_reg_en = 1'b1;
            {`JAL, `DC6}:	jump_en = 1'b1;
            {`JAL, `JALR}:	jump_reg_en = 1'b1;
            default:    	begin
					jump_en = 1'b0;
    					jump_reg_en = 1'b0;
				end
    	endcase
    end

    //assign jump_en = 1'b0;
    //assign jump_reg_en = 1'b0;

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
        casex({op, funct})					// go in order; the ones without comments are original
            {`SPECIAL, `ADD}:	alu_opcode = `ALU_ADD;		// ADD
            {`SPECIAL, `ADDU}:	alu_opcode = `ALU_ADDU;		// ADDU
            {`ADDI, `ADD}:	alu_opcode = `ALU_ADD;		// ADDI
            {`ADDIU, `ADDU}:	alu_opcode = `ALU_ADDU;		// ADDIU
            {`SPECIAL, `SUB}:	alu_opcode = `ALU_SUB;		// SUB
            {`SPECIAL, `SUBU}:	alu_opcode = `ALU_SUBU;		// SUBU
            {`SPECIAL, `SLT}:	alu_opcode = `ALU_SLT;		// SLT
            {`SPECIAL, `SLTU}:	alu_opcode = `ALU_SLTU;		// SLTU
            {`SLTI, `SLT}:	alu_opcode = `ALU_SLT;		// SLTI
            {`SLTIU, `SLTU}:	alu_opcode = `ALU_SLTU;		// SLTIU
            {`SPECIAL, `AND}:	alu_opcode = `ALU_AND;		// AND
            {`ANDI, `AND}:	alu_opcode = `ALU_AND;		// ANDI
            {`SPECIAL, `OR}:	alu_opcode = `ALU_OR;		// OR
            {`ORI, `DC6}:       alu_opcode = `ALU_OR;
            {`SPECIAL, `XOR}:	alu_opcode = `ALU_XOR;		// XOR
            {`XORI, `XOR}:	alu_opcode = `ALU_XOR;		// XORI
            {`SPECIAL, `NOR}:	alu_opcode = `ALU_NOR;		// NOR
            {`SPECIAL, `SRL}:	alu_opcode = `ALU_SRL;		// SRL
            {`SPECIAL, `SRA}:	alu_opcode = `ALU_SRA;		// SRA
            {`SPECIAL, `SLL}:   alu_opcode = `ALU_SLL;
            {`SPECIAL, `SRLV}:	alu_opcode = `ALU_SRL;		// SRLV
            {`SPECIAL, `SRAV}:	alu_opcode = `ALU_SRA;		// SRAV
            {`SPECIAL, `SLLV}:	alu_opcode = `ALU_SLL;		// SLLV
            {`LUI, `DC6}:	alu_opcode = `ALU_SLL;	        // LUI
            {`LW, `DC6}:	alu_opcode = `ALU_ADD;		// LW
            {`SW, `DC6}:        alu_opcode = `ALU_ADD;
            {`BEQ, `DC6}:	alu_opcode = `ALU_SUB;		// BEQ
            {`BNE, `DC6}:	alu_opcode = `ALU_SUB;		// BNE
	    {`BLEZ, `DC6}:	alu_opcode = `ALU_SUB;		// BLEZ
	    {`BGTZ, `DC6}:	alu_opcode = `ALU_SUB;		// BGTZ
	    {`BLTZ_GEZ, `DC6}:	alu_opcode = `ALU_SUB;		// BLTZ, BGEZ - these are dependent on $rt
            {`J, `DC6}:		alu_opcode = `ALU_PASSX;	// J
            {`J, `JR}:		alu_opcode = `ALU_PASSX;	// JR
            {`JAL, `DC6}:	alu_opcode = `ALU_PASSX;	// JAL
            {`JAL, `JALR}:	alu_opcode = `ALU_PASSX;	// JALR
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
        if (op == `ORI || op == `ANDI || op == `XORI)	
	// only zero-extended immediates
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
    assign alu_op_x = (op == `LUI) ? 32'd16 : (isShift ? shift_amount : rs_data);
    

    wire use_imm_operand = &{op != `SPECIAL, op != `BNE, op != `BEQ, op != `BLEZ, op != `BGTZ, op != `BLTZ_GEZ};

    assign alu_op_y = use_imm_operand ? imm_ext : rt_data;
    assign reg_write_addr = use_imm_operand ? rt_addr : rd_addr;
    
    // TODO: assert this signal high when the instruction writes to a register
    // Of the three instructions the starter code supports, only sw doesn't
    // write to a register.

    assign reg_write_en = &{op != `SW, op != `J, op != `BEQ, op != `BNE, op != `BLEZ, op != `BGTZ, op != `BLTZ_GEZ};
  
//******************************************************************************
// Memory control
//******************************************************************************
    assign mem_write_en = op == `SW;    // write to memory
    assign mem_read_en = op == `LW;     // read from memory

endmodule
