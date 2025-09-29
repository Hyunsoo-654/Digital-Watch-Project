`timescale 1ns / 1ps

module sr04_controller (

    input clk,
    input rst,
    input btn_start,
    input echo,  // 센서 출력 echo
    output o_trigger,
    output [9:0] distance,
    output dist_done
);

    wire w_tick_1mhz;

    // !!!!!!!!!!!!!!!!!!!!!!!!!!hex to ascii 인스턴스 추가!!!!!!!!!!!!!!!!!!!!!!!!!!!!


    distance U_distance (
        .clk(clk),
        .rst(rst),
        .tick(w_tick_1mhz),
        .echo(echo),
        .distance(distance),
        .dist_done(dist_done)
    );

    start_trigger U_start_trigger (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_1mhz),
        .start(btn_start),
        .o_sr04_trigger(o_trigger)
    );

    tick_gen_1Mhz U_tick_gen_1Mhz (
        .clk(clk),
        .rst(rst),
        .o_tick_1mhz(w_tick_1mhz)
    );


endmodule


module distance (
    input        clk,
    input        rst,
    input        tick,
    input        echo,
    output [9:0] distance,
    output       dist_done
);


    localparam IDLE = 0, COUNT = 1, CAL = 2;

    reg [1:0] state_reg, state_next;
    reg [20:0] count_reg, count_next;
    reg [9:0] distance_reg, distance_next;
    reg done_reg, done_next;

    assign distance  = distance_reg;
    assign dist_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg    <= 0;
            count_reg    <= 0;
            distance_reg <= 0;
            done_reg     <= 0;
        end else begin
            state_reg    <= state_next;
            count_reg    <= count_next;
            distance_reg <= distance_next;
            done_reg     <= done_next;
        end
    end

    always @(*) begin
        state_next    = state_reg;
        count_next    = count_reg;
        distance_next = distance_reg;
        done_next     = done_reg;
        case (state_reg)
            IDLE: begin
                done_next  = 1'b0;
                count_next = 0;
                if (echo) begin
                    state_next = COUNT;
                    distance_next = 0;
                end
            end
            COUNT: begin
                distance_next = 0;
                if (tick) begin
                    if (echo == 0) begin
                        state_next = CAL;
                    end
                    count_next = count_reg + 1;
                end
            end
            CAL: begin
                distance_next = count_reg / 58;
                done_next = 1'b1;
                state_next = IDLE;
            end
        endcase
    end

endmodule

//=========================================================================

module start_trigger (
    input  clk,
    input  rst,
    input  i_tick,
    input  start,
    output o_sr04_trigger
);

    reg [3:0] count_reg, count_next;
    reg start_reg, start_next;
    reg sr04_trigg_reg, sr04_trigg_next;

    assign o_sr04_trigger = sr04_trigg_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            start_reg      <= 0;
            sr04_trigg_reg <= 0;
            count_reg      <= 0;
        end else begin
            start_reg      <= start_next;
            sr04_trigg_reg <= sr04_trigg_next;
            count_reg      <= count_next;
        end

    end

    always @(*) begin
        start_next = start_reg;
        sr04_trigg_next = sr04_trigg_reg;
        count_next = count_reg;

        case (start_reg)

            1'b0: begin
                count_next = 0;
                sr04_trigg_next = 1'b0;
                if (start) begin
                    start_next = 1'b1;
                end
            end

            1'b1: begin
                if (i_tick) begin
                    sr04_trigg_next = 1'b1;
                    if (count_reg == 10) begin
                        start_next = 0;
                    end
                    count_next = count_reg + 1;
                end
            end

        endcase
    end

endmodule

//===================================================================

module tick_gen_1Mhz #(
    parameter F_COUNT = 100
) (
    input  clk,
    input  rst,
    output o_tick_1mhz
);
    reg [$clog2(F_COUNT)-1:0] count;
    reg tick;
    assign o_tick_1mhz = tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 1'b0;
            tick  <= 1'b0;
        end else if (count == F_COUNT - 1) begin
            count <= 0;
            tick  <= 1'b1;
        end else begin
            count <= count + 1;
            tick  <= 1'b0;
        end
    end

endmodule
