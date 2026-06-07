`timescale 1ns/1ps   // tells simulator: time unit = 1ns, precision = 1ps

module uart_tx_tb;


    reg        clk;
    reg        rst;
    reg  [7:0] fifo_data;
    reg        fifo_empty;
    wire       fifo_rd_en;
    wire       tx;
    wire       baud_tick;

    // -------------------------------------------------------------------------
    // INSTANTIATE MODULES
    // plug baud_timer and uart_tx together, just like uart_top will do
    // using small CLKS_PER_BAUD so simulation runs fast
    // real value is 5208, we use 10 here so we dont wait forever
    // -------------------------------------------------------------------------
    baud_timer #(.CLKS_PER_BAUD(10)) baud_inst (
        .clk      (clk),
        .rst      (rst),
        .baud_tick(baud_tick)
    );

    uart_tx dut (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick),
        .fifo_data (fifo_data),
        .fifo_empty(fifo_empty),
        .fifo_rd_en(fifo_rd_en),
        .tx        (tx)
    );

    // -------------------------------------------------------------------------
    // CLOCK GENERATOR
    // toggles every 10ns = 20ns period = 50MHz
    // -------------------------------------------------------------------------
    always #10 clk = ~clk;

    // -------------------------------------------------------------------------
    // SELF CHECKING TASK
    // this watches the tx line and decodes the byte back
    // a task is like a function in verilog
    // -------------------------------------------------------------------------
    task decode_uart_byte;
        output [7:0] received;      // decoded byte comes out here
        integer i;
        begin
            // wait for start bit (tx goes LOW)
            @(negedge tx);

            // wait half a baud period to get to CENTER of start bit
            // this is the re-sync trick -- sample in the middle not the edge
            repeat(5) @(posedge clk);  // half of CLKS_PER_BAUD=10

            // verify start bit is still low (not a glitch)
            if (tx !== 0)
                $error("START BIT ERROR -- tx went high too early");

            // sample 8 data bits, one per baud period
            for (i = 0; i < 8; i = i + 1) begin
                repeat(10) @(posedge clk);  // wait one full baud period
                received[i] = tx;           // sample into bit i (LSB first)
            end

            // wait for stop bit
            repeat(10) @(posedge clk);
            if (tx !== 1)
                $error("STOP BIT ERROR -- tx should be HIGH");
        end
    endtask

    // -------------------------------------------------------------------------
    // MAIN TEST
    // -------------------------------------------------------------------------
    reg [7:0] received_byte;

    initial begin
        // setup waveform dump so you can open in gtkwave
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        // initialize everything
        clk        = 0;
        rst        = 1;
        fifo_empty = 1;        // fifo starts empty
        fifo_data  = 8'h00;

        // hold reset for a few cycles then release
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);

        // -------------------------------------
        // TEST 1: send 0x55 (01010101)
        // perfect alternating pattern, easy to verify in gtkwave
        // -------------------------------------
        $display("TEST 1: sending 0x55");
        fifo_data  = 8'h55;
        fifo_empty = 0;          // tell TX there is data ready

        // once TX latches the byte it pulses fifo_rd_en
        // we wait for that then set fifo_empty back
        @(posedge fifo_rd_en);
        fifo_empty = 1;

        // decode what came out and check it
        decode_uart_byte(received_byte);
        if (received_byte == 8'h55)
            $display("PASS -- got 0x%h", received_byte);
        else
            $error("FAIL -- expected 0x55 got 0x%h", received_byte);

        // small gap between bytes
        repeat(20) @(posedge clk);

        // -------------------------------------
        // TEST 2: send 'H' (0x48)
        // -------------------------------------
        $display("TEST 2: sending H (0x48)");
        fifo_data  = 8'h48;
        fifo_empty = 0;

        @(posedge fifo_rd_en);
        fifo_empty = 1;

        decode_uart_byte(received_byte);
        if (received_byte == 8'h48)
            $display("PASS -- got 0x%h", received_byte);
        else
            $error("FAIL -- expected 0x48 got 0x%h", received_byte);

        repeat(20) @(posedge clk);

        // -------------------------------------
        // TEST 3: send 0xFF (all ones)
        // -------------------------------------
        $display("TEST 3: sending 0xFF");
        fifo_data  = 8'hFF;
        fifo_empty = 0;

        @(posedge fifo_rd_en);
        fifo_empty = 1;

        decode_uart_byte(received_byte);
        if (received_byte == 8'hFF)
            $display("PASS -- got 0x%h", received_byte);
        else
            $error("FAIL -- expected 0xFF got 0x%h", received_byte);

        repeat(20) @(posedge clk);

        // -------------------------------------
        // TEST 4: send 0x00 (all zeros)
        // -------------------------------------
        $display("TEST 4: sending 0x00");
        fifo_data  = 8'h00;
        fifo_empty = 0;

        @(posedge fifo_rd_en);
        fifo_empty = 1;

        decode_uart_byte(received_byte);
        if (received_byte == 8'h00)
            $display("PASS -- got 0x%h", received_byte);
        else
            $error("FAIL -- expected 0x00 got 0x%h", received_byte);

        repeat(20) @(posedge clk);

        $display("ALL TESTS DONE");
        $finish;
    end

endmodule