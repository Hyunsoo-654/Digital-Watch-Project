`timescale 1ns / 1ps

// module command_to_btn (
//     input clk,
//     input rst,
//     input [7:0] rx_data_command,
//     input rx_done_command,
//     output reg o_clear,
//     output reg o_run,
//     output reg o_stop,
//     output reg o_watch_mode,
//     output reg o_mode,
//     output reg o_up,
//     output reg o_down,
//     output reg o_left,
//     output reg o_right,
//     output reg o_esc
// );

//     reg [3:0] state;
//     parameter IDLE = 4'd1, PROCESS = 4'd2, RUN_STATE = 4'd3, CLEAR_STATE = 4'd4, STOP_STATE = 4'd5,
//               WATCH_MODE_STATE = 4'd6, MODE_STATE = 4'd7, RESET_STATE = 4'd8, 
//               R_STATE = 4'd9, U_STATE = 4'd10, D_STATE = 4'd11, L_STATE = 4'd12, WAIT = 4'd13;

//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             state <= IDLE;
//             o_clear <= 0;
//             o_run <= 0;
//             o_stop <= 0;
//             o_watch_mode <= 0;
//             o_mode <= 0;
//             o_up <= 0;
//             o_down <= 0;
//             o_left <= 0;
//             o_right <= 0;
//             o_esc <= 0;
//         end else begin
//             case (state)
//                 IDLE: begin
//                     if (!rx_done_command) begin
//                         state <= PROCESS;
//                     end
//                 end
//                 PROCESS: begin
//                     case (rx_data_command)
//                         8'h47, 8'h67: state <= RUN_STATE;  //'G', 'g'
//                         8'h43, 8'h63: state <= CLEAR_STATE;  // 'C', 'c'
//                         8'h53, 8'h73: state <= STOP_STATE;  // 'S', 's'

//                         8'h4E, 8'h6E: state <= WATCH_MODE_STATE;  // 'N', 'n'
//                         8'h4D, 8'h6D: state <= MODE_STATE;  // 'M', 'm

//                         8'h52, 8'h72: state <= R_STATE;  // 'R', 'r'
//                         8'h55, 8'h75: state <= U_STATE;  // 'U', 'u'
//                         8'h44, 8'h64: state <= D_STATE;  // 'D', 'd'
//                         8'h4C, 8'h6C: state <= L_STATE;  // 'L', 'l'

//                         8'h1B:   state <= RESET_STATE;  // 'ESC'
//                         default: state <= WAIT;
//                     endcase
//                 end
//                 RUN_STATE: begin
//                     o_run = 1;
//                     state <= WAIT;
//                 end
//                 CLEAR_STATE: begin
//                     o_clear = 1;
//                     state <= WAIT;
//                 end
//                 STOP_STATE: begin
//                     o_stop = 1;
//                     state <= WAIT;
//                 end
//                 WATCH_MODE_STATE: begin
//                     o_watch_mode = 1;
//                     state <= WAIT;
//                 end
//                 MODE_STATE: begin
//                     o_mode = 1;
//                     state <= WAIT;
//                 end
//                 RESET_STATE: begin
//                     o_esc = 1;
//                     state <= WAIT;
//                 end
//                 R_STATE: begin
//                     o_right = 1;
//                     state <= WAIT;
//                 end
//                 U_STATE: begin
//                     o_up = 1;
//                     state <= WAIT;
//                 end
//                 D_STATE: begin
//                     o_down = 1;
//                     state <= WAIT;
//                 end
//                 L_STATE: begin
//                     o_left = 1;
//                     state <= WAIT;
//                 end
//                 WAIT: begin
//                     o_clear <= 0;
//                     o_run <= 0;
//                     o_stop <= 0;
//                     o_watch_mode <= 0;
//                     o_mode <= 0;
//                     o_up <= 0;
//                     o_down <= 0;
//                     o_left <= 0;
//                     o_right <= 0;
//                     o_esc <= 0;
//                     state <= IDLE;
//                 end
//             endcase
//         end
//     end
// endmodule




module command_to_btn (
    input clk,
    input rst,
    input [7:0] rx_data_command,
    input rx_done_command,
    output o_clear,
    output o_run,
    output o_stop,
    output o_watch_mode,
    output o_mode,
    output o_up,
    output o_down,
    output o_left,
    output o_right,
    output o_esc
);
    parameter IDLE = 4'd1, PROCESS = 4'd2, RUN_STATE = 4'd3, CLEAR_STATE = 4'd4, STOP_STATE = 4'd5,
              WATCH_MODE_STATE = 4'd6, MODE_STATE = 4'd7, RESET_STATE = 4'd8, 
              R_STATE = 4'd9, U_STATE = 4'd10, D_STATE = 4'd11, L_STATE = 4'd12, WAIT = 4'd13;

    reg [3:0] n_state, c_state;


    assign o_clear = (c_state == CLEAR_STATE) ? 1 : 0;
    assign o_run = (c_state == RUN_STATE) ? 1 : 0;
    assign o_stop = (c_state == STOP_STATE) ? 1 : 0;

    assign o_watch_mode = (c_state == WATCH_MODE_STATE) ? 1 : 0;
    assign o_mode = (c_state == MODE_STATE) ? 1 : 0;
    assign o_up = (c_state == U_STATE) ? 1 : 0;
    assign o_down = (c_state == D_STATE) ? 1 : 0;
    assign o_left = (c_state == L_STATE) ? 1 : 0;
    assign o_right = (c_state == R_STATE) ? 1 : 0;
    assign o_esc = (c_state == RESET_STATE) ? 1 : 0;

    always @(posedge clk, posedge rst) begin

        if (rst) begin
            c_state <= IDLE;

        end else begin
            c_state <= n_state;

        end
    end

    always @(*) begin
        n_state = c_state;
        case (c_state)
            IDLE: begin
                if (rx_done_command) begin
                    n_state <= PROCESS;
                end
            end
            PROCESS: begin
                case (rx_data_command)
                    8'h47, 8'h67: n_state <= RUN_STATE;  //'G', 'g'
                    8'h43, 8'h63: n_state <= CLEAR_STATE;  // 'C', 'c'
                    8'h53, 8'h73: n_state <= STOP_STATE;  // 'S', 'sn_
                    8'h4E, 8'h6E: n_state <= WATCH_MODE_STATE;  // 'N', 'n'
                    8'h4D, 8'h6D: n_state <= MODE_STATE;  // 'M', 'm'
                    8'h52, 8'h72: n_state <= R_STATE;  // 'R', 'r'
                    8'h55, 8'h75: n_state <= U_STATE;  // 'U', 'u'
                    8'h44, 8'h64: n_state <= D_STATE;  // 'D', 'd'
                    8'h4C, 8'h6C: n_state <= L_STATE;  // 'L', 'l'

                    8'h1B:   n_state <= RESET_STATE;  // 'ESC'
                    default: n_state <= IDLE;
                endcase
            end
            RUN_STATE: begin
                n_state <= IDLE;
            end
            CLEAR_STATE: begin
                n_state <= IDLE;
            end
            STOP_STATE: begin
                n_state <= IDLE;
            end
            WATCH_MODE_STATE: begin
                n_state <= IDLE;
            end
            MODE_STATE: begin
                n_state <= IDLE;
            end
            RESET_STATE: begin
                n_state <= IDLE;
            end
            R_STATE: begin
                n_state <= IDLE;
            end
            U_STATE: begin
                n_state <= IDLE;
            end
            D_STATE: begin
                n_state <= IDLE;
            end
            L_STATE: begin
                n_state <= IDLE;
            end
        endcase
    end




endmodule
