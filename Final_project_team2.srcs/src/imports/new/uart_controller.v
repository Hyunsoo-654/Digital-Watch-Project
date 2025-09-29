`timescale 1ns / 1ps

module uart_controller (
    input       clk,
    input       rst,
    input       rx,
    input       rx_pop,
    input [7:0] tx_push_data,
    input       tx_push,

    output [7:0] rx_pop_data,
    output       rx_empty,
    output       rx_done,
    output       tx_full,
    output       tx_done,
    output       tx_busy,
    output       tx
);


    wire w_bd_tick;
    wire w_tx_busy;
    wire [7:0] w_rx_data, w_tx_pop_data;
    wire w_rx_done, w_tx_start;

    assign rx_done = w_rx_done;
    assign rx_data = w_rx_data;
    assign tx_busy = w_tx_busy;

    //////////////////////////////////////////////////////////////////////////////

    baudrate U_BR (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick)
    );
    //////////////////////////////////////////////////////////////////////////////
    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick),
        .rx(rx),
        .o_rx_done(w_rx_done),
        .o_dout(w_rx_data)
    );

    fifo U_FIFO_RX (
        .clk(clk),
        .rst(rst),
        .push(w_rx_done),
        .pop(rx_pop),
        .push_data(w_rx_data),
        .full(),
        .empty(rx_empty),
        .pop_data(rx_pop_data)
    );
    //////////////////////////////////////////////////////////////////////////////
    fifo U_FIFO_TX (
        .clk(clk),
        .rst(rst),
        .push(tx_push),
        .pop(~w_tx_busy),
        .push_data(tx_push_data),
        .full(tx_full),
        .empty(w_tx_start),
        .pop_data(w_tx_pop_data)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .baud_tick(w_bd_tick),
        .start_trigger(~w_tx_start),
        .data_in(w_tx_pop_data),
        .o_tx_done(tx_done),
        .o_tx_busy(w_tx_busy),
        .o_tx(tx)
    );
    //////////////////////////////////////////////////////////////////////////////
endmodule
