module div_control #(
    parameter int WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic divisor_is_zero,
    input  logic remainder_neg,     // resultado de la resta combinacional
 
    output logic load,
    output logic shift_div,
    output logic shift_quot,
    output logic write_remainder_sub,
    output logic write_remainder_restore,
    output logic done,
    output logic div_by_zero
);
 
    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        SUBTRACT,
        TEST,
        SHIFT,
        DONE_ST,
        DIVZERO_ST
    } state_t;
 
    state_t state, next_state;
 
    // Contador de repeticiones: el diagrama hace 33 repeticiones
    // (1 resta inicial + 32 shifts), equivalente a WIDTH+1 pasos.
    localparam int N_REPS = WIDTH + 1;
    logic [$clog2(N_REPS+1)-1:0] rep_count;
 
    // ---------------- Estado secuencial ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rep_count <= '0;
        end else if (state == LOAD) begin
            rep_count <= '0;
        end else if (state == SHIFT) begin
            rep_count <= rep_count + 1'b1;
        end
    end
 
    // ---------------- Logica de siguiente estado ----------------
    always_comb begin
        next_state = state;
        unique case (state)
            IDLE: begin
                if (start)
                    next_state = divisor_is_zero ? DIVZERO_ST : LOAD;
            end
 
            LOAD: begin
                next_state = SUBTRACT;
            end
 
            SUBTRACT: begin
                next_state = TEST;
            end
 
            TEST: begin
                next_state = SHIFT;
            end
 
            SHIFT: begin
                if (rep_count == N_REPS - 1)
                    next_state = DONE_ST;
                else
                    next_state = SUBTRACT;
            end
 
            DONE_ST: begin
                next_state = IDLE;
            end
 
            DIVZERO_ST: begin
                next_state = IDLE;
            end
 
            default: next_state = IDLE;
        endcase
    end
 
    // ---------------- Salidas (Moore) ----------------
    always_comb begin
        load                     = 1'b0;
        shift_div                = 1'b0;
        shift_quot               = 1'b0;
        write_remainder_sub      = 1'b0;
        write_remainder_restore  = 1'b0;
        done                     = 1'b0;
        div_by_zero              = 1'b0;
 
        unique case (state)
            LOAD: begin
                load = 1'b1;
            end
 
            SUBTRACT: begin
                write_remainder_sub = 1'b1; // Remainder <= Remainder - Divisor
            end
 
            TEST: begin
                // Si remainder_neg, "restauramos" no escribiendo el resultado
                // de la resta (write_remainder_sub ya escribio en SUBTRACT,
                // por lo que aqui revertimos sumando el divisor de vuelta).
                if (remainder_neg)
                    write_remainder_restore = 1'b1;
                shift_quot = 1'b1; // Quotient <= {Quotient[WIDTH-2:0], !remainder_neg}
            end
 
            SHIFT: begin
                shift_div = 1'b1; // Divisor <= Divisor >> 1
            end
 
            DONE_ST: begin
                done = 1'b1;
            end
 
            DIVZERO_ST: begin
                div_by_zero = 1'b1;
                done        = 1'b1;
            end
 
            default: ;
        endcase
    end
 
endmodule
