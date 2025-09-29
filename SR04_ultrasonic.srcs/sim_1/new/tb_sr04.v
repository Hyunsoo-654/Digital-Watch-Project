`timescale 1ns / 1ps

module sr04_controller (
    input  clk,
    input  rst,
    input  start,
    input  echo,
    output trig,
    output [9:0] dist,
    output dist_done
);

    wire w_tick;

    distance_calculator U_Dis_Cal(
    .clk(clk),      
    .rst(rst),
    .echo(echo),
    .tick(w_tick),     
    .distance(dist),
    .dist_done(dist_done)
    );

    start_trigger U_Start_Trigger(
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick),
        .start(start),
        .o_sr04_trigger(trig) 
    );

    tick_gen_sr04 #(
        .F_COUNT(100)
    ) U_Tick_Gen(
        .clk(clk),
        .rst(rst),
        .o_tick_1mhz(w_tick)
    );

endmodule

/////////////////////////////////////////////////////////////////////////////

module distance_calculator (
    input        clk,       // 100MHz clock
    input        rst,
    input        echo,
    input        tick,      // 1us tick
    output [9:0] distance,
    output       dist_done
);

    localparam IDLE = 0, COUNT = 1, CAL = 2;

    reg [1:0] state_reg, state_next;
    reg [20:0] count_reg, count_next;
    reg [9:0] distance_reg, distance_next;
    reg done_reg, done_next;

    assign distance  = distance_reg;
    assign dist_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg    <= 0;
            count_reg    <= 0;
            distance_reg <= 0;
            done_reg     <= 0;
        end else begin
            state_reg    <= state_next;
            count_reg    <= count_next;
            distance_reg <= distance_next;
            done_reg     <= done_next;
        end
    end

    always @(*) begin
        state_next    = state_reg;
        count_next    = count_reg;
        distance_next = distance_reg;
        done_next     = done_reg;
        case (state_reg)
            IDLE: begin
                done_next  = 1'b0;
                count_next = 0;
                if (echo) begin
                    state_next = COUNT;
                    distance_next = 0;
                end
            end
            COUNT: begin
                distance_next = 0;
                if (tick) begin
                    if (echo == 0) begin
                        state_next = CAL;
                    end
                    count_next = count_reg + 1;
                end
            end
            CAL: begin
                distance_next = count_reg / 58;
                done_next = 1'b1;
                state_next = IDLE;
            end
        endcase
    end

    ///////////////////////////////////////// 혁진씨 //////////////////////////////////////

    // reg echo_reg, echo_prev;
    // reg [19:0] count_reg;  // 20bit면 1,000,000us (1초)까지 측정 가능
    // reg [19:0] result_reg;
    // reg done_reg;

    // assign dist_done = done_reg;

    // // ECHO rising/falling edge detection
    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         echo_reg  <= 0;
    //         echo_prev <= 0;
    //     end else begin
    //         echo_prev <= echo_reg;
    //         echo_reg  <= echo;
    //     end
    // end

    // wire rising_edge  = (echo_reg == 1 && echo_prev == 0);
    // wire falling_edge = (echo_reg == 0 && echo_prev == 1);

    // // 거리 측정 FSM
    // localparam IDLE = 2'b00, MEASURE = 2'b01, DONE = 2'b10;
    // reg [1:0] state, next_state;

    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         state <= IDLE;
    //     end else begin
    //         state <= next_state;
    //     end
    // end

    // // 분기 조건
    // always @(*) begin
    //     next_state = state;
    //     case (state)
    //         IDLE:    if (rising_edge) next_state = MEASURE;
    //         MEASURE: if (falling_edge) next_state = DONE;
    //         DONE:    next_state = IDLE;
    //     endcase
    // end

    // // output 
    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         count_reg <= 0;
    //         result_reg <= 0;
    //         done_reg <= 0;
    //         distance <= 0;
    //     end else begin
    //         case (state)
    //             IDLE: begin
    //                 count_reg <= 0;
    //                 done_reg <= 0;
    //             end
    //             MEASURE: begin
    //                 count_reg <= count_reg + 1;
    //             end
    //             DONE: begin
    //                 result_reg <= count_reg;
    //                 distance <= count_reg / 58;  // 단위: cm
    //                 done_reg <= 1;
    //             end
    //         endcase
    //     end
    // end

    /////////////////////////////////////// 내꺼 원본 ////////////////////////////////////

    // parameter IDLE = 2'd0,
    //           MEASURE = 2'd1,
    //           DONE = 2'd2;

    // reg [1:0] state_reg, next_state;
    // reg [15:0] duration_reg, duration_next;
    // reg [9:0] dist_reg, dist_next;
    // reg done_reg, done_next;

    // assign distance  = dist_reg;
    // assign dist_done = done_reg;

    //  // FSM 상태 전이
    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         state_reg <= IDLE; 
    //         duration_reg <= 0;
    //         done_reg <= 0;
    //         dist_reg <= 0;
    //     end else begin
    //         state_reg <= next_state;
    //         duration_reg <= duration_next;
    //         done_reg <= done_next;
    //         dist_reg <= dist_next;
    //     end 
    // end

    // // 거리 계산
    // always @(*) begin
    //     next_state     = state_reg;
    //     duration_next  = duration_reg;
    //     done_next      = 0;
    //     dist_next      = dist_reg;

    //     case (state_reg)
    //         IDLE: begin
    //             duration_next = 0;
    //             dist_next = 0;
    //             done_next = 0;
    //             if (echo) next_state = MEASURE;
    //         end

    //         MEASURE: begin
    //             if (tick) duration_next = duration_reg + 1;
    //             if (!echo) next_state = DONE;
    //         end

    //         DONE: begin
    //             dist_next = duration_reg / 58;
    //             done_next = 1;
    //             next_state = IDLE;
    //         end
    //     endcase
    // end

endmodule

/////////////////////////////////////////////////////////////////////////////

module start_trigger (
    input  clk,
    input  rst,
    input  i_tick,
    input  start,
    output o_sr04_trigger  // 10use짜리 ttl(폭)
);

    reg start_reg, start_next;
    reg sr04_trigg_reg, sr04_trigg_next;
    reg [3:0] count_reg, count_next;  // 10개를 세줄 카운터터

    assign o_sr04_trigger = sr04_trigg_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            start_reg      <= 0;
            sr04_trigg_reg <= 0;
            count_reg      <= 0;
        end else begin
            start_reg      <= start_next;
            sr04_trigg_reg <= sr04_trigg_next;
            count_reg      <= count_next;
        end
    end

    always @(*) begin
        start_next      = start_reg;
        sr04_trigg_next = sr04_trigg_reg;
        count_next      = count_reg;
        case (start_reg)
            0: begin
                count_next = 0;
                sr04_trigg_next = 1'b0;
                if (start) begin
                    start_next = 1;
                end
            end
            1: begin
                if (i_tick) begin
                    sr04_trigg_next = 1'b1;
                    if (count_reg == 10) begin
                        start_next = 0;
                    end
                    count_next = count_reg + 1;
                end
            end
        endcase
    end

endmodule

/////////////////////////////////////////////////////////////////////////////

module tick_gen_sr04 #(
    parameter F_COUNT = 100
) (
    input  clk,
    input  rst,
    output o_tick_1mhz
);
    reg [$clog2(F_COUNT)-1:0] count;
    reg tick;
    assign o_tick_1mhz = tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 1'b0;
            tick  <= 1'b0;
        end else if (count == F_COUNT - 1) begin
            count <= 0;
            tick  <= 1'b1;
        end else begin
            count <= count + 1;
            tick  <= 1'b0;
        end
    end

endmodule

/////////////////////////////////////////////////////////////////////////////
