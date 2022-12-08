`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/04 10:26:38
// Design Name: 
// Module Name: handle_diretion
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


module handle_diretion(
input front_detector,
input back_detector,
input left_detector,
input right_detector,

output reg [3:0] result
    );
    always@(*)begin
    casex({front_detector,back_detector,left_detector, right_detector})
      4'b1011: result <= 4'b0100;   // |~|
      4'b0x11: result <= 4'b1000;   // | |
      4'b1x01: result <= 4'b0010;   //  ~~~|
      4'b1x10: result <= 4'b0001;   //  |~~~
      4'b0110: result <= 4'b1000;   //  |__
      4'b0101: result <= 4'b1000;   //  __|
      default result <= 4'b1000;      
    endcase
    end
    
endmodule
