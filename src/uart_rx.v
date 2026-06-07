module uart_rx #(
    parameter CLKS_PER_BAUD = 5208
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_done
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    localparam HALF = CLKS_PER_BAUD / 2;

    // 2-flop synchronizer
    reg rx_d1, rx_sync;
    always @(posedge clk) begin
        rx_d1   <= rx;
        rx_sync <= rx_d1;
    end

    reg [1:0]  state;
    reg [7:0]  shift_reg;
    reg [2:0]  bit_count;
    reg [12:0] cnt;        // counts clock cycles, resets at each new bit

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            rx_data   <= 0;
            rx_done   <= 0;
            bit_count <= 0;
            shift_reg <= 0;
            cnt       <= 0;
        end
        else begin
            rx_done <= 0;
            cnt     <= cnt + 1;   // always counting

            case (state)

                IDLE: begin
                    cnt <= 0;
                    if (!rx_sync) begin     // falling edge -- start bit begins
                        state <= START;
                    end
                end

                START: begin
                    // wait HALF a baud period to reach middle of start bit
                    if (cnt == HALF - 1) begin
                        cnt <= 0;
                        if (!rx_sync) begin // still low -- valid start bit
                            bit_count <= 0;
                            state     <= DATA;
                        end
                        else begin          // glitch -- go back
                            state <= IDLE;
                        end
                    end
                end

                DATA: begin
                    // wait one full baud period between samples
                    if (cnt == CLKS_PER_BAUD - 1) begin
                        cnt       <= 0;
                        shift_reg <= {rx_sync, shift_reg[7:1]};
                        if (bit_count == 7)
                            state <= STOP;
                        else
                            bit_count <= bit_count + 1;
                    end
                end

                STOP: begin
                    if (cnt == CLKS_PER_BAUD - 1) begin
                        cnt   <= 0;
                        state <= IDLE;
                        if (rx_sync) begin
                            rx_data <= shift_reg;
                            rx_done <= 1;
                        end
                    end
                end

            endcase
        end
    end

endmodule