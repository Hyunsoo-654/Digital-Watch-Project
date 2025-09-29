`timescale 1ns / 1ps

module uart_dht11 (
    input        clk,
    input        rst,
    input        start,
    input        rx,
    output       tx,
    output [7:0] fnd_data,
    output [3:0] fnd_com,
    output [2:0] state_led,
    inout        dht11_io
);
    wire [7:0] w_rh, w_t;
    wire w_valid, w_done;

    sender_uart U_sender_uart (

        .clk(clk),
        .rst(rst),
        .rx(rx),
        .i_send_data(w_t * 100 + w_rh),
        .btn_start(w_done),
        .tx(tx),
        .tx_done()
    );

    btn_debounce U_btn_debounce (
        .clk  (clk),
        .rst  (rst),
        .i_btn(start),
        .o_btn(w_start)
    );

    // fnd_ctrl U_fnd_ctrl (

    //     .clk(clk),
    //     .reset(rst),
    //     .rh_data(w_rh),
    //     .t_data(w_t),
    //     .fnd_data(fnd_data),
    //     .fnd_com(fnd_com)
    // );

    dht11_controller U_dht11_controller (

        .clk(clk),
        .rst(rst),
        .start(w_start),
        .rh_data(w_rh),
        .t_data(w_t),
        .dht11_done(w_done),
        .state_led(state_led),
        .dht11_io(dht11_io)
    );

endmodule

