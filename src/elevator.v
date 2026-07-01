`timescale 1ns / 1ps


module elevator_controller (
    input clk,
    input rst,
    input [3:0] req,              // {F3, F2, F1, F0}

    output reg [1:0] current_floor,
    output reg door_open,
    output reg [1:0] dir          // 00 stop, 01 up, 10 down
);

    // States
    localparam IDLE   = 2'b00;
    localparam MOVING = 2'b01;
    localparam DOOR   = 2'b10;

    // Direction
    localparam STOP = 2'b00;
    localparam UP   = 2'b01;
    localparam DOWN = 2'b10;

    reg [1:0] state;
    reg [3:0] latched_req;
    reg moving_up;
    reg [2:0] door_timer;

    // Look ahead

    wire req_above =
        (current_floor == 2'd0 && |latched_req[3:1]) ||
        (current_floor == 2'd1 && |latched_req[3:2]) ||
        (current_floor == 2'd2 &&  latched_req[3]);

    wire req_below =
        (current_floor == 2'd3 && |latched_req[2:0]) ||
        (current_floor == 2'd2 && |latched_req[1:0]) ||
        (current_floor == 2'd1 &&  latched_req[0]);

    // clear request when door finishes service
    wire [3:0] clear_req =
        (state == DOOR && door_timer == 0) ? (4'b0001 << current_floor) : 4'b0000;

    // Main logic

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            current_floor <= 2'd0;
            latched_req <= 4'b0000;
            moving_up <= 1'b1;
            door_open <= 1'b0;
            dir <= STOP;
            door_timer <= 3'd0;

        end else begin

            // store requests
            latched_req <= (latched_req | req) & ~clear_req;

            case (state)

                //  IDLE
                IDLE: begin
                    door_open <= 1'b0;
                    dir <= STOP;

                    // serve current floor first
                    if (latched_req[current_floor]) begin
                        state <= DOOR;
                        door_timer <= 3'd4;

                    end else if (moving_up && req_above) begin
                        state <= MOVING;
                        dir <= UP;

                    end else if (!moving_up && req_below) begin
                        state <= MOVING;
                        dir <= DOWN;

                    end else if (req_above) begin
                        moving_up <= 1'b1;
                        state <= MOVING;
                        dir <= UP;

                    end else if (req_below) begin
                        moving_up <= 1'b0;
                        state <= MOVING;
                        dir <= DOWN;
                    end
                end

                //  MOVING 
                MOVING: begin
                    door_open <= 1'b0;

                    // move up
                    if (dir == UP && current_floor < 2'd3) begin
                        current_floor <= current_floor + 1'b1;

                    // move down
                    end else if (dir == DOWN && current_floor > 2'd0) begin
                        current_floor <= current_floor - 1'b1;
                    end

                    // after moving, check next floor next cycle
                    state <= IDLE;
                end

                //  DOOR 
                DOOR: begin
                    door_open <= 1'b1;
                    dir <= STOP;

                    if (door_timer > 0)
                        door_timer <= door_timer - 1'b1;
                    else
                        state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
