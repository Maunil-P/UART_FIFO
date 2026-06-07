module fifo #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             wr_en,
    input  wire             rd_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire [WIDTH-1:0] rd_data,   
    output wire             full,
    output wire             empty
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [3:0] wr_ptr;
    reg [3:0] rd_ptr;

    assign empty   = (wr_ptr == rd_ptr);
    assign full    = (wr_ptr[2:0] == rd_ptr[2:0]) && (wr_ptr[3] != rd_ptr[3]);
    assign rd_data = mem[rd_ptr[2:0]];  /

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end
        else if (wr_en && !full) begin
            mem[wr_ptr[2:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
        end
        else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

endmodule