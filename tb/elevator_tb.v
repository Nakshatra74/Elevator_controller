`timescale 1ns / 1ps

module tb_elevator_controller;

    reg clk;
    reg rst;
    reg [3:0] req;

    wire [1:0] current_floor;
    wire door_open;
    wire [1:0] dir;

    // DUT
    elevator_controller dut (
        .clk(clk),
        .rst(rst),
        .req(req),
        .current_floor(current_floor),
        .door_open(door_open),
        .dir(dir)
    );
    
    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $monitor("t=%0t | floor=%0d | req=%b | dir=%b | door=%b",
                 $time, current_floor, req, dir, door_open);
    end

    // Stimulus
    initial begin
        clk = 0;
        rst = 1;
        req = 4'b0000;

        // reset
        #20;
        rst = 0;

        // Test 1: multiple upward requests

        #10;
        req = 4'b1110;   // floors 3,2,1 requested

        #200;

        // Test 2: add lower request while moving

        req = 4'b1001;   // floor 3 and floor 0

        #200;

        // Test 3: only bottom floor

        req = 4'b0001;

        #150;
        $finish;
    end

endmodule
