`timescale 1ns / 1ps


module TOP_SR04(

    input clk,
    input rst,
    input btn_start,
    input echo, // 센서 출력 echo
    output o_trigger,
    output [7:0] fnd_data,
    output [3:0] fnd_com

);

    wire [9:0] w_distance;
    wire w_btn;

    btn_debounce U_Btn_De (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_start),
        .o_btn(w_btn)
    );

    sr04_controller U_sr04_controller(

        .clk(clk),
        .rst(rst),
        .btn_start(w_btn),
        .echo(echo), // 센서 출력 echo
        .o_trigger(o_trigger),
        .distance(w_distance),
        .dist_done()
    );

    fnd_ctrl U_fnd_ctrl(

        .clk(clk),
        .reset(rst),
        .count_data(w_distance),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );
    
endmodule
