module shift_reg_left #(
    parameter int WIDTH = 32
)(
    input  logic               clk,
    input  logic               rst_n,
    input  logic                load,
    input  logic                shift_en,
    input  logic                serial_in,
    input  logic [WIDTH-1:0]    load_val,
    output logic [WIDTH-1:0]    q
);
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= '0;
        end else if (load) begin
            q <= load_val;
        end else if (shift_en) begin
            q <= {q[WIDTH-2:0], serial_in};
        end
    end
 
endmodule
