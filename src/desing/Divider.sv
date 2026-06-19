module divider #(
    parameter WIDTH = 32
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             start,
    input  logic [WIDTH-1:0] dividend,
    input  logic [WIDTH-1:0] divisor_in,
    output logic [WIDTH-1:0] quotient,
    output logic [WIDTH-1:0] remainder,
    output logic             done,
    output logic             div_by_zero
);

    localparam BITS = 2 * WIDTH;

    // Registros internos
    logic [BITS-1:0]  divisor_reg;
    logic [BITS-1:0]  remainder_reg;
    logic [WIDTH-1:0] quotient_reg;

    // ALU combinacional: Remainder - Divisor
    logic [BITS-1:0] sub_result;
    logic            remainder_neg;
    assign sub_result    = remainder_reg - divisor_reg;
    assign remainder_neg = sub_result[BITS-1];

    // Señales de control
    logic load, do_subtract, do_restore;
    logic shift_div, shift_quot, quot_bit;

    // ---------------- Instancia FSM ----------------
    div_control #(.WIDTH(WIDTH)) u_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .divisor_is_zero(divisor_in == {WIDTH{1'b0}}),
        .remainder_neg  (remainder_neg),
        .load           (load),
        .do_subtract    (do_subtract),
        .do_restore     (do_restore),
        .shift_div      (shift_div),
        .shift_quot     (shift_quot),
        .quot_bit       (quot_bit),
        .done           (done),
        .div_by_zero    (div_by_zero)
    );

    // ---------------- Registro Divisor (shift right) ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            divisor_reg <= '0;
        else if (load)
            divisor_reg <= {{WIDTH{1'b0}}, divisor_in} << WIDTH; // divisor en mitad alta
        else if (shift_div)
            divisor_reg <= divisor_reg >> 1;
    end

    // ---------------- Registro Remainder ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            remainder_reg <= '0;
        else if (load)
            remainder_reg <= {{WIDTH{1'b0}}, dividend};
        else if (do_subtract)
            remainder_reg <= sub_result;
        // do_restore: remainder_reg no cambia (ya tiene valor correcto)
    end

    // ---------------- Registro Quotient (shift left) ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            quotient_reg <= '0;
        else if (load)
            quotient_reg <= '0;
        else if (shift_quot)
            quotient_reg <= {quotient_reg[WIDTH-2:0], quot_bit};
    end

    assign quotient  = quotient_reg;
    assign remainder = remainder_reg[WIDTH-1:0];

endmodule
