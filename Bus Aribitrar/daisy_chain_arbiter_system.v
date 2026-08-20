`timescale 1ns / 1ps

module device_node (
    input wire clk,
    input wire rst,
    input wire br_in,       // Device's own Bus Request
    input wire bg_in,       // Bus Grant coming from upstream
    input wire bb,          // Bus Busy line
    output wire br_out,     // Shared BR line contribution
    output wire bg_out,     // Bus Grant going downstream
    output reg bus_granted  // Internal status: device owns the bus
);

    // Pass the request straight through to the shared OR-gate
    assign br_out = br_in;

    // Combinational Logic: Pass the grant downstream ONLY if we don't want the bus
    assign bg_out = bg_in & ~br_in;

    // Synchronous Logic: Claiming and releasing the bus
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bus_granted <= 1'b0;
        end else begin
            if (bus_granted) begin
                // STATE 1: We ALREADY own the bus.
                // Hold it until we drop our own request.
                if (!br_in) begin
                    bus_granted <= 1'b0;
                end
            end else begin
                // STATE 2: We are WAITING for the bus.
                // Claim it ONLY if the token reaches us, we want it, AND the bus is free.
                if (bg_in && br_in && !bb) begin
                    bus_granted <= 1'b1;
                end
            end
        end
    end
endmodule

module central_arbiter (
    input wire clk,
    input wire rst,
    input wire br_shared,   // Shared BR line from all devices
    input wire bb,          // Bus Busy line
    output reg bg_out       // Initial Bus Grant to Device A
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bg_out <= 1'b0;
        end else begin
            // Issue grant if a request is pending and the bus is free
            if (br_shared && !bb) begin
                bg_out <= 1'b1;
            end else begin
                bg_out <= 1'b0;
            end
        end
    end
endmodule

module top_daisy_chain (
    input wire clk,
    input wire rst,
    input wire br_a, br_b, br_c, br_d, // Individual requests
    input wire bb,                     // Bus busy line
    output wire grant_a, grant_b, grant_c, grant_d
);

    wire bg_arb_to_a;
    wire bg_a_to_b;
    wire bg_b_to_c;
    wire bg_c_to_d;
    
    wire br_a_out, br_b_out, br_c_out, br_d_out;
    wire shared_br;

    // Wired-OR for shared Bus Request line
    assign shared_br = br_a_out | br_b_out | br_c_out | br_d_out;

    central_arbiter arb (
        .clk(clk),
        .rst(rst),
        .br_shared(shared_br),
        .bb(bb),
        .bg_out(bg_arb_to_a)
    );

    device_node dev_a (
        .clk(clk), .rst(rst),
        .br_in(br_a), .bg_in(bg_arb_to_a), .bb(bb),
        .br_out(br_a_out), .bg_out(bg_a_to_b), .bus_granted(grant_a)
    );

    device_node dev_b (
        .clk(clk), .rst(rst),
        .br_in(br_b), .bg_in(bg_a_to_b), .bb(bb),
        .br_out(br_b_out), .bg_out(bg_b_to_c), .bus_granted(grant_b)
    );

    device_node dev_c (
        .clk(clk), .rst(rst),
        .br_in(br_c), .bg_in(bg_b_to_c), .bb(bb),
        .br_out(br_c_out), .bg_out(bg_c_to_d), .bus_granted(grant_c)
    );

    device_node dev_d (
        .clk(clk), .rst(rst),
        .br_in(br_d), .bg_in(bg_c_to_d), .bb(bb),
        .br_out(br_d_out), .bg_out(/* terminal */), .bus_granted(grant_d)
    );

endmodule
