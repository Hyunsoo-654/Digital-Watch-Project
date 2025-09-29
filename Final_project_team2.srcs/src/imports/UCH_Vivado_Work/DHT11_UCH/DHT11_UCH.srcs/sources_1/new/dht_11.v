`timescale 1ns / 1ps

module dht11_controller (
    input        clk,
    input        rst,
    input        start,
    output [7:0] rh_data,
    output [7:0] t_data,
    output       dht11_done,
    output       dht11_valid,  //checksum
    output [2:0] state_led,
    inout        dht11_io
);

    wire w_tick;

    tick_gen_10us U_Tick (
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick)
    );

    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4, 
                DATA_SYNC = 5, DATA_DETECT = 6, STOP = 7;

    reg [2 : 0] c_state, n_state;
    reg [$clog2(1900)-1 : 0] t_cnt_reg, t_cnt_next;
    reg dht11_reg, dht11_next;
    reg io_en_reg, io_en_next;
    reg [39:0] data_reg, data_next;
    reg valid_reg, valid_next;
    reg [5:0] data_cnt_reg, data_cnt_next;
    reg dht11_done_reg, dht11_done_next;

    assign dht11_io = (io_en_reg) ? dht11_reg : 1'bz;
    assign state_led = c_state;
    assign dht11_valid = valid_reg;
    assign dht11_done = dht11_done_reg;
    assign rh_data = data_reg[39:32];
    assign t_data = data_reg[23:16];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= 0;
            t_cnt_reg <= 0;
            dht11_reg <= 1'b1;  //초기값 항상 high로
            io_en_reg <= 1'b1;  //idle에서 항상 출력 모드
            data_reg <= 0;
            valid_reg <= 1'b0;
            data_cnt_reg <= 0;
            dht11_done_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            t_cnt_reg <= t_cnt_next;
            dht11_reg <= dht11_next;
            io_en_reg <= io_en_next;
            data_reg <= data_next;
            valid_reg <= valid_next;
            data_cnt_reg <= data_cnt_next;
            dht11_done_reg <= dht11_done_next;
        end
    end

    always @(*) begin
        n_state    = c_state;
        t_cnt_next = t_cnt_reg;
        dht11_next = dht11_reg;
        io_en_next = io_en_reg;
        data_next  = data_reg;
        valid_next = valid_reg;
        data_cnt_next = data_cnt_reg;
        dht11_done_next = dht11_done_reg;
        case (c_state)
            IDLE: begin
                dht11_next = 1'b1;
                io_en_next = 1'b1;
                valid_next = 1'b0;
                dht11_done_next = 1'b0;
                if (start) begin
                    n_state = START;  //start로 보내고 tick 검사
                end
            end
            START: begin
                if (w_tick) begin
                    dht11_next = 1'b0;
                    if (t_cnt_reg == 1900) begin
                        n_state = WAIT;
                        t_cnt_next = 0;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                //출력 high
                dht11_next = 1'b1;
                if (w_tick) begin
                    if (t_cnt_reg == 2) begin
                        n_state = SYNCL;
                        t_cnt_next = 0;
                        //출력을을 입력으로 전환
                        io_en_next = 1'b0;
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin
                if (w_tick) begin
                    if (dht11_io) begin
                        n_state = SYNCH;
                    end
                end
            end
            SYNCH: begin
                if (w_tick) begin
                    if (!dht11_io) begin
                        n_state = DATA_SYNC;
                    end
                end
            end
            DATA_SYNC: begin
                if (w_tick) begin
                    if (dht11_io) begin
                        n_state = DATA_DETECT;
                    end
                end
            end
            DATA_DETECT: begin  //각자, 1길이 count
                if (w_tick) begin
                    if (!dht11_io) begin
                        // Low pulse 길이가 5보다 길면 '1', 아니면 '0'으로 판단하여 bit_data에 저장
                        if (t_cnt_reg < 5) begin  //data 입력 0 (5보다 작으면)
                            data_next = {data_reg[38:0], 1'b0};     
                        end else begin  //data 입력 1 (5보다 크면)
                            data_next = {data_reg[38:0], 1'b1}; 
                        end

                        if (data_cnt_reg == 39) begin  //state 이동 40비트(데이터 40비트)를 모두 읽었으면
                            data_cnt_next = 0;
                            n_state = STOP;
                            t_cnt_next = 0;
                        end else begin
                            data_cnt_next = data_cnt_reg + 1;
                            n_state = DATA_SYNC;
                            t_cnt_next = 0;
                        end
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
            STOP: begin  //각자
                if (w_tick) begin
                    if (t_cnt_reg == 4) begin
                        n_state = IDLE;
                        dht11_done_next = 1'b1;
                        valid_next = ((data_reg[39:32] + data_reg[31:24] +
                           data_reg[23:16] + data_reg[15:8]) == data_reg[7:0]);
                    end else begin
                        t_cnt_next = t_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

///////////////////////////////////////////////////////////////////////////////////////

module tick_gen_10us (
    input clk,
    input rst,
    output reg o_tick
);
    parameter DIV = 1000;  // 100kHz -> 10usec     (10nsec가 100MHz의 속도)

    reg [$clog2(DIV)-1:0] count;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count  <= 0;
            o_tick <= 0;
        end else if (count == DIV - 1) begin
            count  <= 0;
            o_tick <= 1;
        end else begin
            count  <= count + 1;
            o_tick <= 0;
        end
    end
endmodule



//////////////////////////////////////////// 망한 코드 1 /////////////////////////////////////////////////

// module dht_11_controller_CH (
//     input        clk,
//     input        rst,
//     input        start,
//     output [3:0] state_led,
//     output [7:0] rh_data,
//     output [7:0] t_data,
//     output       dht11_done,
//     output       dht11_valid,  //check sum -> uart의 done
//     inout        dht11_io
// );

//     wire w_tick;

//     tick_gen_10us U_Tick (
//         .clk(clk),
//         .rst(rst),
//         .o_tick(w_tick)
//     );

//     // 18msec, 나머지는 us
//     parameter START_CNT = (1800 + 100), WAIT_CNT = (3-1), DATA_0 = 5,
//               TIME_OUT = 5;

//     localparam IDLE = 0, START = 1, WAIT = 2, SYNC_LOW = 3, SYNC_HIGH = 4,
//                DATA_SYNC = 5, DATA_DETECT = 6, CHECK_SUM = 7, STOP = 8;

//     reg [3:0] c_state, n_state;
//     reg [$clog2(START_CNT)-1:0] t_cnt_reg, t_cnt_next;
//     reg dht11_reg, dht11_next;
//     reg io_en_reg, io_en_next;

//     reg [39:0] data_reg, data_next;
//     reg [39:0] data_buf_reg, data_buf_next;
//     reg valid_reg, valid_next;
//     reg [5:0] bit_counter_reg, bit_counter_next;  // 40bit 셀것
//     reg [15:0] high_width_reg, high_width_next;

//     reg [7:0] t_data_reg, t_data_next, rh_data_reg, rh_data_next;

//     assign dht11_io = (io_en_reg) ? dht11_reg : 1'bz;
//     assign state_led = c_state;
//     assign dht11_done = valid_reg;
//     assign t_data = t_data_reg;
//     assign rh_data = rh_data_reg;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             c_state <= IDLE;
//             t_cnt_reg <= 0;
//             dht11_reg <= 1'b1;
//             io_en_reg <= 1'b1;
//             data_reg <= 0;
//             valid_reg <= 0;
//             bit_counter_reg <= 0;
//             high_width_reg <= 0;
//             data_buf_reg <= 0;
//             t_data_reg <= 0;
//             rh_data_reg <= 0;
//         end else begin
//             c_state <= n_state;
//             t_cnt_reg <= t_cnt_next;
//             dht11_reg <= dht11_next;
//             io_en_reg <= io_en_next;
//             data_reg <= data_next;
//             valid_reg <= valid_next;
//             bit_counter_reg <= bit_counter_next;
//             high_width_reg <= high_width_next;
//             data_buf_reg <= data_buf_next;
//             t_data_reg <= t_data_next;
//             rh_data_reg <= rh_data_next;
//         end
//     end

//     always @(*) begin

//         n_state = c_state;
//         t_cnt_next = t_cnt_reg;
//         dht11_next = dht11_reg;
//         io_en_next = io_en_reg;
//         data_next = data_reg;
//         valid_next = valid_reg;
//         bit_counter_next = bit_counter_reg;
//         high_width_next = high_width_reg;
//         data_buf_next = data_buf_reg;
//         t_data_next = t_data_reg;
//         rh_data_next = rh_data_reg;

//         case (c_state)
//             IDLE: begin
//                 dht11_next = 1'b1;
//                 io_en_next = 1'b1;
//                 valid_next = 0;
//                 if (start) begin
//                     n_state = START;
//                     t_cnt_next = 0;
//                 end
//             end
//             START: begin
//                 if (w_tick) begin
//                     dht11_next = 1'b0;
//                     if (t_cnt_reg == START_CNT) begin
//                         n_state    = WAIT;
//                         t_cnt_next = 0;
//                     end else begin
//                         t_cnt_next = t_cnt_reg + 1;
//                     end
//                 end
//             end
//             WAIT: begin
//                 dht11_next = 1'b1;  // 출력이 high
//                 if (w_tick) begin
//                     if (t_cnt_reg == WAIT_CNT) begin
//                         n_state    = SYNC_LOW;
//                         t_cnt_next = 0;
//                         io_en_next = 1'b0; // 출력을 입력으로 전환 
//                     end else begin
//                         t_cnt_next = t_cnt_reg + 1;
//                     end
//                 end
//             end
//             SYNC_LOW: begin
//                 if (w_tick) begin
//                     if (dht11_io) begin
//                         n_state = SYNC_HIGH;
//                     end
//                 end
//             end
//             SYNC_HIGH: begin
//                 if (w_tick) begin
//                     if (!dht11_io) begin
//                         n_state = DATA_SYNC;
//                     end
//                 end
//             end
//             DATA_SYNC: begin
//                 high_width_next = 0;
//                 if (w_tick) begin
//                     if (dht11_io) begin
//                         n_state = DATA_DETECT;
//                     end
//                 end
//             end
//             DATA_DETECT: begin
//                 if (w_tick) begin  // 1us 마다 실행되는 로직
//                     if (dht11_io == 1'b1) begin // dht_io가 high인 경우 (high pulse 측정 중)
//                         high_width_next = high_width_reg + 1; // high pulse 길이 측정 카운터 증가

//                     end else begin // dht_io가 low인 경우 (high pulse 종료)
//                         data_next = {
//                             data_reg[39:0], (high_width_reg >= DATA_0)
//                         };  // high pulse 길이가 DATA_0보다 길면 '1', 아니면 '0'으로 판단하여 bit_data에 저장
//                         high_width_next = 0; // high pulse 길이 측정 카운터 초기화

//                         if (bit_counter_reg == 39) begin // 40비트(데이터 40비트)를 모두 읽었으면
//                             n_state = CHECK_SUM;  // CHECK_SUM 상태로 이동
//                             bit_counter_next = 0;  // bit_counter 초기화
//                             data_buf_next = data_reg; // bit_data를 bit_buffer에 저장

//                         end else begin // 아직 40비트를 다 읽지 못했으면
//                             n_state = DATA_SYNC; // 다음 비트를 읽기 위해 DATA_S 상태로 이동
//                             bit_counter_next = bit_counter_reg + 1; // bit_counter 증가
//                         end
//                     end
//                 end
//             end
//             CHECK_SUM: begin
//                 if (w_tick) begin
//                     if (data_buf_reg[7:0] == data_buf_reg[39:32] + data_buf_reg[31:24] + data_buf_reg[23:16] + data_buf_reg[15:8]) begin
//                         rh_data_next = data_buf_reg[39:32];
//                         t_data_next  = data_buf_reg[23:16];
//                     end else begin
//                         rh_data_next = 8'h00;
//                         t_data_next  = 8'h00;
//                         valid_next   = 1'b0;
//                     end
//                     n_state = STOP;
//                     t_cnt_next = 0;
//                 end
//             end

//             STOP: begin
//                 if (w_tick) begin
//                     if (t_cnt_reg == TIME_OUT - 1) begin
//                         valid_next = 1;
//                         n_state = IDLE;
//                         t_cnt_next = 0;
//                     end else begin
//                         t_cnt_next = t_cnt_reg + 1;
//                     end
//                 end
//             end

//         endcase
//     end

// endmodule

