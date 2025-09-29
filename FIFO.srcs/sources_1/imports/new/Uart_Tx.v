`timescale 1ns / 1ps

module Uart_Tx (

    input        clk,
    input        rst,
    input        baud_tick,
    input        start,
    input  [7:0] din,
    output       o_tx_done,
    output       o_tx_busy,
    output       o_tx

);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, WAIT = 4;

    reg [2:0] c_state, n_state;  // state
    reg tx_reg, tx_next;
    reg [2:0] data_count_reg, data_count_next;
    reg [3:0] b_cnt_reg, b_cnt_next;
    reg tx_done_reg, tx_done_next;
    reg tx_busy_reg, tx_busy_next;
    reg [7:0] tx_din_reg, tx_din_next;

    assign o_tx = tx_reg;
    assign o_tx_done = tx_done_reg;
    assign o_tx_busy = tx_busy_reg;
    // assign o_tx_done = ((c_state == STOP) & (b_cnt_reg == 7)) ? 1'b1 : 1'b0;

    // state register

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= 0;
            tx_reg <= 1'b1;  // 출력 초기를 HIGH로 설정
            data_count_reg <= 0; // data 비트 전송 반복구조를 위해서 생성.
            b_cnt_reg <= 0;  // baud tick을 0부터 7까지 count.
            tx_done_reg <= 0;  // 데이터 다 보냈다 신호
            tx_busy_reg <= 0;
            tx_din_reg <= 0;
        end else begin
            c_state <= n_state;
            tx_reg <= tx_next;
            data_count_reg <= data_count_next;
            b_cnt_reg <= b_cnt_next;
            tx_done_reg <= tx_done_next;
            tx_busy_reg <= tx_busy_next;
            tx_din_reg <= tx_din_next;
        end
    end

    // 방법 1. State 넘겨서 tick 확인
    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg;
        data_count_next = data_count_reg;
        b_cnt_next = b_cnt_reg;
        tx_done_next = 0;
        tx_busy_next = tx_busy_reg;
        tx_din_next = tx_din_reg;

        case (c_state)

            IDLE: begin
                b_cnt_next = 0;
                data_count_next = 0;
                tx_next = 1'b1;
                tx_done_next = 1'b0;
                tx_busy_next = 1'b0;
                if (start == 1'b1) begin
                    n_state = START;
                    tx_busy_next = 1'b1;
                    tx_din_next = din;
                end
            end

            START: begin
                tx_next = 1'b0;// 블럭도 보면 Tx= 0으로 나가게 설계함
                if (baud_tick == 1'b1) begin
                    if (b_cnt_reg == 8) begin
                        n_state = DATA;
                        data_count_next = 0;
                        b_cnt_next = 0;

                    end else begin
                        b_cnt_next = b_cnt_reg + 1;

                    end

                end
            end

            DATA: begin
                tx_next = tx_din_reg[data_count_reg];
                if (baud_tick == 1'b1) begin
                    if (b_cnt_reg == 3'b111) begin
                        if (data_count_reg == 3'b111) begin
                            n_state = STOP;
                        end
                        b_cnt_next = 0;
                        data_count_next = data_count_reg + 1;
                    end else begin
                        b_cnt_next = b_cnt_reg + 1;
                    end

                end
            end

            STOP: begin
                if (baud_tick == 1'b1) begin

                    tx_next = 1'b1;
                    if (b_cnt_reg == 3'b111) begin
                        n_state = IDLE;
                        tx_busy_next = 1'b0;
                        tx_done_next = 1'b1;

                    end else begin
                        b_cnt_next = b_cnt_reg + 1;

                    end
                end
            end



        endcase
    end

    // 방법 2. flag 처리 -> FF 늘어남
    // always @(*) begin
    //     case (c_state)
    //         IDLE: begin
    //             if (start == 1'b1) begin
    //                 start_flag = 1'b1;

    //             end

    //             if(start_flag & baud_tick) begin
    //                 n_state <= START;
    //             end
    //                .
    //                .
    //                .
    //                .
    //         end 
    //     endcase
    // end
endmodule
