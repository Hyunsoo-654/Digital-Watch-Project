`timescale 1ns / 1ps

module fnd_ctrl (

    input        clk,
    input        reset,
    // input        valid,
    input  [7:0] rh_data,
    input  [7:0] t_data,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);

    wire [3:0] w_bcd;
    wire w_oclk;
    wire [1:0] fnd_sel;
    wire [3:0] w_rh10,w_rh1, w_t10,w_t1;

    // reg  [15:0] display_data;
    // always @(posedge clk or posedge reset) begin
    //     if (reset) begin
    //         display_data <= 0;
    //     end else if (valid) begin
    //         display_data <= {rh_data, t_data};
    //     end
    // end


    clk_div U_clk_div (
        .clk  (clk),
        .reset(reset),
        .o_clk(w_oclk)
    );

    counter_4 U_counter_4 (

        .clk(w_oclk),
        .reset(reset),
        .fnd_sel(fnd_sel)

    );

    decoder_2x4 U_decoder (
        .fnd_sel(fnd_sel),
        .fnd_com(fnd_com)
    );

    digit_spliter #(
        .BIT_WIDTH(8)
    ) U_ds_rh(
        .data(rh_data),
        .digit_1(w_rh1),
        .digit_10(w_rh10)

    );

    digit_spliter #(
        .BIT_WIDTH(8)
    ) U_ds_t(
        .data(t_data),
        .digit_1(w_t1),
        .digit_10(w_t10)

    );

    mux_4x1 U_mux (

        .digit_1(w_rh1),
        .digit_10(w_rh10),
        .digit_100(w_t1),
        .digit_1000(w_t10),
        .sel(fnd_sel),
        .bcd(w_bcd)

    );

    bcd U_bcd (

        .bcd(w_bcd),
        .fnd_data(fnd_data)

    );

endmodule

//============================================================================

module clk_div (

    input  clk,
    input  reset,
    output o_clk
);
    //clk 100_000_000 -> 1Hz, r_counter = 100_000 -> 1kHz
    reg [$clog2(100_000) - 1 : 0] r_counter;  // = reg [16:0] r_counter; -1은 0부터 계산하기위해.
    reg r_clk;
    assign o_clk = r_clk;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
            r_clk <= 1'b0; // 신호같은 것은 비트수로 정의하는 것이 좋음
        end else begin
            if (r_counter == 100_000 - 1) begin
                r_counter <= 0;
                r_clk = 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end

endmodule

//============================================================================
// 비동기식 : 독립적으로 작동, 동기식 : 특정 조건에서 작동
// 비동기식 카운터 (posedge clk, posedge reset) = (posedge clk or posedge reset)

module counter_4 (

    input clk,
    input reset,
    output [1:0] fnd_sel

);

    reg [1:0] r_counter;
    assign fnd_sel = r_counter;

    // posedge : positive edge(상승 엣지에서만 동작하도록 함)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0; // "<=" : non-block(일반적으로 posedge, 동기논리, 클럭 끝에 대입하는연산자), "=" : block(일반적으로 조합논리)
        end else begin
            r_counter <= r_counter + 1;
        end
    end

endmodule

//============================================================================

module decoder_2x4 (

    input      [1:0] fnd_sel,
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

//============================================================================

module mux_4x1 (

    // mux는 입력과 출력의 비트 수는 동일하게
    // mux의 select는 2비트 -> 2비트로 4가지 표현 ㄱㄴ
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [1:0] sel,
    output [3:0] bcd

);
    // always 출력 -> reg type
    reg [3:0] r_bcd;
    assign bcd = r_bcd;

    // '*' 모두, 'sel' 써도 됨 -> 상황에 따라 다름, 별이면 안되는 경우가 있음
    always @(*) begin
        case (sel)
            2'b00:   r_bcd = digit_1;
            2'b01:   r_bcd = digit_10;
            2'b10:   r_bcd = digit_100;
            2'b11:   r_bcd = digit_1000;
            default: r_bcd = 4'd0;
        endcase
    end

endmodule

//============================================================================

module digit_spliter #(
    parameter BIT_WIDTH = 7
) (
    input  [BIT_WIDTH - 1 : 0] data,
    output [              3:0] digit_1,
    output [              3:0] digit_10

);

    assign digit_1  = data % 10;
    assign digit_10 = (data / 10) % 10;

endmodule

//============================================================================

module bcd (

    input  [3:0] bcd,
    output [7:0] fnd_data

);
    /****** 입력(받는 거) : wire, 출력 : reg ******/

    // always 출력 -> reg type
    reg [7:0] r_fnd_data;
    assign fnd_data = r_fnd_data;

    // 조합논리 combinational, 행위수준 모델링
    // ()안의 이벤트가 발생하면 항상 코드 실행
    always @(bcd) begin

        case (bcd)

            4'h00:   r_fnd_data = 8'hc0;
            4'h01:   r_fnd_data = 8'hf9;
            4'h02:   r_fnd_data = 8'ha4;
            4'h03:   r_fnd_data = 8'hb0;
            4'h04:   r_fnd_data = 8'h99;
            4'h05:   r_fnd_data = 8'h92;
            4'h06:   r_fnd_data = 8'h82;
            4'h07:   r_fnd_data = 8'hf8;
            4'h08:   r_fnd_data = 8'h80;
            4'h09:   r_fnd_data = 8'h90;
            default: r_fnd_data = 8'hff;
        endcase

    end

endmodule