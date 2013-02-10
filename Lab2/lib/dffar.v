// dffar: D flip-flip with asynchronous reset
// Parametrized width; default of 1
module dffar #(parameter WIDTH = 1) (
    input clk,
    input r,
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    always @(posedge clk or negedge r)
        if (~r)
            q <= {WIDTH{1'b0}};
        else
            q <= d;

endmodule
