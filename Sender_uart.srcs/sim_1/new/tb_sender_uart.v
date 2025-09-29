`timescale 1ns / 1ps

module tb_sender_uart ();

    reg clk, rst, start;
    reg [9:0] send_data;
    wire tx, tx_done;

    sender_uart dut (

        .clk(clk),
        .rst(rst),
        .rx(),
        .i_send_data(send_data),
        .btn_start(start),
        .tx(tx),
        .tx_done(tx_done)

    );

    always #5 clk = ~clk;

    initial begin

        #0;
        clk   = 0;
        rst   = 1;
        start = 0;
        send_data = 400;

        #20;
        rst = 0;

        #20;
        start = 1;

        #10;
        start = 0;

        wait(tx_done);

        #200;
        wait(tx_done);

        #200;
        wait(tx_done);

        #200;
        $stop;


    end


endmodule
