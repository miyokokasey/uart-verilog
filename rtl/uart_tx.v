module uart_tx 
(
    input  wire       clk,
    input  wire       rst,
    input  wire       baud_tick,   // 16x tick from baud_gen
    input  wire       tx_start,    // pulse high for 1 cycle to begin sending
    input  wire [7:0] data_in,
    output reg        tx_serial,   // idle-high serial line
    output reg        tx_busy      // high while a byte is in flight
);

// FSM State Encoding
localparam [1:0] STATE_IDLE  = 2'b00,
                 STATE_START = 2'b01,
                 STATE_DATA  = 2'b10,
                 STATE_STOP  = 2'b11;

reg [1:0] state;
reg [3:0] tick_count; // Counts 0 to 15 (16 oversampling ticks = 1 bit duration)
reg [2:0] bit_index;  // Tracks current data bit (0 to 7)
reg [7:0] tx_shift;   // Internal shift register for LSB-first output

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state      <= STATE_IDLE;
        tx_serial  <= 1'b1; // UART bus idles high
        tx_busy    <= 1'b0;
        tick_count <= 4'd0;
        bit_index  <= 3'd0;
        tx_shift   <= 8'd0;
    end else begin
        case (state)
            STATE_IDLE: begin
                tx_serial <= 1'b1;
                tx_busy   <= 1'b0;
                tick_count <= 4'd0;
                bit_index  <= 3'd0;

                if (tx_start) begin
                    tx_shift <= data_in; // Latch input byte
                    tx_busy  <= 1'b1;    // Assert busy signal immediately
                    state    <= STATE_START;
                end
            end

            STATE_START: begin
                tx_serial <= 1'b0; // Start bit is active LOW (0)

                if (baud_tick) begin
                    if (tick_count == 4'd15) begin
                        tick_count <= 4'd0;
                        state      <= STATE_DATA;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end
            end

            STATE_DATA: begin
                tx_serial <= tx_shift[0]; // Output current LSB

                if (baud_tick) begin
                    if (tick_count == 4'd15) begin
                        tick_count <= 4'd0;
                        tx_shift   <= tx_shift >> 1; // Shift right for next bit

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= STATE_STOP;
                        end 
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end 
                    else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end
            end

            STATE_STOP: begin
                tx_serial <= 1'b1; // Stop bit is active HIGH (1)

                if (baud_tick) begin
                    if (tick_count == 4'd15) begin
                        tick_count <= 4'd0;
                        tx_busy    <= 1'b0; // Transmission finished
                        state      <= STATE_IDLE;
                    end else begin
                        tick_count <= tick_count + 1'b1;
                    end
                end
            end

            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule