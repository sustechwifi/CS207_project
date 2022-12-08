`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/21 22:41:23
// Design Name: 
// Module Name: semi_auto_driving
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


module semi_auto_driving(
//input [31:0] cnt,  Ê±ÐòÂß¼­ÐÅºÅµÈ
input [3:0]state,
output reg [3:0] state_output,
output [3:0] control_signal_output,

input front_detector,
input back_detector,
input left_detector,
input right_detector
    );
     parameter   SEMI_AUTO     =   4'b0101;
       //TODO other states in semi auto  5-9
       //...
    
    always@(state)begin
    if(state < 4'h5 || state > 4'h9)state_output <= state;
    else begin
        casex(state)
        //TODO fill something
        //.....
        endcase
        end
    end
    //TODO any other opeartions 
    //...
endmodule
