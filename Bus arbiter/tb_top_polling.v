`timescale 1ns / 1ps

module tb_top_polling;
    reg clk;
    reg rst;
    reg [7:0] req;
    
    wire [7:0] grant;
    wire [2:0] current_poll_addr;
    wire shared_bus_busy;

    // Instantiate Top Module
    top_polling_system uut (
        .clk(clk),
        .rst(rst),
        .req(req),
        .grant(grant),
        .current_poll_addr(current_poll_addr),
        .shared_bus_busy(shared_bus_busy)
    );

    // 10ns System Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; req = 8'd0;
        
        // Reset and let arbiter free-run (Fault Tolerance bypass)
        // Observe current_poll_addr incrementing every 2 clock cycles
        #25; rst = 0;
        
        // Test 1: Device 4 requests the bus
        #60; req[4] = 1;
        // Observe: Arbiter will lock on address 4, grant[4] goes high
        
        #40; req[4] = 0; // Device 4 releases bus
        
        // Test 2: Prove Round-Robin Fairness 
        // Devices 2, 5, and 7 all want the bus simultaneously
        #30; 
        req[2] = 1; 
        req[5] = 1; 
        req[7] = 1;
        
        // The Arbiter will naturally grant them in order (2 -> 5 -> 7)
        // We drop each request after giving it a few cycles to hold the bus
        
        #50; req[2] = 0; // Arbiter will immediately increment and find Device 5 next
        #50; req[5] = 0; // Arbiter increments and finds Device 7 next
        #50; req[7] = 0; // Bus becomes idle, arbiter goes back to free-running
        
        #80;
        $finish;
    end
endmodule