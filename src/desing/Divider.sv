module divider #(
    parameter int WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  start,
    input  logic [WIDTH-1:0]      dividend,
    input  logic [WIDTH-1:0]      divisor_in,
    output logic [WIDTH-1:0]      quotient,
    output logic [WIDTH-1:0]      remainder,
    output logic                  done,
    output logic                  div_by_zero
);
 
    // ---------------------------------------------------------
    // Señales internas / datapath
    // ---------------------------------------------------------
    logic [2*WIDTH-1:0] divisor_reg;     // 64 bits
    logic [2*WIDTH-1:0] remainder_reg;   // 64 bits
    logic [WIDTH-1:0]   quotient_reg;    // 32 bits
 
    logic [2*WIDTH-1:0] sub_result;
    logic                remainder_neg;
 
    // Carga inicial: Remainder = {32'b0, dividend}, Divisor = {divisor_in, 32'b0}
    logic load;
    // Control de shifts y escritura
    logic shift_div;
    logic shift_quot;
    logic write_remainder_sub;
    logic write_remainder_restore;
 
    // ALU de 64 bits: resta Remainder - Divisor
    assign sub_result    = remainder_reg - divisor_reg;
    assign remainder_neg = sub_result[2*WIDTH-1];
 
    // ---------------------------------------------------------
    // Datapath: registros con shift (modular: divisor + quotient)
    // ---------------------------------------------------------
    shift_reg_right #(.WIDTH(2*WIDTH)) u_divisor_reg (
        .clk      (clk),
        .rst_n    (rst_n),
        .load     (load),
        .shift_en (shift_div),
        .load_val ({divisor_in, {WIDTH{1'b0}}}),
        .q        (divisor_reg)
    );
 
    shift_reg_left #(.WIDTH(WIDTH)) u_quotient_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .load       (load),
        .shift_en   (shift_quot),
        .serial_in  (~remainder_neg), // bit0 = 1 si resta fue exitosa (>=0)
        .load_val   ({WIDTH{1'b0}}),
        .q          (quotient_reg)
    );
 
    // Registro Remainder: carga, escribe resultado de resta o restaura
    // sumando el divisor de vuelta cuando la resta dio negativo.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remainder_reg <= '0;
        end else if (load) begin
            remainder_reg <= {{WIDTH{1'b0}}, dividend};
        end else if (write_remainder_sub) begin
            remainder_reg <= sub_result;
        end else if (write_remainder_restore) begin
            remainder_reg <= remainder_reg + divisor_reg; // restaurar
        end
    end
 
    // ---------------------------------------------------------
    // FSM de control
    // ---------------------------------------------------------
    div_control #(.WIDTH(WIDTH)) u_control (
        .clk                      (clk),
        .rst_n                    (rst_n),
        .start                    (start),
        .divisor_is_zero          (divisor_in == '0),
        .remainder_neg            (remainder_neg),
        .load                     (load),
        .shift_div                (shift_div),
        .shift_quot               (shift_quot),
        .write_remainder_sub      (write_remainder_sub),
        .write_remainder_restore  (write_remainder_restore),
        .done                     (done),
        .div_by_zero              (div_by_zero)
    );
 
    assign quotient  = quotient_reg;
    assign remainder = remainder_reg[WIDTH-1:0];
 
endmodule
