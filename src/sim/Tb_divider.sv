`timescale 1ns/1ps
 
module tb_divider;
 
    localparam int WIDTH = 32;
    localparam int CLK_PERIOD = 10;
 
    logic                  clk;
    logic                  rst_n;
    logic                  start;
    logic [WIDTH-1:0]      dividend;
    logic [WIDTH-1:0]      divisor_in;
    logic [WIDTH-1:0]      quotient;
    logic [WIDTH-1:0]      remainder;
    logic                  done;
    logic                  div_by_zero;
 
    int errors;
    int test_num;
 
    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------
    divider #(.WIDTH(WIDTH)) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .dividend    (dividend),
        .divisor_in  (divisor_in),
        .quotient    (quotient),
        .remainder   (remainder),
        .done        (done),
        .div_by_zero (div_by_zero)
    );
 
    // ---------------------------------------------------------
    // Clock
    // ---------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;
 
    // ---------------------------------------------------------
    // Tarea para correr un caso de prueba y validar resultado
    // ---------------------------------------------------------
    task automatic run_case(
        input [WIDTH-1:0] dvnd,
        input [WIDTH-1:0] dvsr,
        input string       label
    );
        logic [WIDTH-1:0] exp_q, exp_r;
        begin
            test_num++;
            dividend   = dvnd;
            divisor_in = dvsr;
 
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;
 
            // Esperar a que la FSM termine
            wait (done == 1'b1);
            @(posedge clk); // dejar un ciclo para que se asiente la salida
 
            $display("---------------------------------------------------");
            $display("Caso %0d: %s", test_num, label);
            $display("  dividend = %0d (0x%h)", dvnd, dvnd);
            $display("  divisor  = %0d (0x%h)", dvsr, dvsr);
 
            if (div_by_zero) begin
                $display("  RESULTADO: division por cero detectada.");
            end else begin
                exp_q = dvsr == 0 ? '0 : dvnd / dvsr;
                exp_r = dvsr == 0 ? '0 : dvnd % dvsr;
 
                $display("  quotient  = %0d (esperado %0d)", quotient, exp_q);
                $display("  remainder = %0d (esperado %0d)", remainder, exp_r);
 
                if (quotient !== exp_q || remainder !== exp_r) begin
                    $display("  RESULTADO: FALLO");
                    errors++;
                end else begin
                    $display("  RESULTADO: OK");
                end
            end
 
            // Esperar a que la FSM vuelva a IDLE antes del siguiente caso
            @(posedge clk);
        end
    endtask
 
    // ---------------------------------------------------------
    // Estimulo principal
    // ---------------------------------------------------------
    initial begin
        $dumpfile("tb_divider.vcd");
        $dumpvars(0, tb_divider);
 
        errors    = 0;
        test_num  = 0;
        rst_n     = 1'b0;
        start     = 1'b0;
        dividend  = '0;
        divisor_in= '0;
 
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
 
        // Caso 1: division exacta
        run_case(32'd20, 32'd4, "Division exacta (20 / 4)");
 
        // Caso 2: division con residuo
        run_case(32'd17, 32'd5, "Division con residuo (17 / 5)");
 
        // Caso 3: dividendo menor que el divisor
        run_case(32'd3, 32'd9, "Dividendo menor al divisor (3 / 9)");
 
        $display("---------------------------------------------------");
        if (errors == 0)
            $display("TODOS LOS CASOS PASARON (%0d/%0d)", test_num, test_num);
        else
            $display("%0d DE %0d CASOS FALLARON", errors, test_num);
        $display("---------------------------------------------------");
 
        repeat (5) @(posedge clk);
        $finish;
    end
 
endmodule
