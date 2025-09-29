`timescale 1ns / 1ps

module tb_sender ();

     // 테스트 신호 선언
    reg clk;
    reg rst;
    reg start;
    reg rx;
    wire tx;
    wire [7:0] fnd_data;
    wire [3:0] fnd_com;
    wire [2:0] state_led;
    wire dht11_io;

    // 클럭 생성 (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // 인스턴스화
    TOP_dht11 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .rx(rx),
        .tx(tx),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com),
        .state_led(state_led),
        .dht11_io(dht11_io)
    );

    // 버튼 입력 및 초기 조건
    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        start = 0;
        rx = 1;

        #100;
        rst = 0;

        // 버튼 눌렀다가 떼기
        #(100000);
        start = 1;
        #20000;
        start = 0;

        // 두 번째 측정
        #(20000000);
        start = 1;
        #20000;
        start = 0;

        #(50000000);
        $finish;
    end


endmodule

//================================================================
// reg clk, rst, start;
// reg [15:0] send_data;
// wire tx, tx_done;

// sender_uart dut (

//     .clk(clk),
//     .rst(rst),
//     .rx(),
//     .i_send_data(send_data),
//     .btn_start(start),
//     .tx(tx),
//     .tx_done(tx_done)

// );

// always #5 clk = ~clk;

// initial begin

//     #0;
//     clk   = 0;
//     rst   = 1;
//     start = 0;
//     send_data = 2553;

//     #20;
//     rst = 0;

//     #20;
//     start = 1;

//     #10;
//     start = 0;

//     wait(tx_done);

//     #200;
//     wait(tx_done);

//     #200;
//     wait(tx_done);

//     #200;
//     wait(tx_done);

//     #200;
//     $stop;


// end


