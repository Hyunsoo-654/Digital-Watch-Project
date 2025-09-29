`timescale 1ns / 1ps
module sender_uart (
    input clk,
    input rst,
    input rx,
    input [15:0] i_send_data,  // {humidity, temperature}
    input btn_start,
    output tx,
    output tx_done
);
    wire w_tx_full;
    wire w_tx_busy;

    reg [7:0] send_data_reg, send_data_next;
    reg send_reg, send_next;
    reg [5:0] send_cnt_reg, send_cnt_next;
    reg [4:0] state, next_state;

    wire [7:0] temp_ascii[1:0];
    wire [7:0] humi_ascii[1:0];

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

    Uart_controller U_UART_CNTL (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_pop(),
        .rx_pop_data(),
        .rx_empty(),
        .rx_done(),
        .tx_push_data(send_data_reg),
        .tx_push(send_reg),
        .tx_full(w_tx_full),
        .tx_done(tx_done),
        .tx_busy(w_tx_busy),
        .tx(tx)
    );

    // 상태 정의
    localparam IDLE = 0, LOAD = 1, WAIT = 2;

    // 레지스터
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_data_reg <= 0;
            send_reg <= 0;
            send_cnt_reg <= 0;
            state <= IDLE;
        end else begin
            send_data_reg <= send_data_next;
            send_reg <= send_next;
            send_cnt_reg <= send_cnt_next;
            state <= next_state;
        end
    end

    // 상태 머신
    always @(*) begin
        send_next = 0;
        send_data_next = send_data_reg;
        send_cnt_next = send_cnt_reg;
        next_state = state;

        case (state)
            IDLE: begin
                if (btn_start) begin
                    send_cnt_next = 0;
                    next_state = LOAD;
                end
            end

            LOAD: begin
                if (~w_tx_full && ~w_tx_busy) begin
                    case (send_cnt_reg)
                        0:  send_data_next = "T";
                        1:  send_data_next = "e";
                        2:  send_data_next = "m";
                        3:  send_data_next = "p";
                        4:  send_data_next = ":";
                        5:  send_data_next = " ";
                        6:  send_data_next = temp_ascii[0];
                        7:  send_data_next = temp_ascii[1];
                        8:  send_data_next = "'";
                        9:  send_data_next = "C";
                        10: send_data_next = ",";
                        11: send_data_next = " ";
                        12: send_data_next = "H";
                        13: send_data_next = "u";
                        14: send_data_next = "m";
                        15: send_data_next = "i";
                        16: send_data_next = "d";
                        17: send_data_next = ":";
                        18: send_data_next = " ";
                        19: send_data_next = humi_ascii[0];
                        20: send_data_next = humi_ascii[1];
                        21: send_data_next = "%";
                        22: send_data_next = "\n";
                        default: begin
                            send_data_next = 0;
                            next_state = IDLE;
                        end
                    endcase
                    send_next  = 1;
                    next_state = WAIT;
                end
            end

            WAIT: begin
                if (tx_done) begin
                    send_cnt_next = send_cnt_reg + 1;
                    next_state = (send_cnt_reg == 22) ? IDLE : LOAD;
                end
            end


        endcase
    end
endmodule

// 그대로 유지
module datatoascii2 (
    input  [7:0] i_data,
    output [7:0] o1,
    output [7:0] o2
);
    assign o1 = (i_data / 10) + 8'd48;
    assign o2 = (i_data % 10) + 8'd48;
endmodule


// `timescale 1ns / 1ps
// module sender_uart (

//     input clk,
//     input rst,
//     input rx,
//     input [15:0] i_send_data,
//     input btn_start,
//     output tx,
//     output tx_done
// );
//     wire w_tx_full;
//     wire [31:0] w_send_data;
//     reg c_state, n_state;
//     reg [7:0] send_data_reg, send_data_next;
//     reg send_reg, send_next;
//     reg [2:0] send_cnt_reg, send_cnt_next;



//     //    assign w_start = btn_start;

//     Uart_controller U_UART_CNTL (
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

//     datatoascii U_DtoA (
//         .i_data(i_send_data),
//         .o_data(w_send_data)
//     );

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             c_state       <= 0;
//             send_data_reg <= 0;
//             send_reg      <= 0;
//             send_cnt_reg  <= 0;
//         end else begin
//             c_state       <= n_state;
//             send_data_reg <= send_data_next;
//             send_reg      <= send_next;
//             send_cnt_reg  <= send_cnt_next;
//         end
//     end

//     always @(*) begin
//         n_state        = c_state;
//         send_data_next = send_data_reg;
//         send_next      = send_reg;
//         send_cnt_next  = send_cnt_reg;
//         case (c_state)
//             00: begin
//                 send_cnt_next = 0;
//                 if (btn_start) begin
//                     n_state = 1;
//                 end
//             end
//             01: begin  // send
//                 if (~w_tx_full) begin
//                     send_next = 1;  // send tick 생성.
//                     if (send_cnt_reg < 4) begin
//                         // 상위부터 보내기
//                         case (send_cnt_reg)
//                             2'b00: send_data_next = w_send_data[31:24];
//                             2'b01: send_data_next = w_send_data[23:16];
//                             2'b10: send_data_next = w_send_data[15:8];
//                             2'b11: send_data_next = w_send_data[7:0];
//                         endcase
//                         send_cnt_next = send_cnt_reg + 1;
//                     end else begin
//                         n_state   = 0;
//                         send_next = 0;
//                         send_data_next = 0;
//                     end
//                 end else n_state = c_state;
//             end
//         endcase
//     end
// endmodule

// // decoder, LUT
// module datatoascii (
//     input  [13:0] i_data,
//     output [31:0] o_data
// );
//     assign o_data[7:0]   = i_data % 10 + 8'h30;  // 나머지 + 8'h30
//     assign o_data[15:8]  = (i_data / 10) % 10 + 8'h30;
//     assign o_data[23:16] = (i_data / 100) % 10 + 8'h30;
//     assign o_data[31:24] = (i_data / 1000) % 10 + 8'h30;
// endmodule
