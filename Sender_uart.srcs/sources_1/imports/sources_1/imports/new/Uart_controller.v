`timescale 1ns / 1ps

module Uart_controller (
    input        clk,
    input        rst,
    input        rx,
    input        rx_pop,
    input  [7:0] tx_push_data,
    input        tx_push,
    output [7:0] rx_pop_data,
    output       rx_done,
    output       rx_empty,
    output       tx_full,
    output       tx_done,
    output       tx_busy,
    output       tx
);

    wire w_bd_tick;
    wire w_tx_busy;
    wire [7:0] w_rx_data, w_tx_pop_data;
    wire w_rx_done;
    wire w_tx_start;

    assign tx_busy = w_tx_busy;
    assign rx_done = w_rx_done;
    assign rx_data = w_rx_data;

    FIFO U_FIFO_TX (

        .clk      (clk),
        .rst      (rst),
        .push     (tx_push),              // tx fifo push
        .pop      (~w_tx_busy),
        .push_data(tx_push_data),              // tx fifo push data
        .full     (tx_full),              // tx fifo full
        .empty    (w_tx_start),
        .pop_data (w_tx_pop_data)

    );

    FIFO U_FIFO_RX (

        .clk(clk),
        .rst(rst),
        .push(w_rx_done),
        .pop(rx_pop),  // rx fifo
        .push_data(w_rx_data),
        .full(),  // 필요없음
        .empty(rx_empty),  // rx fifo empty
        .pop_data(rx_pop_data)  // pop data

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

    Uart_Tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick),
        .start(~w_tx_start),
        .din(w_tx_pop_data),
        .o_tx_done(tx_done),
        .o_tx_busy(w_tx_busy),
        .o_tx(tx)
    );

endmodule


