`timescale 1ns / 1ps

module uart_tx (
    input clk,
    input rst,
    input baud_tick,
    input start_trigger,
    input [9:0] data_in,
    output o_tx_done,
    output o_tx_busy,
    output o_tx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [2:0] c_state, n_state;
    reg [2:0] data_counter_reg, data_counter_next;
    reg [3:0] b_tick_count_reg, b_tick_count_next;

    reg tx_reg, tx_next;
    reg tx_done_reg, tx_done_next;
    reg tx_busy_reg, tx_busy_next;

    // tx data buffer
    reg [7:0] tx_din_reg, tx_din_next;

    assign o_tx = tx_reg;
    assign o_tx_done = tx_done_reg;
    assign o_tx_busy = tx_busy_reg;
    //assign o_tx_done = ((c_state == STOP) & (b_tick_count_reg == 7)) ? 1'b1 : 1'b0 ;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state          <= 0;
            tx_reg           <= 1'b1;  // 출력 초기를 High로 
            data_counter_reg <= 0;  // data bit 전송 반복 구조를 위해
            b_tick_count_reg <= 0;  // baud tick
            tx_done_reg      <= 0;
            tx_busy_reg      <= 0;
            tx_din_reg       <= 0;
        end else begin
            c_state          <= n_state;
            tx_reg           <= tx_next;
            data_counter_reg <= data_counter_next;
            b_tick_count_reg <= b_tick_count_next;
            tx_done_reg      <= tx_done_next;
            tx_busy_reg      <= tx_busy_next;
            tx_din_reg       <= tx_din_next;
        end
    end

    // next state CL
    always @(*) begin

        n_state           = c_state;
        tx_next           = tx_reg;
        data_counter_next = data_counter_reg;
        b_tick_count_next = b_tick_count_reg;
        tx_done_next      = 0;  // 혹시 모르니까 0으로로
        tx_busy_next      = tx_busy_reg;
        tx_din_next       = tx_din_reg;

        case (c_state)
            IDLE: begin
                b_tick_count_next = 0;
                data_counter_next = 0;
                tx_next = 1'b1;
                tx_done_next = 1'b0;
                tx_busy_next = 1'b0;
                if (start_trigger == 1'b1) begin
                    n_state = START;
                    tx_busy_next = 1'b1;
                    tx_din_next = data_in;
                end
            end

            START: begin
                if (baud_tick == 1'b1) begin
                    tx_next = 1'b0;
                    if (b_tick_count_reg == 8) begin
                        n_state = DATA;
                        data_counter_next = 0;
                        b_tick_count_next = 0;
                    end else begin
                        b_tick_count_next = b_tick_count_reg + 1;
                    end
                end
            end

            DATA: begin
                tx_next = tx_din_reg[data_counter_reg];
                if (baud_tick == 1'b1) begin
                    if (b_tick_count_reg == 3'b111) begin
                        if (data_counter_reg == 3'b111) begin
                            n_state = STOP;
                        end
                        b_tick_count_next = 0;
                        data_counter_next = data_counter_reg + 1;
                    end else begin
                        b_tick_count_next = b_tick_count_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (baud_tick == 1'b1) begin
                    if (b_tick_count_reg == 3'b111) begin
                        n_state = IDLE;
                        tx_done_next = 1'b1;
                        tx_busy_next = 1'b0;
                    end
                    b_tick_count_next = b_tick_count_reg + 1;
                end
            end

        endcase

    end

endmodule
