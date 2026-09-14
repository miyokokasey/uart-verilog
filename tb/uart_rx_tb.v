`timescale 1ns / 1ps

module uart_rx_tb;

    reg clk;
    reg rst;
    reg rx_serial;
    
    wire baud_tick;
    wire [7:0] data_out;
    wire rx_done;

    // Instantiate baud rate generator
    // Instantiate Baud Generator using CLK_FREQ and BAUD_RATE parameters
    baud_gen #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9600)
    ) u_baud_gen (
        .clk(clk),
        .rst(rst),
        .tick(baud_tick)  // Connects to baud_tick wire in uart_rx_tb
    );

    // Instantiate UART receiver
    uart_rx u_uart_rx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .rx_serial(rx_serial),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    // 50 MHz Clock generation (20 ns period)
    always #10 clk = ~clk;

    // Task to send one 10-bit UART frame manually (104.16 us per bit)
    task send_uart_byte(input [7:0] byte_to_send);
        integer i;
        begin
            // 1. Start Bit (LOW)
            rx_serial = 1'b0;
            #104160;

            // 2. 8 Data Bits (LSB First)
            for (i = 0; i < 8; i = i + 1) begin
                rx_serial = byte_to_send[i];
                #104160;
            end

            // 3. Stop Bit (HIGH)
            rx_serial = 1'b1;
            #104160;
        end
    endtask

    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);

        // Initialize signals
        clk       = 0;
        rst       = 1;
        rx_serial = 1; // Idle high

        // Apply reset
        #100;
        rst = 0;
        #100;

        // Drive byte 0x41 (ASCII 'A' -> 0b01000001) manually onto rx_serial
        $display("Sending byte 0x41...");
        send_uart_byte(8'h41);

        // Idle time after frame
        #200000;

        // Drive a second test byte 0xA5 (0b10100101)
        $display("Sending byte 0xA5...");
        send_uart_byte(8'hA5);

        #200000;

        // Check output
        if (data_out == 8'hA5) begin
            $display("SUCCESS: RX module received byte correctly!");
        end else begin
            $display("ERROR: Expected 0xA5, got 0x%h", data_out);
        end

        $finish;
    end

endmodule