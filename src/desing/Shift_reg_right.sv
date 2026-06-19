module shift_reg_right #(
    parameter int WIDTH = 64
)(
    input  logic               clk,
    input  logic               rst_n,
    input  logic                load,
    input  logic                shift_en,
    input  logic [WIDTH-1:0]    load_val,
    output logic [WIDTH-1:0]    q
);
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= '0;
        end else if (load) begin
            q <= load_val;
        end else if (shift_en) begin
            q <= q >> 1;
        end
    end
 
endmodule
