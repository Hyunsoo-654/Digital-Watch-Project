`timescale 1ns / 1ps

module sr04_controller (
    input  clk,
    input  rst,
    input  start,
    input  echo,
    output trig,
    output [15:0] dist,
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

    // start_trigger_propessor U_STT(
    //     .clk(clk),
    //     .rst(rst),
    //     .i_tick(w_tick),
    //     .start(start),
    //     .echo(echo),
    //     .dist(dist),
    //     .dist_done(dist_done),
    //     .o_sr04_trigger(trig)
    // );

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
    input        clk,
    input        rst,
    input        echo,
    input        tick,
    output [15:0] distance,
    output       dist_done
);
    localparam IDLE = 0, MEASURE = 1, DIVIDE = 2, DONE = 3;

    reg [1:0] state_reg, state_next;
    reg [20:0] count_reg, count_next;
    reg [15:0] quotient_reg, quotient_next;
    reg done_reg, done_next;
    reg [7:0] div_cnt_reg, div_cnt_next;
    reg [20:0] dividend_reg, dividend_next;

    assign distance  = quotient_reg;
    assign dist_done = done_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg     <= IDLE;
            count_reg     <= 0;
            quotient_reg  <= 0;
            done_reg      <= 0;
            div_cnt_reg   <= 0;
            dividend_reg  <= 0;
        end else begin
            state_reg     <= state_next;
            count_reg     <= count_next;
            quotient_reg  <= quotient_next;
            done_reg      <= done_next;
            div_cnt_reg   <= div_cnt_next;
            dividend_reg  <= dividend_next;
        end
    end

    always @(*) begin
        state_next     = state_reg;
        count_next     = count_reg;
        quotient_next  = quotient_reg;
        done_next      = 0;
        div_cnt_next   = div_cnt_reg;
        dividend_next  = dividend_reg;

        case (state_reg)
            IDLE: begin
                if (echo) begin
                    state_next = MEASURE;
                    count_next = 0;
                end
            end

            MEASURE: begin
                if (tick) begin
                    count_next = count_reg + 1;
                    if (!echo) begin
                        state_next = DIVIDE;
                        dividend_next = count_reg;
                        div_cnt_next = 0;
                        quotient_next = 0;
                    end
                end
            end

            DIVIDE: begin
                // shift-and-subtract divider for division by 58
                if (dividend_reg >= 58) begin
                    dividend_next = dividend_reg - 58;
                    quotient_next = quotient_reg + 1;
                end else begin
                    state_next = DONE;
                end
            end

            DONE: begin
                done_next = 1;
                state_next = IDLE;
            end
        endcase
    end
endmodule

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


////////////////// 교수 풀이 distance + start_trigger ////////////////////////

// module start_trigger_propessor (
//     input  clk,
//     input  rst,
//     input  i_tick,
//     input  start,
//     input  echo,
//     output [9:0] dist,
//     output dist_done,
//     output o_sr04_trigger  // 10use짜리 ttl(폭)
// );

//     reg [1:0] start_reg, start_next;
//     reg sr04_trigg_reg, sr04_trigg_next;
//     reg [3:0] count_reg, count_next;  // 10개를 세줄 카운터
//     reg [14:0] dist_count_reg, dist_count_next;
//     reg dist_done_reg, dist_done_next;
//     reg [9:0] dist_reg, dist_next;

//     assign o_sr04_trigger = sr04_trigg_reg;
//     assign dist = dist_reg;
//     assign dist_done = dist_done_reg;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             start_reg      <= 0;
//             sr04_trigg_reg <= 0;
//             count_reg      <= 0;
//             dist_count_reg <=0;
//             dist_done_reg  <= 0;
//             dist_reg       <=0;
//         end else begin
//             start_reg      <= start_next;
//             sr04_trigg_reg <= sr04_trigg_next;
//             count_reg      <= count_next;
//             dist_count_reg <= dist_count_next;
//             dist_done_reg <= dist_done_next;
//             dist_reg <= dist_next;
//         end
//     end

//     always @(*) begin
//         start_next      = start_reg;
//         sr04_trigg_next = sr04_trigg_reg;
//         count_next      = count_reg;
//         dist_count_next = dist_count_reg;
//         dist_done_next = dist_done_reg;
//         dist_next = dist_reg;
//         case (start_reg)
//             0: begin
//                 count_next = 0;
//                 sr04_trigg_next = 1'b0;
//                 dist_done_next = 1'b0;
//                 if (start) begin
//                     start_next = 1;
//                     dist_count_next = 0;
//                     dist_next = 0;
//                 end
//             end
//             1: begin    //start trig
//                 if (i_tick) begin
//                     sr04_trigg_next = 1'b1;
//                     if (count_reg == 10) begin
//                         start_next = 2;
//                     end
//                     count_next = count_reg + 1;
//                 end
//             end
//             2: begin // dist count
//                 if(echo & i_tick) begin
//                     dist_count_next = dist_count_reg + 1;
//                     if(dist_count_reg == 57) begin   // 나누기 연산 오래걸리니 58진 카운터 쓰기도 가능
//                         dist_next = dist_reg + 1;
//                         dist_count_next = 0;
//                     end
//                 end else if (~echo) begin
//                     start_next = 3;
//                 end else begin
//                     dist_count_next = dist_count_reg;
//                 end
//             end
//             3: begin // dist call
//                 // dist_count_next = dist_count_reg / 58;
//                 dist_next = dist_reg;
//                 start_next = 0;
//                 dist_done_next = 1'b1;
//             end
//         endcase
//     end

// endmodule
