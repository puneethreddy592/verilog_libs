`timescale 1ns / 1ps

module independent_arbiter (
    input wire clk,
    input wire rst,
    input wire [3:0] req,    // Independent Bus Requests (BR3, BR2, BR1, BR0)
    output reg [3:0] grant   // Independent Bus Grants (BG3, BG2, BG1, BG0)
);

    wire [3:0] comb_grant;
    wire [3:0] active_req;
    wire bus_is_held;

    // Check if the current bus owner is still holding its request
    assign bus_is_held = |(grant & req);

    // MUX: If the bus is held, ignore all other requests and only look at the current owner.
    // If the bus is free, look at all incoming requests.
    assign active_req = bus_is_held ? (grant & req) : req;

    // Combinational Fixed Priority Encoder
    // Device 0 is highest priority; Device 3 is lowest.
    assign comb_grant[0] = active_req[0];
    assign comb_grant[1] = active_req[1] & ~active_req[0];
    assign comb_grant[2] = active_req[2] & ~active_req[1] & ~active_req[0];
    assign comb_grant[3] = active_req[3] & ~active_req[2] & ~active_req[1] & ~active_req[0];

    // Single-cycle synchronous grant update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 4'b0000;
        end else begin
            grant <= comb_grant;
        end
    end

endmodule