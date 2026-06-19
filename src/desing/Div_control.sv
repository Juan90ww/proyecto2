module div_control #(
    parameter WIDTH = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic divisor_is_zero,
    input  logic remainder_neg,

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

    localparam N_REPS = WIDTH + 1;
    integer rep_count;

    // ---------------- Estado secuencial ----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rep_count <= 0;
        end else if (state == LOAD) begin
            rep_count <= 0;
        end else if (state == SHIFT) begin
            rep_count <= rep_count + 1;
        end
    end

    // ---------------- Logica de siguiente estado ----------------
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
              if (start) begin
                
                if (divisor_is_zero)
                  
                  next_state = DIVZERO_ST;
                else
                  next_state = LOAD;
            end
              
            end
            LOAD:      next_state = SUBTRACT;
            SUBTRACT:  next_state = TEST;
            TEST:      next_state = SHIFT;
            SHIFT: begin
                if (rep_count == N_REPS - 1)
                    next_state = DONE_ST;
                else
                    next_state = SUBTRACT;
            end
            DONE_ST:    next_state = IDLE;
            DIVZERO_ST: next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end

    always_comb begin
        load                     = 1'b0;
        shift_div                = 1'b0;
        shift_quot               = 1'b0;
        write_remainder_sub      = 1'b0;
        write_remainder_restore  = 1'b0;
        done                     = 1'b0;
        div_by_zero              = 1'b0;

        case (state)
            LOAD:      load = 1'b1;
            SUBTRACT:  write_remainder_sub = 1'b1;
            TEST: begin
                if (remainder_neg)
                    write_remainder_restore = 1'b1;
                shift_quot = 1'b1;
            end
            SHIFT:      shift_div = 1'b1;
            DONE_ST:    done = 1'b1;
            DIVZERO_ST: begin
                div_by_zero = 1'b1;
                done        = 1'b1;
            end
            default: ;
        endcase
    end

endmodule
