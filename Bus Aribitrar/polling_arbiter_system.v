`timescale 1ns / 1ps

module polling_arbiter (
    input wire clk,
    input wire rst,
    input wire bus_busy,       // Shared line driven by active devices
    output reg [2:0] poll_addr // 3-bit interrogation bus
);
    reg wait_flag; // 1-cycle timeout counter
    reg was_busy;  // Edge detector for bus release

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            poll_addr <= 3'd0;
            wait_flag <= 1'b0;
            was_busy  <= 1'b0;
        end else begin
            was_busy <= bus_busy;

            // Falling edge of bus_busy: previous device finished.
            // Force immediate increment to guarantee Round-Robin fairness.
            if (was_busy && !bus_busy) begin
                poll_addr <= poll_addr + 1;
                wait_flag <= 1'b0; // Start new interrogation window
                
            end else if (bus_busy) begin
                // Bus is actively held. Freeze address and clear wait flag.
                wait_flag <= 1'b0;
                
            end else begin
                // Bus is free. Wait for an answer or timeout.
                if (!wait_flag) begin
                    // Interrogation Window: Give device 1 cycle to respond.
                    wait_flag <= 1'b1;
                end else begin
                    // Timeout Triggered: Device is broken or doesn't need bus.
                    // Bypass it and interrogate the next device.
                    poll_addr <= poll_addr + 1;
                    wait_flag <= 1'b0;
                end
            end
        end
    end
endmodule

module polling_device #(
    parameter [2:0] MY_ADDR = 3'd0
)(
    input wire clk,
    input wire rst,
    input wire req,              // Internal device request
    input wire [2:0] poll_addr,  // Address broadcast by arbiter
    output wire bus_busy_out,    // CHANGED TO WIRE: Combinational claim
    output reg bus_granted       // Internal status: device owns bus
);

    // Combinationally assert busy if we ALREADY own it, OR if we are CLAIMING it right now
    assign bus_busy_out = bus_granted | (req && (poll_addr == MY_ADDR));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bus_granted  <= 1'b0;
        end else begin
            if (bus_granted) begin
                // State: Holds the Bus. Keep it until request drops.
                if (!req) begin
                    bus_granted  <= 1'b0;
                end
            end else begin
                // State: Waiting. Claim bus if address matches.
                if (req && (poll_addr == MY_ADDR)) begin
                    bus_granted  <= 1'b1;
                end
            end
        end
    end
endmodule

module top_polling_system (
    input wire clk,
    input wire rst,
    input wire [7:0] req,               // 8 distinct device requests
    output wire [7:0] grant,            // 8 distinct grant statuses
    output wire [2:0] current_poll_addr,// To observe arbitration looping
    output wire shared_bus_busy         // Observe bus state
);
    wire [7:0] busy_out_array;
    
    // Simulate open-drain/wired-OR physical bus sharing 
    assign shared_bus_busy = |busy_out_array; 

    polling_arbiter central_arb (
        .clk(clk),
        .rst(rst),
        .bus_busy(shared_bus_busy),
        .poll_addr(current_poll_addr)
    );

    // Generate 8 hardware nodes dynamically
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : peripheral_nodes
            polling_device #(
                .MY_ADDR(i)
            ) dev (
                .clk(clk),
                .rst(rst),
                .req(req[i]),
                .poll_addr(current_poll_addr),
                .bus_busy_out(busy_out_array[i]),
                .bus_granted(grant[i])
            );
        end
    endgenerate
endmodule
