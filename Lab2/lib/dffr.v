// dffr: D flip-flop with active high synchronous reset
// Parametrized width; default of 1
module dffr #(parameter WIDTH = 1) (
    input clk,
    input r,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    always @ (posedge clk) 
        if (r) 
            q <= {WIDTH{1'b0}};
        else
            q <= d;

endmodule
