//=============================================================================
// EE108B Lab 2
//
// MIPS CPU Module. Contains the five stages in the single-cycle MIPS CPU.
//=============================================================================

`include "mips_defines.v"

module alu (
    input [3:0] alu_opcode,
    input [31:0] alu_op_x,
    input [31:0] alu_op_y,
    output reg [31:0] alu_result,
    output wire alu_overflow
);

//******************************************************************************
// Shift operation: ">>>" will perform an arithmetic shift, but the operand
// must be reg signed, also useful for signed vs. unsigned comparison.
//******************************************************************************
    wire signed [31:0] alu_op_x_signed = alu_op_x;
    wire signed [31:0] alu_op_y_signed = alu_op_y;
  
//******************************************************************************
// ALU datapath
//******************************************************************************

    // TODO: fill in the remaining operations based on the ALU opcodes

    always @* begin
        case (alu_opcode)
            // PERFORM ALU OPERATIONS DEFINED ABOVE		// shift operations are Y >> X[4:0]
            `ALU_ADDU:	alu_result = alu_op_x + alu_op_y;	// new - is this same as add?
	    `ALU_AND:	alu_result = alu_op_x & alu_op_y;	// new
	    `ALU_XOR:	alu_result = alu_op_x ^ alu_op_y;	// new
	    `ALU_OR:    alu_result = alu_op_x | alu_op_y;
	    `ALU_NOR:	alu_result = alu_op_x ~| alu_op_y;	// new
	    `ALU_SUBU:	alu_result = alu_op_x - alu_op_y;	// new
	    `ALU_SLTU:	alu_result = (alu_op_x - alu_op_y < 0) ? 1: 0;	// new
	    `ALU_SLT:	alu_result = (alu_op_x - alu_op_y < 0) ? 1: 0;	// new
	    `ALU_SRL:	alu_result = alu_op_y >> alu_op_x[4:0];	// new
	    `ALU_SRA:	alu_result = alu_op_y >>> alu_op_x[4:0];// new
	    `ALU_SLL:   alu_result = alu_op_y << alu_op_x[4:0];
	    `ALU_PASSX: alu_result = alu_op_x;
	    `ALU_PASSY:	alu_result = alu_op_y;			// new
	    `ALU_ADD:   alu_result = alu_op_x + alu_op_y;
	    `ALU_SUB:	alu_result = alu_op_x - alu_op_y;	// new
            default:    alu_result = 32'hxxxxxxxx;              // undefined
        endcase
    end
    
    // TODO: for extra credit, assert this signal high when an add or sub
    // instruction causes an overflow (or underflow)
    assign alu_overflow = 1'b0;

endmodule
