`timescale 1ns / 1ps

module uart_rx (
    input        clk,
    input        rst,
    input        baud_tick,  // baud_tick_x8
    input        rx,
    output       o_rx_done,
    output [7:0] o_dout
);
    localparam IDLE = 0;
    localparam START = 1;
    localparam DATA = 2;
    localparam DATA_READ = 3;
    localparam STOP = 4;

    reg [2:0] state, next_state;
    reg [3:0]
        b_count_reg,
        b_count_next;  // baud tick 이라 tick_count랑 같은거 (Tx)
    reg [3:0] d_count_reg, d_count_next;  // 여기는 data
    reg [7:0] dout_reg, dout_next;
    reg rx_done_reg, rx_done_next;

    assign o_rx_done = rx_done_reg;
    assign o_dout = dout_reg;

    // 동기 상태 레지스터
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            rx_done_reg <= 0;
            dout_reg    <= 0;
            d_count_reg <= 0;
            b_count_reg <= 0;
        end else begin
            state       <= next_state;
            rx_done_reg <= rx_done_next;
            dout_reg    <= dout_next;
            d_count_reg <= d_count_next;
            b_count_reg <= b_count_next;
        end
    end

    // 상태 전이 및 동작 정의
    always @(*) begin
        next_state   = state;
        b_count_next = b_count_reg;
        d_count_next = d_count_reg;
        dout_next    = dout_reg;
        rx_done_next = 0;  // 기본은 비활성

        case (state)

            IDLE: begin
                b_count_next = 0;
                d_count_next = 0;
                rx_done_next = 0;
                if (baud_tick) begin
                    if (rx == 1'b0) begin  // Start bit 감지
                        next_state = START;
                    end
                end
            end

            START: begin
                if (baud_tick) begin
                    if (b_count_reg == 11) begin  // 중앙값에서 샘플
                        next_state   = DATA_READ;
                        b_count_next = 0;
                    end else begin
                        b_count_next = b_count_reg + 1;
                    end
                end
            end

            DATA_READ: begin
                dout_next  = {rx, dout_reg[7:1]};
                next_state = DATA;
            end

            DATA: begin
                if (baud_tick) begin
                    if (b_count_reg == 7) begin  // 8 tick마다 샘플링
                        if (d_count_reg == 7) begin
                            next_state = STOP;
                        end else begin
                            d_count_next = d_count_reg + 1;
                            next_state   = DATA_READ;
                            b_count_next = 0;
                        end
                    end else begin
                        b_count_next = b_count_reg + 1;
                    end
                end
            end

            STOP: begin
                if (baud_tick) begin
                    next_state   = IDLE;
                    rx_done_next = 1;
                end
            end

        endcase
    end

endmodule
