`timescale 1ns / 1ps
module sender_uart (
    input clk,
    input rst,
    input rx,
    input [15:0] i_send_data,
    input btn_sender_up,
    input btn_sender_down,
    output tx,
    output tx_done
);
    wire w_tx_full;
    wire w_tx_busy;

    reg [4:0] state, next_state;
    reg [7:0] send_data_reg, send_data_next;
    reg send_reg, send_next;
    reg [5:0] send_cnt_reg, send_cnt_next;

    wire [7:0] temp_ascii[1:0];
    wire [7:0] humi_ascii[1:0];
    wire [31:0] w_send_dist_data;

    reg [7:0] message_buffer [0:31];
    reg [4:0] msg_len_reg;
    reg [4:0] buf_idx, buf_idx_next;
    reg prepare_done, prepare_done_next;
    integer i;

    uart_controller U_UART_CNTL (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_pop(),
        .tx_push_data(send_data_reg),
        .tx_push(send_reg),
        .rx_pop_data(),
        .rx_empty(),
        .rx_done(),
        .tx_full(w_tx_full),
        .tx_done(tx_done),
        .tx_busy(w_tx_busy),
        .tx(tx)
    );

    datatoascii U_dist (
        .i_data(i_send_data),
        .o_data(w_send_dist_data)
    );

    datatoascii2 U_temp (
        .i_data(i_send_data[7:0]),
        .o1(temp_ascii[0]),
        .o2(temp_ascii[1])
    );

    datatoascii2 U_humi (
        .i_data(i_send_data[15:8]),
        .o1(humi_ascii[0]),
        .o2(humi_ascii[1])
    );

    localparam IDLE = 0, PREPARE = 1, LOAD = 2, WAIT = 3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_data_reg <= 0;
            send_reg <= 0;
            send_cnt_reg <= 0;
            state <= IDLE;
            buf_idx <= 0;
            prepare_done <= 0;
        end else begin
            send_data_reg <= send_data_next;
            send_reg <= send_next;
            send_cnt_reg <= send_cnt_next;
            state <= next_state;
            buf_idx <= buf_idx_next;
            prepare_done <= prepare_done_next;
        end
    end

    always @(*) begin
        send_next = 0;
        send_data_next = send_data_reg;
        send_cnt_next = send_cnt_reg;
        buf_idx_next = buf_idx;
        next_state = state;
        prepare_done_next = prepare_done;

        case (state)
            IDLE: begin
                prepare_done_next = 0;
                if (btn_sender_up || btn_sender_down)
                    next_state = PREPARE;
            end

            PREPARE: begin
                if (!prepare_done) begin
                    if (btn_sender_up) begin
                        message_buffer[0]  = "T";
                        message_buffer[1]  = "e";
                        message_buffer[2]  = "m";
                        message_buffer[3]  = "p";
                        message_buffer[4]  = ":";
                        message_buffer[5]  = " ";
                        message_buffer[6]  = temp_ascii[0];
                        message_buffer[7]  = temp_ascii[1];
                        message_buffer[8]  = "'";
                        message_buffer[9]  = "C";
                        message_buffer[10] = ",";
                        message_buffer[11] = " ";
                        message_buffer[12] = "H";
                        message_buffer[13] = "u";
                        message_buffer[14] = "m";
                        message_buffer[15] = "i";
                        message_buffer[16] = "d";
                        message_buffer[17] = ":";
                        message_buffer[18] = " ";
                        message_buffer[19] = humi_ascii[0];
                        message_buffer[20] = humi_ascii[1];
                        message_buffer[21] = "%";
                        message_buffer[22] = "\n";
                        msg_len_reg = 23;
                    end else begin
                        message_buffer[0]  = "D";
                        message_buffer[1]  = "i";
                        message_buffer[2]  = "s";
                        message_buffer[3]  = "t";
                        message_buffer[4]  = "a";
                        message_buffer[5]  = "n";
                        message_buffer[6]  = "c";
                        message_buffer[7]  = "e";
                        message_buffer[8]  = ":";
                        message_buffer[9]  = w_send_dist_data[31:24];
                        message_buffer[10] = w_send_dist_data[23:16];
                        message_buffer[11] = w_send_dist_data[15:8];
                        message_buffer[12] = w_send_dist_data[7:0];
                        message_buffer[13] = "c";
                        message_buffer[14] = "m";
                        message_buffer[15] = "\n";
                        msg_len_reg = 16;
                    end
                    prepare_done_next = 1;
                end else begin
                    next_state = LOAD;
                end
            end

            LOAD: begin
                if (~w_tx_full && ~w_tx_busy && buf_idx < msg_len_reg) begin
                    send_data_next = message_buffer[buf_idx];
                    send_next = 1;
                    next_state = WAIT;
                end
            end

            WAIT: begin
                if (tx_done) begin
                    if (buf_idx + 1 == msg_len_reg)
                        next_state = IDLE;
                    else begin
                        buf_idx_next = buf_idx + 1;
                        next_state = LOAD;
                    end
                end
            end
        endcase
    end
endmodule


module datatoascii (
    input  [15:0] i_data,
    output [31:0] o_data
);
    assign o_data[7:0]   = i_data % 10 + 8'h30;
    assign o_data[15:8]  = (i_data / 10) % 10 + 8'h30;
    assign o_data[23:16] = (i_data / 100) % 10 + 8'h30;
    assign o_data[31:24] = (i_data / 1000) % 10 + 8'h30;
endmodule

module datatoascii2 (
    input  [7:0] i_data,
    output [7:0] o1,
    output [7:0] o2
);
    assign o1 = (i_data / 10) + 8'd48;
    assign o2 = (i_data % 10) + 8'd48;
endmodule

//////////////////////////////////////다른 방법////////////////////////////////////////////////

// module sender_uart_Second (
//     input clk,
//     input rst,
//     input rx,
//     input [13:0] i_send_data,  // 상위 7비트: 온도, 하위 7비트: 습도
//     input btn_start,
//     output tx,
//     output tx_done
// );
//     wire w_start, w_tx_full;
//     wire [31:0] w_temp_ascii, w_humi_ascii;
//     reg [7:0] send_data_reg, send_data_next;
//     reg send_reg, send_next;
//     reg [2:0] send_cnt_reg, send_cnt_next;
//     reg [4:0] str_index_reg, str_index_next;
//     reg [2:0] state, next_state;

//     localparam IDLE         = 0,
//                SEND_STR_T   = 1,
//                SEND_TEMP    = 2,
//                SEND_STR_H   = 3,
//                SEND_HUMI    = 4,
//                DONE         = 5;

//     // 온도: i_send_data[13:7], 습도: i_send_data[6:0]
//     datatoascii_Second temp_converter (
//         .i_data(i_send_data[13:7]),
//         .o_data(w_temp_ascii)
//     );

//     datatoascii_Second humi_converter (
//         .i_data(i_send_data[6:0]),
//         .o_data(w_humi_ascii)
//     );

//     // 버튼 디바운스
//     btn_debounce U_START_BD (
//         .clk(clk),
//         .rst(rst),
//         .i_btn(btn_start),
//         .o_btn(w_start)
//     );

//     // UART 컨트롤러
//     uart_controller U_UART (
//         .clk(clk),
//         .rst(rst),
//         .rx(rx),
//         .rx_pop(),
//         .tx_push_data(send_data_reg),
//         .tx_push(send_reg),
//         .rx_pop_data(),
//         .rx_empty(),
//         .rx_done(),
//         .tx_full(w_tx_full),
//         .tx_done(tx_done),
//         .tx_busy(),
//         .tx(tx)
//     );

//     // 문자열 배열
//     reg [7:0] DIST_STR [0:20];
//     initial begin
//         DIST_STR[0]  = "t";  DIST_STR[1]  = "e";  DIST_STR[2]  = "m";  DIST_STR[3]  = "p";
//         DIST_STR[4]  = "e";  DIST_STR[5]  = "r";  DIST_STR[6]  = "a";  DIST_STR[7]  = "t";
//         DIST_STR[8]  = "e";  DIST_STR[9]  = " ";  DIST_STR[10] = ":";
//         DIST_STR[11] = "h";  DIST_STR[12] = "u";  DIST_STR[13] = "m";  DIST_STR[14] = "i";
//         DIST_STR[15] = "n";  DIST_STR[16] = "i";  DIST_STR[17] = "t";  DIST_STR[18] = "y";
//         DIST_STR[19] = " ";  DIST_STR[20] = ":";
//     end

//     // 상태 레지스터
//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             state <= IDLE;
//             send_data_reg <= 0;
//             send_reg <= 0;
//             send_cnt_reg <= 0;
//             str_index_reg <= 0;
//         end else begin
//             state <= next_state;
//             send_data_reg <= send_data_next;
//             send_reg <= send_next;
//             send_cnt_reg <= send_cnt_next;
//             str_index_reg <= str_index_next;
//         end
//     end

//     // FSM
//     always @(*) begin
//         next_state = state;
//         send_data_next = send_data_reg;
//         send_next = 0;
//         send_cnt_next = send_cnt_reg;
//         str_index_next = str_index_reg;

//         case (state)
//             IDLE: begin
//                 send_cnt_next = 0;
//                 str_index_next = 0;
//                 if (w_start)
//                     next_state = SEND_STR_T;
//             end

//             SEND_STR_T: begin
//                 if (~w_tx_full && str_index_reg < 11) begin
//                     send_data_next = DIST_STR[str_index_reg];
//                     send_next = 1;
//                     str_index_next = str_index_reg + 1;
//                 end else if (str_index_reg == 11) begin
//                     send_cnt_next = 0;
//                     next_state = SEND_TEMP;
//                 end
//             end

//             SEND_TEMP: begin
//                 if (~w_tx_full) begin
//                     case (send_cnt_reg)
//                         0: send_data_next = w_temp_ascii[31:24];
//                         1: send_data_next = w_temp_ascii[23:16];
//                         2: send_data_next = w_temp_ascii[15:8];
//                         3: send_data_next = w_temp_ascii[7:0];
//                     endcase
//                     send_next = 1;
//                     send_cnt_next = send_cnt_reg + 1;
//                     if (send_cnt_reg == 3) begin
//                         str_index_next = 11;
//                         send_cnt_next = 0;
//                         next_state = SEND_STR_H;
//                     end
//                 end
//             end

//             SEND_STR_H: begin
//                 if (~w_tx_full && str_index_reg < 21) begin
//                     send_data_next = DIST_STR[str_index_reg];
//                     send_next = 1;
//                     str_index_next = str_index_reg + 1;
//                 end else if (str_index_reg == 21) begin
//                     send_cnt_next = 0;
//                     next_state = SEND_HUMI;
//                 end
//             end

//             SEND_HUMI: begin
//                 if (~w_tx_full) begin
//                     case (send_cnt_reg)
//                         0: send_data_next = w_humi_ascii[31:24];
//                         1: send_data_next = w_humi_ascii[23:16];
//                         2: send_data_next = w_humi_ascii[15:8];
//                         3: send_data_next = w_humi_ascii[7:0];
//                     endcase
//                     send_next = 1;
//                     send_cnt_next = send_cnt_reg + 1;
//                     if (send_cnt_reg == 3)
//                         next_state = DONE;
//                 end
//             end

//             DONE: begin
//                 next_state = IDLE;
//             end

//             default: next_state = IDLE;
//         endcase
//     end
// endmodule

// module datatoascii_Second(
//     input  [6:0] i_data,
//     output [31:0] o_data
// );
//     assign o_data[7:0]   = i_data % 10 + 8'h30;
//     assign o_data[15:8]  = (i_data / 10) % 10 + 8'h30;
//     assign o_data[23:16] = (i_data / 100) % 10 + 8'h30;
//     assign o_data[31:24] = (i_data / 1000) % 10 + 8'h30;
// endmodule
