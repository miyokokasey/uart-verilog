# UART Transceiver in Verilog

A parameterized UART transmitter and receiver, implemented as FSM + shift-register
Verilog modules, verified with a self-checking loopback testbench in Icarus Verilog.

## Frame Format
- 1 start bit (0)
- 8 data bits, LSB first
- 1 stop bit (1)
- No parity

## Architecture
[paste the ASCII block diagram here]

## Repo Layout
- rtl/ — synthesizable design (baud_gen, uart_tx, uart_rx, uart_top)
- tb/ — testbenches, including a self-checking loopback test
- waveforms/ — GTKWave screenshots
- synth/ — Yosys synthesis report (optional)

## How to Run
    iverilog -o sim_top rtl/baud_gen.v rtl/uart_tx.v rtl/uart_rx.v rtl/uart_top.v tb/uart_top_tb.v
    vvp sim_top
    gtkwave uart_top_tb.vcd

## Verification
Self-checking testbench sends 4 bytes through TX -> loopback -> RX and asserts
byte-for-byte equality, including edge cases (0x00, 0xFF, back-to-back frames):

    PASS: sent 0x41, received 0x41
    PASS: sent 0xa5, received 0xa5
    PASS: sent 0x00, received 0x00
    PASS: sent 0xff, received 0xff
    
    ---- Results: 4 passed, 0 failed ----

![loopback waveform](waveforms/loopback_full_sequence.png)

## Synthesis (optional)
Ran through Yosys for a gate-level sanity check:

    [paste stat output]
