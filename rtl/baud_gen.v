// rtl/baud_gen.v
module baud_gen #
(
    parameter CLK_FREQ  = 50_000_000, // 50 MHz system clock
    parameter BAUD_RATE = 9600        // Target baud rate
)
(
    input wire clk,
    input wire rst,
    output reg tick                   // Pulses high for 1 clock cycle at 16x baud rate
);

    // Compute how many clock cycles we need to count to get 16 ticks per bit
    // For 50MHz and 9600 Baud: 50,000,000 / (9600 * 16) = 325.52 -> 326
    localparam DIVISOR = CLK_FREQ / (BAUD_RATE * 16);
    
    // Determine the width of the counter register dynamically
    // $clog2(326) calculates how many binary bits we need to hold the number 326
    reg [$clog2(DIVISOR)-1:0] counter;

    always @(posedge clk or posedge rst) 
    begin
        if (rst) 
        begin
            counter <= 0;
            tick    <= 1'b0;
        end 
        else 
        begin
            if (counter == (DIVISOR - 1)) 
            begin
                counter <= 0;
                tick    <= 1'b1; // Fire the tick pulse for exactly one clock cycle
            end 
            else 
            begin
                counter <= counter + 1;
                tick    <= 1'b0; // Keep it low otherwise
            end
        end
    end

endmodule
