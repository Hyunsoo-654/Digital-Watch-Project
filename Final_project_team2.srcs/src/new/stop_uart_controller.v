`timescale 1ns / 1ps

module stop_uart_controller (
    input  clk,
    input  rst,
    input  btn_start,
    input  rx,
    output rx_done,             // 얘네 연결
    output [7:0] rx_data,       // 얘네 연결
    output tx
);

    wire w_bd_tick;
    wire w_start;
    wire w_tx_done, w_tx_busy;
    wire [7:0] w_dout;
    wire w_rx_done;

    assign rx_data = w_dout;
    assign rx_done = w_rx_done;

    btn_debounce U_BTN_DB_START (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_start),
        .o_btn(w_start)
    );

    baudrate U_BR (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick)
    );

    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick),
        .rx(rx),
        .o_rx_done(w_rx_done),
        .o_dout(w_dout)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick),
        .start_trigger({w_start | w_rx_done}),
        .data_in(w_dout),
        .o_tx_done(w_tx_done),
        .o_tx_busy(w_tx_busy),
        .o_tx(tx)
    );

endmodule
