`timescale 1ns / 1ps

module fnd_controller_top (
    input        clk,
    input        reset,
    input  [3:0] sw,

    input  [6:0] msec_s,
    input  [5:0] sec_s,
    input  [5:0] min_s,
    input  [4:0] hour_s,
    input  [6:0] msec_r,
    input  [5:0] sec_r,
    input  [5:0] min_r,
    input  [4:0] hour_r,

    input  [9:0] dist,
    input  [7:0] t_data,
    input  [7:0] rh_data,

    output [7:0] fnd_data,
    output [3:0] fnd_com
);

    wire [3:0] w_msec_1, w_msec_10;
    wire [3:0] w_sec_1, w_sec_10;
    wire [3:0] w_min_1, w_min_10;
    wire [3:0] w_hour_1, w_hour_10;

    wire [3:0] w_dist_1, w_dist_10, w_dist_100, w_dist_1000;
    wire [3:0] w_t_1, w_t_10, w_rh_1, w_rh_10;

    wire [3:0] w_bcd_watch, w_bcd_dht11, w_bcd_sr04;
    wire [3:0] w_bcd, w_bcd_Msec_Sec, w_bcd_Min_Hour;
    wire w_oclk;
    wire [2:0] fnd_sel;
    wire [3:0] w_msec_sel;

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    clk_div U_CLK_DIV (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_oclk)
    );

    Comparator U_Comparator (
        .i_msec_sel(w_msec),
        .M_sel(w_msec_sel)
    );

    counter_8 U_Counter_8 (
        .clk(w_oclk),
        .reset(reset),
        .fnd_sel(fnd_sel)
    );

    decoder_2x4 U_Decoder_2x4 (
        .fnd_sel(fnd_sel),
        .fnd_com(fnd_com)
    );

    mux_2x1_watch_stopwatch U_mux_2x1_watch_stopwatch (
        .sel(sw[1]),
        .s_msec(msec_s),
        .s_sec(sec_s),
        .s_min(min_s),
        .s_hour(hour_s),
        .w_msec(msec_r),
        .w_sec(sec_r),
        .w_min(min_r),
        .w_hour(hour_r),
        .o_msec(w_msec),
        .o_sec(w_sec),
        .o_min(w_min),
        .o_hour(w_hour)
    );

    digit_spliter #(
        .BIT_WIDTH(7)
    ) U_DigitSpliter_MSEC (
        .count_data(w_msec),
        .digit_1  (w_msec_1),
        .digit_10 (w_msec_10)
    );

    digit_spliter #(
        .BIT_WIDTH(6)
    ) U_DigitSpliter_SEC (
        .count_data(w_sec),
        .digit_1  (w_sec_1),
        .digit_10 (w_sec_10)
    );

    digit_spliter #(
        .BIT_WIDTH(6)
    ) U_DigitSpliter_MIN (
        .count_data(w_min),
        .digit_1  (w_min_1),
        .digit_10 (w_min_10)
    );

    digit_spliter #(
        .BIT_WIDTH(5)
    ) U_DigitSpliter_HOUR (
        .count_data(w_hour),
        .digit_1  (w_hour_1),
        .digit_10 (w_hour_10)
    );

    ///////////////////////// 센서용 //////////////////////////////////
    digit_spliter_sr04 #(
        .BIT_WIDTH(10)
    ) U_DigitSpliter_SR04 (
        .count_data(dist),
        .digit_1  (w_dist_1),
        .digit_10 (w_dist_10),
        .digit_100(w_dist_100),
        .digit_1000(w_dist_1000)
    );

    digit_spliter #(
        .BIT_WIDTH(8)
    ) U_DigitSpliter_DHT11_T (
        .count_data(t_data),
        .digit_1  (w_t_1),
        .digit_10 (w_t_10)
    );

    digit_spliter #(
        .BIT_WIDTH(8)
    ) U_DigitSpliter_DHT11_RH (
        .count_data(rh_data),
        .digit_1  (w_rh_1),
        .digit_10 (w_rh_10)
    );
    //////////////////////////////////////////////////////////////////

    Mux_8x1 U_MUX_8x1_MSEC_SEC (
        .sel(fnd_sel),
        .x_0(w_msec_1),
        .x_1(w_msec_10),
        .x_2(w_sec_1),
        .x_3(w_sec_10),
        .x_4(4'ha),
        .x_5(4'ha),
        .x_6(w_msec_sel),
        .x_7(4'ha),
        .y  (w_bcd_Msec_Sec)
    );

    Mux_8x1 U_MUX_8x1_MIN_HOUR (
        .sel(fnd_sel),
        .x_0(w_min_1),
        .x_1(w_min_10),
        .x_2(w_hour_1),
        .x_3(w_hour_10),
        .x_4(4'ha),
        .x_5(4'ha),
        .x_6(w_msec_sel),
        .x_7(4'ha),
        .y  (w_bcd_Min_Hour)
    );

    Mux_2x1 U_mux_2x1_SecHour (
        .sel(sw[0]),
        .Msec_Sec(w_bcd_Msec_Sec),
        .Min_Hour(w_bcd_Min_Hour),
        .Mode(w_bcd_watch)
    );

    Mux_4x1 U_MUX_4x1_sr04 (
        .digit_1(w_dist_1),
        .digit_10(w_dist_10),
        .digit_100(w_dist_100),
        .digit_1000(w_dist_1000),
        .sel(fnd_sel),
        .bcd(w_bcd_sr04)
    );

    Mux_4x1 U_MUX_4x1_dht11 (
        .digit_1(w_t_1),
        .digit_10(w_t_10),
        .digit_100(w_rh_1),
        .digit_1000(w_rh_10),
        .sel(fnd_sel),
        .bcd(w_bcd_dht11)
    );


    Mux_4x1_bcd U_Mux_4x1_bcd(
        .sw_bcd(sw[3:2]),
        .bcd_watch(w_bcd_watch),
        .bcd_sr04(w_bcd_sr04),
        .bcd_dht11(w_bcd_dht11),
        .bcd_final(w_bcd)
    );

    bcd U_BCD (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

endmodule


/////////////////////////////////////////////////////////////////////////////////////////////////////////////

module Mux_4x1_bcd (
    input  [1:0] sw_bcd,
    input  [3:0] bcd_watch,
    input  [3:0] bcd_sr04,
    input  [3:0] bcd_dht11,
    output [3:0] bcd_final
);
    reg [3:0] r_bcd;
    assign bcd_final = r_bcd;

    always @(*) begin
        case (sw_bcd)
            2'b00:   r_bcd = bcd_watch;
            2'b01:   r_bcd = bcd_sr04;
            2'b10:   r_bcd = bcd_dht11;
            default: r_bcd = 4'b0000;
        endcase
    end

endmodule

/////////////////////////////////////////////// clk_div //////////////////////////////////////////////////////
//////////////******** Clk divider_1kHz ********////////////// 

module clk_div (
    input  clk,
    input  reset,
    output o_clk
);

    // reg [16:0] r_counter;
    reg [$clog2(100_000) - 1:0] r_counter;
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk     <= 1'b0;
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter <= 17'd0;
                r_clk     <= 1'b1;  // 1kHz 클럭 
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end

endmodule

/////////////////////////////////////////////////////////////

/////////////////******** 4진 Counter ********//////////////// 

module counter_8 (
    input        clk,     // 클럭
    input        reset,   // 비동기 리셋 (active-low)
    output [2:0] fnd_sel  // 2비트 출력
);

    reg [2:0] r_counter;
    assign fnd_sel = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;  // 리셋 시 0
        end else begin
            r_counter <= r_counter + 1;  // 클럭마다 1씩 증가
        end
    end

endmodule

/////////////////////////////////////////////////////////////

/////////////////******** Decoder_2x4 ********/////////////// 

module decoder_2x4 (
    input [1:0] fnd_sel,
    output reg [3:0] fnd_com
);
    always @(fnd_sel) begin
        case (fnd_sel)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end

endmodule
/////////////////////////////////////////////////////////////

///////////////////******** Mux_4x1 ********/////////////////
module Mux_4x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [1:0] sel,
    output [3:0] bcd
);
    // 4:1 mux, always 구문 -> default 설정 안하면 위험함 (Latch)
    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            2'b00:   r_bcd = digit_1;
            2'b01:   r_bcd = digit_10;
            2'b10:   r_bcd = digit_100;
            2'b11:   r_bcd = digit_1000;
            default: r_bcd = 4'd0;
        endcase
    end

    // // assign 문법 (삼항 연산자)
    // assign bcd = (sel == 2'b00) ? digit_1    :
    //              (sel == 2'b01) ? digit_10   :
    //              (sel == 2'b10) ? digit_100  :
    //                               digit_1000;

endmodule
/////////////////////////////////////////////////////////////

/////////////////////////비교기 모듈 추가 ////////////////////////////////////

module Comparator #(
    parameter BIT_WIDTH_MSEC = 7
) (
    input [BIT_WIDTH_MSEC-1:0] i_msec_sel,
    output [3:0] M_sel
);
    assign M_sel = (i_msec_sel < 50) ? 4'he : 4'hf;

endmodule

/////////////////////////////////////////////////////////////

///////////////////******** Mux_8x1 ********/////////////////
module Mux_8x1 (
    input [2:0] sel,
    input [3:0] x_0,
    input [3:0] x_1,
    input [3:0] x_2,
    input [3:0] x_3,
    input [3:0] x_4,
    input [3:0] x_5,
    input [3:0] x_6,
    input [3:0] x_7,
    output reg [3:0] y
);
    always @(*) begin
        case (sel)
            3'b000:  y = x_0;
            3'b001:  y = x_1;
            3'b010:  y = x_2;
            3'b011:  y = x_3;
            3'b100:  y = x_4;
            3'b101:  y = x_5;
            3'b110:  y = x_6;
            3'b111:  y = x_7;
            default: y = 4'b0000;
        endcase
    end
endmodule
/////////////////////////////////////////////////////////////

////////////////******** digit_spliter ********////////////// 

module digit_spliter_sr04  #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] count_data,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);

    assign digit_1    = count_data % 10;
    assign digit_10   = (count_data / 10) % 10;
    assign digit_100  = (count_data / 100) % 10;
    assign digit_1000 = (count_data / 1000) % 10;

endmodule

module digit_spliter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH-1:0] count_data,
    output [          3:0] digit_1,
    output [          3:0] digit_10
);

    assign digit_1  = count_data % 10;
    assign digit_10 = (count_data / 10) % 10;

endmodule

/////////////////////////////////////////////////////////////

/////////////////////******** bcd ********/////////////////// 

module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data
);

    always @(bcd) begin
        case (bcd)
            4'h00:   fnd_data = 8'hC0;
            4'h01:   fnd_data = 8'hF9;
            4'h02:   fnd_data = 8'hA4;
            4'h03:   fnd_data = 8'hB0;
            4'h04:   fnd_data = 8'h99;
            4'h05:   fnd_data = 8'h92;
            4'h06:   fnd_data = 8'h82;
            4'h07:   fnd_data = 8'hF8;
            4'h08:   fnd_data = 8'h80;
            4'h09:   fnd_data = 8'h90;
            default: fnd_data = 8'hFF;  // 모든 segment off
        endcase
    end

endmodule
/////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////

module mux_2x1_watch_stopwatch (
    input sel,
    input [6:0] s_msec,
    input [5:0] s_sec,
    input [5:0] s_min,
    input [4:0] s_hour,
    input [6:0] w_msec,
    input [5:0] w_sec,
    input [5:0] w_min,
    input [4:0] w_hour,
    output reg [6:0] o_msec,
    output reg [5:0] o_sec,
    output reg [5:0] o_min,
    output reg [4:0] o_hour
);
    always @(*) begin
        case (sel)
            1'b0: begin
                o_msec = w_msec;
                o_sec  = w_sec;
                o_min  = w_min;
                o_hour = w_hour;
            end
            1'b1: begin
                o_msec = s_msec;
                o_sec  = s_sec;
                o_min  = s_min;
                o_hour = s_hour;
            end
            default: begin
                o_msec = 0;
                o_sec  = 0;
                o_min  = 0;
                o_hour = 0;
            end
        endcase
    end
endmodule

/////////////////////////////////////////////////////////////

module Mux_2x1 (
    input        sel,
    input  [3:0] Msec_Sec,
    input  [3:0] Min_Hour,
    output [3:0] Mode
);
    assign Mode = (sel == 1'b0) ? Msec_Sec : Min_Hour;

endmodule