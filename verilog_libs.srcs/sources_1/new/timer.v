`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 17.05.2025 11:42:22
// Design Name: 
// Module Name: timer
// Project Name: Verilog Libraries
// Target Devices: 
// Tool Versions: 1.0
// Description: 
// 
// Dependencies: none
// 
// Revision:0
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module timer #(
    parameter WIDTH = 32,
    parameter TICKS = 100)(
    input wire timer_clk,
    input wire timer_rst,
    input wire timer_enable,
    input wire timer_clear,
    output reg timer_done
    );
    reg [WIDTH-1:0] counter;
    
    always @(posedge timer_clk) 
    begin
        if(timer_rst)
        begin
            counter <= 0;
            timer_done <= 0;
        end
        else if (timer_clear)
        begin
            counter <= 0;
            timer_done <= 0;
        end
        else if (timer_enable)
        begin
            if (counter == TICKS - 1) 
            begin
                counter <= 0;
                timer_done <= 1;
            end 
            else 
            begin
                counter <= counter + 1;
                timer_done <= 0;
            end
       end
       else 
       begin
           timer_done <= 0;
       end
    end
endmodule
