`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////
///////////////////////***** fnd_controllr *****//////////////////////////
//////////////////////////////////////////////////////////////////////////

module fnd (
    input        clk,
    input        reset,
    input        sw,
    input  [6:0] msec,
    input  [5:0] sec,
    input  [5:0] min,
    input  [4:0] hour,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);

    wire [3:0] w_msec_1, w_msec_10, w_sec_1, w_sec_10;
    wire [3:0] w_min_1, w_min_10, w_hour_1, w_hour_10;
    wire [3:0] w_bcd_sec, w_bcd_hour, w_bcd_final;
    wire w_oclk;
    wire [2:0] fnd_sel;
    wire [3:0] w_dot;

    dot_compare U_dot_compare(
        .dot_time(msec),
        .dot(w_dot)
    );

    clk_div U_CLK_DIV (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_oclk)
    );

    // counter_4 U_Counter_4 (
    //     .clk(w_oclk),
    //     .reset(reset),
    //     .fnd_sel(fnd_sel)
    // );

    counter_8 U_counter_8(
        .clk(w_oclk),     
        .reset(reset),   
        .fnd_sel(fnd_sel)  
    );

    decoder_2x4 U_Decoder_2x4 (
        .fnd_sel(fnd_sel),
        .fnd_com(fnd_com)
    );

    digit_spliter #(
        .BIT_WIDTH(7)
    ) U_digit_spliter_msec (
        .time_data(msec),
        .digit_1  (w_msec_1),
        .digit_10 (w_msec_10)
    );

    digit_spliter #(
        .BIT_WIDTH(6)
    ) U_digit_spliter_sec (
        .time_data(sec),
        .digit_1  (w_sec_1),
        .digit_10 (w_sec_10)
    );

    digit_spliter #(
        .BIT_WIDTH(6)
    ) U_digit_spliter_min (
        .time_data(min),
        .digit_1  (w_min_1),
        .digit_10 (w_min_10)
    );

    digit_spliter #(
        .BIT_WIDTH(5)
    ) U_digit_spliter_hour (
        .time_data(hour),
        .digit_1  (w_hour_1),
        .digit_10 (w_hour_10)
    );

    Mux_8x1 U_MUX_8x1 (
        .digit_1(w_msec_1),
        .digit_10(w_msec_10),
        .digit_100(w_sec_1),
        .digit_1000(w_sec_10),
        .dc1(4'hA),
        .dc2(4'hA),
        .d_on(w_dot),
        .dc3(4'hA),
        .sel(fnd_sel),
        .bcd(w_bcd_sec)
    );

    Mux_8x1 U_MUX_8x1_2 (
        .digit_1(w_min_1),
        .digit_10(w_min_10),
        .digit_100(w_hour_1),
        .digit_1000(w_hour_10),
        .dc1(4'hA),
        .dc2(4'hA),
        .d_on(w_dot),
        .dc3(4'hA),
        .sel(fnd_sel),
        .bcd(w_bcd_hour)
    );

    mux_2x1 U_mux_2X1 (
        .sec    (w_bcd_sec),   // 입력 0
        .hour   (w_bcd_hour),  // 입력 1
        .sel    (sw),          // 선택 신호
        .bcd_out(w_bcd_final)  // 출력
    );

    bcd U_BCD (
        .bcd(w_bcd_final),
        .fnd_data(fnd_data)
    );



endmodule
//////////////////////////////////////////////////////////////////////////
//************************************************************************
//////////////////////////////////////////////////////////////////////////

//////////////******** 1비트 비교기 ********//////////////

module dot_compare (
    input  [6:0] dot_time,
    output [3:0] dot
);

    assign dot = (dot_time >= 7'd50) ? 4'hE : 4'hA;

endmodule

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

// module counter_4 (
//     input        clk,     // 클럭
//     input        reset,   // 비동기 리셋 (active-low)
//     output [1:0] fnd_sel  // 2비트 출력
// );

//     reg [1:0] r_counter;
//     assign fnd_sel = r_counter;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             r_counter <= 2'b00;  // 리셋 시 0
//         end else begin
//             r_counter <= r_counter + 2'b01;  // 클럭마다 1씩 증가
//         end
//     end

// endmodule

/////////////////////////////////////////////////////////////

/////////////////******** 8진 Counter ********//////////////// 

module counter_8 (
    input        clk,     
    input        reset,   
    output [2:0] fnd_sel  
);

    reg [2:0] r_counter;
    assign fnd_sel = r_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_counter <= 3'b000;  
        end else begin
            if (r_counter == 3'b111)  
                r_counter <= 3'b000;  
            else
                r_counter <= r_counter + 1;  
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
module Mux_8x1 (
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [3:0] dc1,
    input  [3:0] dc2,
    input  [3:0] dc3,
    input  [3:0] d_on,
    input  [2:0] sel,
    output [3:0] bcd
);
    // 4:1 mux, always 구문 -> default 설정 안하면 위험함 (Latch)
    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    always @(*) begin
        case (sel)
            3'b000:   r_bcd = digit_1;
            3'b001:   r_bcd = digit_10;
            3'b010:   r_bcd = digit_100;
            3'b011:   r_bcd = digit_1000;
            3'b100:   r_bcd = dc1;
            3'b101:   r_bcd = dc2;
            3'b110:   r_bcd = d_on;
            3'b111:   r_bcd = dc3;
            default: r_bcd = 4'bx;
        endcase
    end

    // // assign 문법 (삼항 연산자)
    // assign bcd = (sel == 2'b00) ? digit_1    :
    //              (sel == 2'b01) ? digit_10   :
    //              (sel == 2'b10) ? digit_100  :
    //                               digit_1000;

endmodule
/////////////////////////////////////////////////////////////

module mux_2x1 (
    input  [3:0] sec,     // 입력 0
    input  [3:0] hour,    // 입력 1
    input        sel,     // 선택 신호
    output [3:0] bcd_out  // 출력
);

    assign bcd_out = (sel == 1'b0) ? sec : hour;

endmodule


////////////////******** digit_spliter ********////////////// 

module digit_spliter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH - 1 : 0] time_data,
    output [              3:0] digit_1,
    output [              3:0] digit_10

);

    assign digit_1  = time_data % 10;
    assign digit_10 = (time_data / 10) % 10;

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
            4'hA:    fnd_data = 8'hFF;
            4'hB:    fnd_data = 8'hFF;
            4'hC:    fnd_data = 8'hFF;
            4'hD:    fnd_data = 8'hFF;
            4'hE:    fnd_data = 8'h7F;
            4'hF:    fnd_data = 8'hFF;
            default: fnd_data = 8'hFF;  // 모든 segment off
        endcase
    end

endmodule
/////////////////////////////////////////////////////////////
