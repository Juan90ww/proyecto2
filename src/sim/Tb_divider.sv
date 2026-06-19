`timescale 1ns/1ps

module tb_divider;

    localparam WIDTH      = 32;
    localparam CLK_PERIOD = 10;

    logic             clk, rst_n, start;
    logic [WIDTH-1:0] dividend, divisor_in;
    logic [WIDTH-1:0] quotient, remainder;
    logic             done, div_by_zero;

    int errors, test_num;

    divider #(.WIDTH(WIDTH)) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .dividend   (dividend),
        .divisor_in (divisor_in),
        .quotient   (quotient),
        .remainder  (remainder),
        .done       (done),
        .div_by_zero(div_by_zero)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    task automatic run_case(
        input [WIDTH-1:0] dvnd,
        input [WIDTH-1:0] dvsr,
        input string label
    );
        logic [WIDTH-1:0] exp_q, exp_r;
        test_num++;
        dividend   = dvnd;
        divisor_in = dvsr;

        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        @(posedge done);
        @(posedge clk); #1;

        $display("---------------------------------------------------");
        $display("Caso %0d: %s", test_num, label);
        $display("  dividend = %0d (0x%h)", dvnd, dvnd);
        $display("  divisor  = %0d (0x%h)", dvsr, dvsr);

        exp_q = dvnd / dvsr;
        exp_r = dvnd % dvsr;
        $display("  quotient  = %0d (esperado %0d)", quotient, exp_q);
        $display("  remainder = %0d (esperado %0d)", remainder, exp_r);

        if (quotient !== exp_q || remainder !== exp_r) begin
            $display("  RESULTADO: FALLO");
            errors++;
        end else
            $display("  RESULTADO: OK");

        repeat(2) @(posedge clk);
    endtask

    initial begin
        $dumpfile("tb_divider.vcd");
        $dumpvars(0, tb_divider);

        errors = 0; test_num = 0;
        rst_n = 0; start = 0;
        dividend = 0; divisor_in = 0;

        repeat(3) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        run_case(32'd25, 32'd5,  "Division exacta (25 / 5)");
        run_case(32'd17, 32'd5,  "Division con residuo (17 / 5)");
        run_case(32'd3,  32'd9,  "Dividendo menor al divisor (3 / 9)");

        $display("---------------------------------------------------");
        if (errors == 0)
            $display("TODOS LOS CASOS PASARON (%0d/%0d)", test_num, test_num);
        else
            $display("%0d DE %0d CASOS FALLARON", errors, test_num);
        $display("---------------------------------------------------");

        repeat(5) @(posedge clk);
        $finish;
    end

endmodule
