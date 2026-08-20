`timescale 1ns / 1ps

module tb_top_daisy_chain;

    reg clk;
    reg rst;
    reg br_a, br_b, br_c, br_d;
    reg bb;
    
    wire grant_a, grant_b, grant_c, grant_d;

    // Instantiate Unit Under Test (UUT)
    top_daisy_chain uut (
        .clk(clk),
        .rst(rst),
        .br_a(br_a),
        .br_b(br_b),
        .br_c(br_c),
        .br_d(br_d),
        .bb(bb),
        .grant_a(grant_a),
        .grant_b(grant_b),
        .grant_c(grant_c),
        .grant_d(grant_d)
    );

    // Generate 10ns clock
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0; rst = 1;
        br_a = 0; br_b = 0; br_c = 0; br_d = 0;
        bb = 0;

        // Apply Reset
        #20; rst = 0;
        
        // Test 1: Device C requests the bus alone
        #20; br_c = 1;
        
        // Test 2: B and D request simultaneously (Priority: B wins over D)
        #40;
        br_c = 0; // C releases
        br_b = 1; br_d = 1;
        
        // Test 3: Clear requests
        #40; br_b = 0; br_d = 0;
        
        // Test 4: All devices request simultaneously (A wins)
        #20; br_a = 1; br_b = 1; br_c = 1; br_d = 1;
        
        // Test 5: Testing the MANUAL Bus Busy (bb) line
        // First, drop all requests to reset the state
        #40; br_a = 0; br_b = 0; br_c = 0; br_d = 0;
        
        #20;
        bb = 1;         // MANUALLY assert Bus Busy (simulating an external master using the bus)
        
        #10;
        br_c = 1;       // Device C requests the bus.
        // OBSERVE: C's request goes high, but `grant_c` will remain 0 because bb is high!
        
        #40;
        bb = 0;         // Release Bus Busy
        // OBSERVE: On the next clock edge after bb drops, `grant_c` will instantly assert.
        
        // End simulation
        #60;
        $finish;
    
    end

endmodule