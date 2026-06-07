# UART + FIFO Transmitter/Receiver

A synthesizable UART implementation in Verilog with a synchronous FIFO buffer and self-checking testbench. Built and verified using Icarus Verilog and GTKWave.

## Overview

This project implements a complete UART communication system including:
- Configurable baud rate generator
- 8-entry synchronous FIFO buffer
- UART transmitter FSM
- UART receiver FSM with start-bit detection and baud recovery
- Self-checking loopback testbench

## Project Structure
UART_FIFO/
├── src/
│   ├── baud_timer.v   — clock divider, generates baud_tick pulse
│   ├── fifo.v         — 8x8 synchronous FIFO with full/empty flags
│   ├── uart_tx.v      — UART transmitter FSM (IDLE/START/DATA/STOP)
│   ├── uart_rx.v      — UART receiver FSM with start-bit resync
│   └── uart_top.v     — top level, wires all modules together
└── tb/
├── uart_tx_tb.v   — isolated TX testbench with self-checking decoder
└── uart_top_tb.v  — full system loopback testbench

## How It Works

### UART Protocol
UART transmits bytes serially over a single wire. When idle the line sits HIGH.
A byte transmission consists of:
- 1 start bit (LOW)
- 8 data bits, LSB first
- 1 stop bit (HIGH)

Because it is UART both sides must be configured to the same baud rate ahead of time. There is no negotiation.

### FIFO
A synchronous 8-entry FIFO buffers bytes between the CPU/testbench and the TX module. The CPU can write up to 8 bytes in burst and the transmitter drains them one at a time in the background.

### Baud Rate Configuration
Default configuration:
| Parameter | Value |
|---|---|
| Clock frequency | 50 MHz |
| Baud rate | 9600 |
| CLKS_PER_BAUD | 5208 |

To change baud rate, override the parameter at instantiation:
```verilog
uart_top #(.CLKS_PER_BAUD(434)) dut (...);  // 115200 baud at 50MHz
```

## Running the Simulation

### Requirements
- [Icarus Verilog](http://bleyer.org/icarus/)
- [GTKWave](https://sourceforge.net/projects/gtkwave/)

### TX module test
```bash
iverilog -o tx_sim.out tb/uart_tx_tb.v src/uart_tx.v src/baud_timer.v
vvp tx_sim.out
```

### Full system loopback test
```bash
iverilog -o top_sim.out tb/uart_top_tb.v src/uart_top.v src/uart_tx.v src/uart_rx.v src/fifo.v src/baud_timer.v
vvp top_sim.out
```

### View waveforms
```bash
gtkwave uart_top.vcd
```

## Test Results

### TX testbench