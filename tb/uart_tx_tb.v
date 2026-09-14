// tb/uart_tx_tb.v
`timescale 1ns / 1ps

module uart_tx_tb;

    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] data_in;

    wire tick;
    wire tx_serial;
    wire tx_busy;

    // Instantiate Baud Generator (50 MHz clock, 9600 baud rate)
    baud_gen #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9600)
    ) baud_inst (
        .clk(clk),
        .rst(rst),
        .tick(tick)
    );

    // Instantiate Transmitter Unit Under Test
    uart_tx uut (
        .clk(clk),
        .rst(rst),
        .baud_tick(tick),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx_serial(tx_serial),
        .tx_busy(tx_busy)
    );

    // 50 MHz clock generation (20ns period)
    always begin
        #10 clk = ~clk;
    end

    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        // Initialize signals
        clk      = 0;
        rst      = 1;
        tx_start = 0;
        data_in  = 8'h00;

        // Reset sequence
        #100;
        rst = 0;
        #100;

        // Transmit ASCII 'A' (8'h41 = 8'b01000001)
        @(posedge clk);
        data_in  = 8'h41;
        tx_start = 1'b1;

        @(posedge clk);
        tx_start = 1'b0; // Deassert after 1 clock cycle

        // Wait until transmission completes
        wait(tx_busy == 1'b1);
        wait(tx_busy == 1'b0);

        #50000; // Extra margin to observe line returning to IDLE high
        $display("Transmission of 0x41 completed successfully.");
        $finish;
    end

endmodule
