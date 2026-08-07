module uart_tx_rtl #(
    parameter CLK_FREQUENCY = 50_000_000,
    parameter BAUD_RATE = 115200
)(
    output txd,
    output tx_ready,
    input clk,
    input [7:0] tx_data,
    input tx_valid,
    input rst_n
);
    localparam BAUD_CNT_MAX = (CLK_FREQUENCY / BAUD_RATE) - 1;
    localparam IDLE_S = 2'd0,
               START_S = 2'd1,
               DATA_S = 2'd2,
               STOP_S = 2'd3;
    localparam DATA_MAX_CNT = 3'd7;

    wire baud_tick;
    reg [$clog2(BAUD_CNT_MAX)-1:0] baud_counter;
    reg [1:0] state, next_state;
    reg [2:0] data_counter;
    reg serial_out, serial_out_next;
    reg [7:0] piso;
    reg tx_ready_reg;
    wire tx_begin;

    // BAUD TICK COUNTER
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) baud_counter <= 0;
        else if(tx_begin) baud_counter <= 0;
        else if(baud_tick) baud_counter <= 0;
        else baud_counter <= baud_counter + 1'b1;
    end
    assign baud_tick = (baud_counter == BAUD_CNT_MAX);

    // CLEAN TX-BEGIN
    assign tx_begin = tx_valid && tx_ready && (state == IDLE_S);

    // STATE MACHINE
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) state <= IDLE_S;
        else state <= next_state;
    end

    always @* begin
        next_state = state;
        case(state)
            IDLE_S: if(tx_begin) next_state = START_S;
            START_S: if(baud_tick) next_state = DATA_S;
            DATA_S: if(baud_tick && data_counter == DATA_MAX_CNT) next_state = STOP_S;
            STOP_S: if(baud_tick) next_state = IDLE_S;
        endcase
    end

    // DATA COUNTER
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) data_counter <= 3'd0;
        else if(state == DATA_S && baud_tick) data_counter <= data_counter + 1'b1;
        else if(tx_begin) data_counter <= 3'b0;
    end

    // PARALLEL IN SERIAL OUT
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) piso <= 8'd0;
        else if(tx_begin) piso <= tx_data;
        else if(baud_tick && state==DATA_S) piso <= {1'b0, piso[7:1]};
    end

    // FINAL TXD OUT
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) serial_out <= 1'b1;
        else serial_out <= serial_out_next;
    end
    always @* begin
        case(state)
            IDLE_S: serial_out_next = 1'b1;
            START_S: serial_out_next = 1'b0;
            DATA_S: serial_out_next = piso[0];
            STOP_S: serial_out_next = 1'b1;
        endcase
    end
    assign txd = serial_out;

    // READY SIGNAL
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) tx_ready_reg <= 1'b1;
        else if(tx_begin) tx_ready_reg <= 1'b0;
        else if(state==STOP_S && baud_tick) tx_ready_reg <= 1'b1;
    end
    assign tx_ready = tx_ready_reg;

endmodule