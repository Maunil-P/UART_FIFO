`timescale 1ns/1ps

module uart_top_tb;

    reg        clk, rst;
    reg  [7:0] wr_data;
    reg        wr_en;
    wire       full, tx, rx_in;
    wire [7:0] rx_data;
    wire       rx_done;

    assign rx_in = tx;

    uart_top #(.CLKS_PER_BAUD(10)) dut (
        .clk(clk), .rst(rst),
        .wr_data(wr_data), .wr_en(wr_en), .full(full),
        .tx(tx), .rx_in(rx_in),
        .rx_data(rx_data), .rx_done(rx_done)
    );

    always #10 clk = ~clk;

    task send_and_check;
        input [7:0] byte_to_send;
        integer timeout;
        begin
            @(posedge clk); #1;
            wr_data = byte_to_send;
            wr_en   = 1;
            @(posedge clk); #1;
            wr_en = 0;

            timeout = 0;
            while (!rx_done && timeout < 50000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 50000)
                $error("TIMEOUT -- rx_done never fired for 0x%h", byte_to_send);
            else if (rx_data == byte_to_send)
                $display("PASS -- sent 0x%h got 0x%h", byte_to_send, rx_data);
            else
                $error("FAIL -- sent 0x%h got 0x%h", byte_to_send, rx_data);
        end
    endtask

    initial begin
        $dumpfile("uart_top.vcd");
        $dumpvars(0, uart_top_tb);
        clk=0; rst=1; wr_en=0; wr_data=0;
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);

        send_and_check(8'h55);
        send_and_check(8'h48);  // H
        send_and_check(8'h49);  // I
        send_and_check(8'h21);  // !
        send_and_check(8'hFF);
        send_and_check(8'h00);

        $display("back to back...");
        send_and_check(8'hAA);
        send_and_check(8'hBB);
        send_and_check(8'hCC);

        repeat(20) @(posedge clk);
        $display("ALL DONE");
        $finish;
    end

endmodule