`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.05.2025 11:54:14
// Design Name: 
// Module Name: timer_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module timer_tb;

    // Parameters
    parameter WIDTH = 32;
    parameter TICKS = 10;

    // Inputs
    reg timer_clk;
    reg timer_rst;
    reg timer_enable;
    reg timer_clear;

    // Outputs
    wire timer_done;

    // Instantiate the Unit Under Test (UUT)
    timer #(
        .WIDTH(WIDTH),
        .TICKS(TICKS)
    ) uut (
        .timer_clk(timer_clk),
        .timer_rst(timer_rst),
        .timer_enable(timer_enable),
        .timer_clear(timer_clear),
        .timer_done(timer_done)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        timer_clk = 0;
        forever #5 timer_clk = ~timer_clk;
    end

    // Stimulus
    initial begin
        // Initialize inputs
        timer_rst = 1;
        timer_enable = 0;
        timer_clear = 0;

        // Wait for global reset
        #20;
        timer_rst = 0;

        // Enable timer
        #10;
        timer_enable = 1;

        // Let it run for 3 * TICKS cycles
        #(TICKS * 3 * 10);

        // Clear timer in between
        timer_clear = 1;
        #10;
        timer_clear = 0;

        // Let it run again for 2 * TICKS cycles
        #(TICKS * 2 * 10);

        // Stop simulation
        timer_enable = 0;
        #50;
        $finish;
    end

    // Monitor output
    initial begin
        $monitor("Time = %0dns, rst = %b, clear = %b, enable = %b, done = %b",
                 $time, timer_rst, timer_clear, timer_enable, timer_done);
    end

endmodule
