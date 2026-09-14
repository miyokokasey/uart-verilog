module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] data_in,
    output wire       tx_busy,
    output wire [7:0] data_out,
    output wire       rx_done
);

    wire baud_tick;
    wire serial_line; // Physical loopback wire: tx_serial -> rx_serial

    // Shared 16x Baud Generator Instance
    baud_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) u_baud (
        .clk(clk),
        .rst(rst),
        .tick(baud_tick)
    );

    // UART Transmitter Instance
    uart_tx u_tx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx_serial(serial_line),
        .tx_busy(tx_busy)
    );

    // UART Receiver Instance
    uart_rx u_rx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .rx_serial(serial_line),
        .data_out(data_out),
        .rx_done(rx_done)
    );

endmodule