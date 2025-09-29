`timescale 1ns / 1ps

module baudrate (
    input  clk,
    input  rst,
    output baud_tick
);

    parameter BAUD_RATE = 9600;
    parameter BAUD_COUNT= 100_000_000 / (BAUD_RATE * 8);

    reg [$clog2(BAUD_COUNT) - 1 : 0] count_reg, count_next;
    reg baud_tick_reg, baud_tick_next;

    assign baud_tick = baud_tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            baud_tick_reg <= 0;
        end else begin
            count_reg <= count_next;
            baud_tick_reg <= baud_tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        baud_tick_next  = 0; // baud_tick_reg -> 얘도 가능하다.
        if (count_reg == BAUD_COUNT - 1) begin
            count_next = 0;
            baud_tick_next  = baud_tick_reg + 1;
        end else begin
            count_next = count_reg + 1;
            baud_tick_next  = 1'b0;
        end
    end


endmodule


// assign(조합논리)를 활용. FF가 없어서 한 클럭 빠르게 tick 발생생

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




