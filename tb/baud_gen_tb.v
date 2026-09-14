// tb/baud_gen_tb.v
`timescale 1ns / 1ps

module baud_gen_tb;

    // Inputs to the UUT (Unit Under Test)
    reg clk;
    reg rst;

    // Outputs from the UUT
    wire tick;

    // Instantiate the Baud Generator
    // We can use default parameters (50MHz, 9600)
    baud_gen uut (
        .clk(clk),
        .rst(rst),
        .tick(tick)
    );

    // Generate a 50 MHz clock signal
    // Period = 1 / 50MHz = 20ns. We toggle every 10ns.
    always begin
        #10 clk = ~clk;
    end

    initial begin
        // Setup wave dumping for GTKWave
        $dumpfile("baud_gen_tb.vcd");
        $dumpvars(0, baud_gen_tb);

        // Initialize signals
        clk = 0;
        rst = 1;

        // Hold reset for 100ns, then release it
        #100;
        rst = 0;

        // Run simulation long enough to see a few tick pulses
        // Since a tick happens every ~326 clock cycles (6520ns), running for 30,000ns is plenty.
        #30000;

        $display("Simulation finished safely.");
        $finish;
    end

endmodule

