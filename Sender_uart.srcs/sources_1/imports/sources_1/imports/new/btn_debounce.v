`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn

);

    // 10khz clk = 100Mhz / 1000;  -> 그래서 F_COUNT = 10000.
    parameter F_COUNT = 10000;
    reg [$clog2(F_COUNT)-1:0] r_counter;

    reg r_clk;  // 클럭 생성
    reg [7:0] q_reg, q_next;  // 회로 output 
    reg  r_edge_q; 
    wire w_debounce;

    // 10khz clk 생성
    always @(posedge clk, posedge rst) begin

        if (rst) begin
            r_counter <= 0;
            r_clk <= 0;
        end else begin
            if (r_counter == (F_COUNT - 1)) begin
                r_counter <= 0;
                r_clk <= 1'b1;
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;
            end
        end
    end

    // debounce 
    always @(posedge r_clk, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end

    // shift register
    always @(i_btn, r_clk, q_reg) begin
        q_next = {i_btn, q_reg[7:1]};
    end

    // 8 input and gate
    assign w_debounce = &q_reg;

    // edge detector
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_edge_q <= 0;
        end else begin
            r_edge_q <= w_debounce;
        end
    end

    // rising edge
    assign o_btn = ~(r_edge_q) & w_debounce;

endmodule
