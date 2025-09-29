`timescale 1ns / 1ps

module tb_distance ();

    reg clk;
    reg rst;
    reg echo;
    reg i_tick;

    wire [9:0] distance;
    wire       dist_done;

    // DUT 인스턴스
    distance uut (
        .clk(clk),
        .rst(rst),
        .i_tick(i_tick),
        .echo(echo),
        .distance(distance),
        .dist_done(dist_done)
    );

    // 100MHz 클럭 생성 (10ns 주기)
    always #5 clk = ~clk;

    // 1MHz tick 생성기 (100 클럭마다 1 tick = 1μs)
    reg [6:0] tick_cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_cnt <= 0;
            i_tick   <= 0;
        end else begin
            if (tick_cnt == 99) begin
                tick_cnt <= 0;
                i_tick   <= 1;
            end else begin
                tick_cnt <= tick_cnt + 1;
                i_tick   <= 0;
            end
        end
    end

    initial begin
        // 초기화
        clk  = 0;
        rst  = 1;
        echo = 0;

        #100;  // 1us
        rst = 0;

        // echo HIGH → 580us
        #1000;  // 1us 안정화
        echo = 1;
        #(5800 * 10);  // 58us 유지
        echo = 0;
        #1000;
        echo = 1;
        #(5800 * 10);  // 58us 유지
        echo = 0;
        #1000;


        #1000;
        $stop;
    end

endmodule
