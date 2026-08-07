`timescale 1ns / 1ps

module uart_tx_rtl_tb();

    localparam CLK_FREQUENCY = 50_000_000;
    localparam BAUD_RATE = 115200;
    localparam BAUD_PERIOD = 1_000_000_000 / BAUD_RATE;
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQUENCY;

    wire txd, tx_ready;
    reg clk, tx_valid, rst_n;
    reg [7:0] tx_data;
    
    uart_tx_rtl #(
        .CLK_FREQUENCY(CLK_FREQUENCY),
        .BAUD_RATE(BAUD_RATE)
    ) dut(
        .txd(txd),
        .tx_ready(tx_ready),
        .clk(clk),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .rst_n(rst_n)
    );

    initial begin
        tx_valid = 1'b0; rst_n = 1'b0; tx_data = 8'b0110_1101;
    end

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        #10 rst_n = 1'b1;

        #10 tx_valid = 1'b1;
        #20 tx_valid = 1'b0;

        #(8*BAUD_PERIOD) tx_data = 8'b1101_0101;

        #5 tx_valid = 1'b1;
    end

    initial #(25*BAUD_PERIOD) $finish;

endmodule