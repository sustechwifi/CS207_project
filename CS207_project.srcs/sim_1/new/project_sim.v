`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/19 10:47:06
// Design Name: 
// Module Name: project_sim
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


module project_sim();
reg clk;
//,rx;
//wire tx;
//reg 
//turn_left_signal,
//turn_right_signal,
//move_forward_signal,
//move_backward_signal, 
//place_barrier_signal,
//destroy_barrier_signal;

//wire 
//front_detector,
//back_detector, 
//left_detector, 
//right_detector;

reg power_on;
reg power_off;
reg [2:0] mode;
wire [3:0] test;

initial
    begin
        clk = 1'b0;
        mode = 3'b001;
        power_on = 1'b1;
        power_off = 1'b0;
    end

//系统时钟初始化，周期为20ns
always #100000000 clk = ~clk;

wire  [2:0] state = impl.state;
//显示初始化

//实例化
project_impl impl
(
   clk,
   power_on,
   power_off,
   mode,
   test
);
endmodule
