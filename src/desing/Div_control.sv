module div_control #(
    parameter WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic divisor_is_zero,
    input  logic remainder_neg,   // combinacional: (Remainder - Divisor) < 0

    output logic load,
    output logic do_subtract,     // escribe sub_result en Remainder
    output logic do_restore,      // escribe Remainder + Divisor en Remainder
    output logic shift_div,
    output logic shift_quot,
    output logic quot_bit,        // valor a insertar en LSB del quotient
    output logic done,
    output logic div_by_zero
);

    typedef enum logic [1:0] {
        IDLE,
        LOAD,
        ITERATE,
        DONE_ST
    } state_t;

    state_t state, next_state;
    integer rep_count;
    localparam N_REPS = WIDTH + 1;

    // ---------------- Registros de estado ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         state <= IDLE;
        else                state <= next_state;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)                   rep_count <= 0;
        else if (state == LOAD)       rep_count <= 0;
        else if (state == ITERATE)    rep_count <= rep_count + 1;
    end

    // ---------------- Siguiente estado ----------------
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    if (divisor_is_zero)
                        next_state = DONE_ST;
                    else
                        next_state = LOAD;
                end
            end
            LOAD:    next_state = ITERATE;
            ITERATE: begin
                if (rep_count == N_REPS - 1)
                    next_state = DONE_ST;
                else
                    next_state = ITERATE;
            end
            DONE_ST: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // ---------------- Salidas ----------------
    // En ITERATE: cada ciclo hace resta combinacional, decide, escribe y shiftea.
    // do_subtract y do_restore son mutuamente excluyentes.
    always_comb begin
        load         = 1'b0;
        do_subtract  = 1'b0;
        do_restore   = 1'b0;
        shift_div    = 1'b0;
        shift_quot   = 1'b0;
        quot_bit     = 1'b0;
        done         = 1'b0;
        div_by_zero  = 1'b0;

        case (state)
            LOAD: begin
                load = 1'b1;
            end

            ITERATE: begin
                // La ALU calcula Remainder - Divisor combinacionalmente.
                // Si >= 0: escribir resultado, bit de quotient = 1
                // Si <  0: restaurar (Remainder queda igual), bit = 0
                if (!remainder_neg) begin
                    do_subtract = 1'b1;
                    quot_bit    = 1'b1;
                end else begin
                    do_restore  = 1'b1;
                    quot_bit    = 1'b0;
                end
                shift_quot = 1'b1;
                shift_div  = 1'b1;
            end

            DONE_ST: begin
                done        = 1'b1;
                div_by_zero = divisor_is_zero;
            end

            default: ;
        endcase
    end

endmodule
