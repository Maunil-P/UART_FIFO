module uart_top #(
    parameter CLKS_PER_BAUD = 5208  // 50MHz / 9600 baud, override in tb
)(
    input  wire       clk,
    input  wire       rst,

    // FIFO write interface -- driven by user/testbench
    input  wire [7:0] wr_data,
    input  wire       wr_en,
    output wire       full,

    // serial pins
    output wire       tx,
    input  wire       rx_in,

    // RX output
    output wire [7:0] rx_data,
    output wire       rx_done
);

    // internal wires connecting modules together
    wire       baud_tick;
    wire [7:0] fifo_data;
    wire       fifo_empty;
    wire       fifo_rd_en;

    // baud timer -- drives everything
    baud_timer #(.CLKS_PER_BAUD(CLKS_PER_BAUD)) baud_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick)
    );

    // FIFO -- buffers bytes waiting to transmit
    fifo fifo_inst (
        .clk    (clk),
        .rst    (rst),
        .wr_en  (wr_en),
        .rd_en  (fifo_rd_en),
        .wr_data(wr_data),
        .rd_data(fifo_data),
        .full   (full),
        .empty  (fifo_empty)
    );

    // TX -- drains FIFO and sends bytes serially
    uart_tx tx_inst (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick),
        .fifo_data (fifo_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .tx        (tx)
    );

    // RX -- receives serial bytes
   uart_rx #(.CLKS_PER_BAUD(CLKS_PER_BAUD)) rx_inst (
    .clk    (clk),
    .rst    (rst),
    .rx     (rx_in),
    .rx_data(rx_data),
    .rx_done(rx_done)
);

endmodule