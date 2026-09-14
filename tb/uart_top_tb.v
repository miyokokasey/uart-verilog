`timescale 1ns / 1ps

module uart_top_tb;

    reg        clk;
    reg        rst;
    reg        tx_start;
    reg  [7:0] data_in;
    wire       tx_busy;
    wire [7:0] data_out;
    wire       rx_done;

    // Instantiate Top-Level Module
    uart_top #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(9600)
    ) uut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx_busy(tx_busy),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    // 50 MHz Clock generation (20 ns period)
    always #10 clk = ~clk;

    // Self-checking task to transmit a byte and verify reception
    task send_and_check(input [7:0] test_byte);
        begin
            // Wait if TX is currently busy
            while (tx_busy) @(posedge clk);

            // Send 1-cycle start pulse with data
            @(posedge clk);
            data_in  = test_byte;
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;

            // Wait for receiver to signal completion
            @(posedge rx_done);

            // Self-checking validation logic
            if (data_out === test_byte) begin
                $display("[PASS] Sent: 0x%h | Received: 0x%h", test_byte, data_out);
            end else begin
                $display("[FAIL] Sent: 0x%h | Received: 0x%h (MISMATCH!)", test_byte, data_out);
            end

            // Wait brief guard band between frames
            #50000;
        end
    endtask

    initial begin
        $dumpfile("uart_top_tb.vcd");
        $dumpvars(0, uart_top_tb);

        // Initialize signals
        clk      = 0;
        rst      = 1;
        tx_start = 0;
        data_in  = 8'd0;

        // Apply global reset
        #100;
        rst = 0;
        #100;

        $display("--- STARTING UART LOOPBACK VERIFICATION ---");

        // Test vectors
        send_and_check(8'h41); // ASCII 'A' (0b01000001)
        send_and_check(8'hA5); // Alternating bit pattern (0b10100101)
        send_and_check(8'hFF); // All high bits
        send_and_check(8'h00); // All low bits

        $display("--- ALL TESTS COMPLETED ---");
        $finish;
    end

endmodule