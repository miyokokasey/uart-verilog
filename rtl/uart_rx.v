module uart_rx (
    input  wire       clk,
    input  wire       rst,
    input  wire       baud_tick,  // 16x oversampling tick
    input  wire       rx_serial,  // Incoming serial line
    output reg  [7:0] data_out,   // Reconstructed byte output
    output reg        rx_done     // Single-cycle pulse when byte is ready
);

    // FSM State Encoding
    localparam [1:0] STATE_IDLE  = 2'b00,
                     STATE_START = 2'b01,
                     STATE_DATA  = 2'b10,
                     STATE_STOP  = 2'b11;

    reg [1:0] state;
    reg [3:0] tick_count; // Tracks 16x oversampling ticks (0 to 15)
    reg [2:0] bit_index;  // Tracks received data bits (0 to 7)
    reg [7:0] rx_shift;   // Internal shift register for serial-to-parallel conversion

    // 2-Stage Synchronizer & Edge Detector for rx_serial
    reg rx_sync_0, rx_sync_1;
    reg rx_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
            rx_prev   <= 1'b1;
        end else begin
            rx_sync_0 <= rx_serial;
            rx_sync_1 <= rx_sync_0;
            rx_prev   <= rx_sync_1;
        end
    end

    // Falling edge detection: 1 -> 0 transition
    wire falling_edge = (rx_prev && !rx_sync_1);

    // Main FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= STATE_IDLE;
            tick_count <= 4'd0;
            bit_index  <= 3'd0;
            rx_shift   <= 8'd0;
            data_out   <= 8'd0;
            rx_done    <= 1'b0;
        end else begin
            // Default: rx_done is a 1-cycle pulse
            rx_done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    tick_count <= 4'd0;
                    bit_index  <= 3'd0;
                    
                    // Detect falling edge (Start bit onset)
                    if (falling_edge) begin
                        state <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (baud_tick) begin
                        // Mid-point check at tick 7 (0 indexed: tick count 7 is the 8th tick)
                        if (tick_count == 4'd7) begin
                            if (rx_sync_1 == 1'b0) begin
                                // Valid start bit verified! Reset tick counter for full bit timing
                                tick_count <= 4'd0;
                                state      <= STATE_DATA;
                            end else begin
                                // Glitch detected (line pulled high again) -> return to IDLE
                                state <= STATE_IDLE;
                            end
                        end 
                        else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end

                STATE_DATA: begin
                    if (baud_tick) begin
                        if (tick_count == 4'd15) begin
                            tick_count <= 4'd0;
                            
                            // Sample at mid-bit point (tick 15 of current 16-tick interval)
                            // Shift received bit into MSB position (shifts right towards LSB)
                            rx_shift <= {rx_sync_1, rx_shift[7:1]};

                            if (bit_index == 3'd7) begin
                                bit_index <= 3'd0;
                                state     <= STATE_STOP;
                            end else begin
                                bit_index <= bit_index + 1'b1;
                            end
                        end else begin
                            tick_count <= tick_count + 1'b1;
                        end
                    end
                end

                STATE_STOP: begin
                    if (baud_tick) begin
                        if (tick_count == 4'd15) begin
                            tick_count <= 4'd0;
                            
                            // Confirm valid Stop bit (high line)
                            if (rx_sync_1 == 1'b1) begin
                                data_out <= rx_shift; // Latch completed byte
                                rx_done  <= 1'b1;     // Pulse ready flag
                            end
                            
                            state <= STATE_IDLE;
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