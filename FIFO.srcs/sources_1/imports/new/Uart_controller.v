`timescale 1ns / 1ps

module Uart_controller (
    input        clk,
    input        rst,
    input        btn_start,
    input        rx,
    input  [7:0] tx_din,
    output       rx_done,    
    output [7:0] rx_data,    
    output       tx_done,
    output tx_busy,
    output       tx
);

    wire w_bd_tick;
    wire w_start;
    wire w_tx_busy;
    wire [7:0] w_rx_data, w_rx_pop_data, w_tx_pop_data;
    wire w_rx_done;
    wire w_tx_full;
    wire w_rx_empty;
    wire w_tx_start;

    assign tx_busy = w_tx_busy;
    assign rx_done = w_rx_done;
    assign rx_data = w_rx_data;

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

    Uart_Rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .b_tick(w_bd_tick),
        .rx(rx),
        .o_rx_done(w_rx_done),
        .o_dout(w_rx_data)
    );

    FIFO U_FIFO_RX (

        .clk(clk),
        .rst(rst),
        .push(w_rx_done),
        .pop(~w_tx_full),
        .push_data(w_rx_data),
        .full(),
        .empty(w_rx_empty),
        .pop_data(w_rx_pop_data)

    );

    FIFO U_FIFO_TX (

        .clk(clk),
        .rst(rst),
        .push(~w_rx_empty),
        .pop(~w_tx_busy),
        .push_data(w_rx_pop_data),
        .full(w_tx_full),
        .empty(w_tx_start),
        .pop_data(w_tx_pop_data)

    );

    Uart_Tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick),
        .start(w_start | (~w_tx_start)),
        .din(w_tx_pop_data),
        .o_tx_done(tx_done),
        .o_tx_busy(w_tx_busy),
        .o_tx(tx)
    );

endmodule
