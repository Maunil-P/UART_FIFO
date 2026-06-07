module baud_timer #(
    parameter CLKS_PER_BAUD = 5208 //9600
)(
    input wire clk,
    input wire rst,
    output reg baud_tick
);


    reg [12:0] counter; 

    always @(posedge clk) begin
        if (rst) begin
            counter   <= 0;
            baud_tick <= 0;
        end
        else if (counter == CLKS_PER_BAUD - 1) begin // the next clock cycle will trigger baud_tick
            counter   <= 0;
            baud_tick <= 1;
        end
        else begin
            counter   <= counter + 1;
            baud_tick <= 0;
        end
    end

endmodule
