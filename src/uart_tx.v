module uart_tx (
    input  wire       clk,
    input  wire       rst,
    input  wire       baud_tick,
    input  wire [7:0] fifo_data,
    input  wire       fifo_empty,
    output reg        fifo_rd_en,
    output reg        tx
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            tx         <= 1;        // idle line sits HIGH
            fifo_rd_en <= 0;
            bit_count  <= 0;
            shift_reg  <= 0;
        end
        else begin
            fifo_rd_en <= 0;        // default low every cycle

            case (state)

                IDLE: begin
                    tx <= 1;
                    if (!fifo_empty) begin
                        shift_reg  <= fifo_data;  // latch byte from FIFO
                        fifo_rd_en <= 1;           // pulse rd_en to advance FIFO
                        state      <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin
                        tx        <= 0;            // pull line LOW
                        bit_count <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        tx        <= shift_reg[0]; // send LSB
                        shift_reg <= shift_reg >> 1; // shift right, next bit moves to [0]
                        if (bit_count == 7)
                            state <= STOP;
                        else
                            bit_count <= bit_count + 1;
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        tx    <= 1;                // line back HIGH
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule