`timescale 1ns / 1ps

module tb_final_module ();

    parameter US = 1000;
    
    reg        clk;
    reg        rst;
    reg  [3:0] sw;
    reg        btn_U;
    reg        btn_D;
    reg        btn_L;
    reg        btn_R;
    reg        rx;
    wire       tx;

    reg        uart_sw;

    reg        echo;
    wire       dht11_data;
    wire       trig;

    reg dht11_io_reg, io_en;

    wire [2:0] state_led;
    wire [3:0] led_out;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;


    Top_final_module dut (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .btn_U(btn_U),
        .btn_D(btn_D),
        .btn_L(btn_L),
        .btn_R(btn_R),
        .rx(rx),
        .tx(tx),

        .uart_sw(uart_sw),

        .echo(echo),
        .dht11_data(dht11_data),
        .trig(trig),

        .state_led(state_led),
        .led_out  (led_out),
        .fnd_com  (fnd_com),
        .fnd_data (fnd_data)
    );

    // Clock generation: 100MHz
    assign dht11_data = (io_en) ? 1'bz : dht11_io_reg;
    always #5 clk = ~clk;

    integer i;
    reg [39:0] dht11_test_data = 40'b10101010_00001111_11000110_00000000_01111111;

    initial begin
        // 초기화
        clk = 0;
        rst = 1;
        sw = 4'b0000;  // 기본: stopwatch
        btn_U = 0;
        btn_D = 0;
        btn_L = 0;
        btn_R = 0;
        uart_sw = 0;
        rx = 1;
        echo = 0;
        dht11_io_reg = 1;
        io_en = 1;

        #100;
        rst = 0;

        // ------------------ [1] Stopwatch 테스트 -------------------
        #50;
        sw = 4'b0000;  // stopwatch mode
        btn_R = 1;  // run
        #20;
        btn_R = 0;

        #500_000;

        btn_L = 1;  // clear
        #20;
        btn_L = 0;

        #500_000;

        // ------------------ [2] SR04 거리 센서 테스트 -------------------
        sw = 4'b0100;  // SR04 mode
        btn_D = 1;     // trigger
        #20;
        btn_D = 0;

        // echo 응답
        #3000;
        echo = 1;
        #7000;
        echo = 0;

        #300_000;

        // ------------------ [3] DHT11 센서 테스트 -------------------
        sw = 4'b1000;  // DHT11 mode
        btn_U = 1;
        #20;
        btn_U = 0;

        // DHT11 프로토콜 응답 시퀀스
        wait (!dht11_io_reg);
        wait (dht11_io_reg);  // start 응답 대기

        #(30 * US);
        dht11_io_reg = 1;
        io_en = 0;
        dht11_io_reg = 0;
        #(80 * US);
        dht11_io_reg = 1;

        // 40비트 전송 (START LOW + 데이터 bits)
        for (i = 0; i < 40; i = i + 1) begin
            dht11_io_reg = 0;
            #(50 * US);  // start of bit
            if (dht11_test_data[39-i] == 0) begin
                dht11_io_reg = 1;
                #(28 * US);
            end else begin
                dht11_io_reg = 1;
                #(70 * US);
            end
        end

        dht11_io_reg = 0;
        #(50 * US);
        io_en = 1;

        // 종료 대기
        #1_000_000;

        $display("Simulation Finished");
        $stop;
    end


endmodule
