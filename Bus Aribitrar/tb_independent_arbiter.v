`timescale 1ns / 1ps

module tb_independent_arbiter;

    reg clk;
    reg rst;
    reg [3:0] req;
    
    wire [3:0] grant;

    // Instantiate the Unit Under Test (UUT)
    independent_arbiter uut (
        .clk(clk),
        .rst(rst),
        .req(req),
        .grant(grant)
    );

    // Generate 10ns System Clock
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        req = 4'b0000;

        // Apply Reset
        #20;
        rst = 0;
        
        // Test 1: Single Request from Device 2
        #20;
        req[2] = 1; 
        // Observe: grant[2] goes high on the next clock edge.
        
        // Test 2: Non-Preemptive Check (Device 0 requests while Device 2 holds bus)
        #30;
        req[0] = 1;
        // Observe: grant[2] REMAINS high. Device 0 must wait.
        
        // Test 3: Single-Cycle Handover
        #30;
        req[2] = 0; // Device 2 finishes and drops its request
        // Observe: In exactly ONE clock cycle, grant[2] drops and grant[0] asserts.
        
        // Test 4: Simultaneous Conflict Resolution
        #40;
        req = 4'b0000; // Clear bus
        #20;
        req = 4'b1111; // All four devices request at the exact same time
        // Observe: grant[0] immediately wins due to highest fixed priority.
        
        // Test 5: Sequential Release
        #30; req[0] = 0; // Device 1 takes over
        #30; req[1] = 0; // Device 2 takes over
        #30; req[2] = 0; // Device 3 takes over
        #30; req[3] = 0; // Bus goes idle
        
        #50;
        $finish;
    end

endmodule