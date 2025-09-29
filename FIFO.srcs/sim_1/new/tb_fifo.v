`timescale 1ns / 1ps

module tb_fifo ();

    reg clk, rst, rx, start;
    wire tx;

    reg [7:0] tx_din, tx_data, send_data;

    wire [7:0] rx_data;
    wire tx_done, rx_done, tx_busy;

    Uart_controller U_UART (
        .clk(clk),
        .rst(rst),
        .btn_start(start),
        .rx(rx),
        .tx_din(tx_data),
        .tx_done(tx_done),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .tx_busy(tx_busy),
        .tx(tx)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        start = 0;
        rx = 1;
        #20;
        rst = 0;

        #100;
        start = 1'b1;
        #10000;
        start = 1'b0;
        #2000000;

        // 3,6 보냄
        rx = 0;  // start
        #(10416 * 10);  // 1 % 9600
        rx = 1;  //d0
        #(10416 * 10);  // 1 % 9600
        rx = 0;
        #(10416 * 10);  // 1 % 9600
        rx = 0;
        #(10416 * 10);  // 1 % 9600
        rx = 0;
        #(10416 * 10);  // 1 % 9600
        rx = 1;
        #(10416 * 10);  // 1 % 9600
        rx = 1;
        #(10416 * 10);  // 1 % 9600
        rx = 0;
        #(10416 * 10);  // 1 % 9600
        rx = 0;  // d7
        #(10416 * 10);  // 1 % 9600
        rx = 1;  // stop

        // #2000000;
        // $stop;


        wait (tx_done);  // tx_done 값까지 wait
        #10;
        // 검증 Test
        send_data_to_rx(8'h32);
        wait_for_rx();


        $stop;

    end

    // rx로 데이터 전송송
    integer i;
    task send_data_to_rx(input [7:0] send_data);
        begin

            // uart rx start condition
            rx = 0;
            #(10416 * 10);

            // rx data lsb transfer
            for (i = 0; i < 8; i = i + 1) begin
                rx = send_data[i];
                #(10416 * 10);
            end

            rx = 1;
            #(10416 * 10);
            $display("send_data = %h", send_data);
        end
    endtask

    // rx : 수신 완료시 검사.
    task wait_for_rx();
        begin
            wait (rx_done);
            if (rx_data == send_data) begin
                // pass
                $display("PASS!!!, rx_data = %h", rx_data);
            end else begin
                // fail
                $display("FAIL~~~, rx_data = %h", rx_data);
            end
        end
    endtask



endmodule
