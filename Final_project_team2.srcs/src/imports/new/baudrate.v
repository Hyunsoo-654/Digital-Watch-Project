`timescale 1ns / 1ps

module baudrate (
    input  clk,
    input  rst,
    output baud_tick
);

    parameter BAUD = 9600;
    localparam BAUD_COUNT = (100_000_000 / BAUD) / 8;

    /////////////////////////// 기존 속도 //////////////////////////
    reg [$clog2(BAUD_COUNT) -1:0] count_reg, count_next;
    reg baud_tick_reg, baud_tick_next;

    assign baud_tick = baud_tick_reg;
    ////////////////////////////////////////////////////////////////
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            baud_tick_reg <= 0;
        end else begin
            count_reg <= count_next;
            baud_tick_reg <= baud_tick_next;
        end
    end
    /////////////////////////// 기존 속도 //////////////////////////
    always @(*) begin
        count_next = count_reg;
        baud_tick_next = 0;  // baud_tick_reg -> 얘도 가능하다.
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            baud_tick_next = 1'b1;
        end else begin
            count_next = count_reg + 1;
            baud_tick_next = 1'b0;
        end
    end

endmodule

////////////////////////////////////////////////////////////////////////////////////////

// module baudrate_assign (
//     input  clk,
//     input  rst,
//     output baud_tick
// );

//     parameter BAUD_RATE = 9600;
//     localparam BAUD_COUNT = (100_000_000 / BAUD_RATE);  // / 16;

//     reg [$clog2(BAUD_COUNT)-1 : 0] count_reg; 
//     wire [$clog2(BAUD_COUNT)-1 : 0] count_next;

//     assign count_next = (count_reg == BAUD_COUNT - 1) ? 0 : count_reg + 1;
//     assign baud_tick = (count_reg == BAUD_COUNT - 1) ? 1'b1 : 1'b0;

//     ///////////////////////////////////////////////////////////////

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             count_reg <= 0;
//         end else begin
//             count_reg <= count_next;
//         end
//     end

// endmodule

////////////////////////////////////////////////////////////////////////////////////////

// module baud_tick_gen (
//     input  clk,
//     input  reset,
//     output baud_tick
// );

//     parameter BAUD_RATE = 9600;
//     localparam BAUD_COUNT = (100_000_000 / BAUD_RATE);
//     reg [$clog2(BAUD_COUNT)-1 : 0] count_reg, count_next;
//     reg tick_reg, tick_next;

//     assign baud_tick = tick_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             count_reg <= 0;
//             tick_reg  <= 0;
//         end else begin
//             count_reg <= count_next;
//             tick_reg  <= tick_next;
//         end
//     end

//     always @(*) begin
//         count_next = count_reg;
//         tick_next  = tick_reg;
//         if (count_reg == BAUD_COUNT - 1) begin
//             count_next = 0;
//             tick_next  = tick_reg + 1;
//         end else begin
//             count_next = count_reg + 1;
//             tick_next  = 1'b0;
//         end
//     end
// endmodule
