`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/21 22:41:42
// Design Name: 
// Module Name: auto_driving
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


module auto_driving(
input [31:0] cnt,
input [3:0]state,
output reg [3:0] state_output,
output [3:0] control_signal_output,

input front_detector,
input back_detector,
input left_detector,
input right_detector
    );
        parameter   AUTO_DRIVING     =   4'b1010;
        parameter   AUTO_FORWARD     =   4'b1011;
        parameter   AUTO_TURN_LEFT   =   4'b1100;
        parameter   AUTO_TURN_RIGHT  =   4'b1101;
        parameter   AUTO_TURN_BACK   =   4'b1110;
        
        reg [3:0] next_state;
        reg [3:0] res;
        
        always@(state)begin
             case(state)
             AUTO_DRIVING:
                begin
                  //TODO
                  res <= 4'b0000;
                  state_output <= next_state;
                end
             AUTO_FORWARD:
                begin
                    res <= 4'b1000;
                    state_output <= next_state;
                end
             AUTO_TURN_LEFT:
                begin
                    if(cnt > 32'd8000_0000)
                    begin
                        state_output <= AUTO_DRIVING;
                        if(cnt < 32'd1_0000_0000)begin
                        state_output <= AUTO_TURN_LEFT;
                        res <= 4'b1000;
                        end
                    end
                    else begin
                        res <= 4'b0010;
                        state_output <= AUTO_TURN_LEFT;
                    end
                end
              AUTO_TURN_RIGHT:
                     begin
                        if(cnt > 32'd8000_0000)
                         begin
                             state_output <= AUTO_DRIVING;
                             if(cnt < 32'd1_0000_0000)begin
                             state_output <= AUTO_TURN_LEFT;
                             res <= 4'b1000;
                             end
                         end
                        else begin
                             res <= 4'b0001;
                             state_output <= AUTO_TURN_RIGHT;
                        end
                     end
              AUTO_TURN_BACK:
                      begin
                        if(cnt > 32'd1_7000_0000)
                         begin
                           state_output <= AUTO_DRIVING;
                         end
                        else begin
                           res <= 4'b0001;
                           state_output <= AUTO_TURN_BACK;
                         end
                      end
             default : begin
             state_output <= state;
             res <= 4'b0000;
             end
             endcase
        end
        
       always@(front_detector,back_detector,left_detector, right_detector)begin
            if(state == AUTO_DRIVING || state == AUTO_FORWARD)begin
            casex({front_detector,back_detector,left_detector, right_detector})
              4'b1011: next_state <= AUTO_TURN_BACK;   // |~|
              4'b0x11: next_state <= AUTO_FORWARD;   // | |
              4'b1x01: next_state <= AUTO_TURN_LEFT;   //  <-~~~|
              4'b1x10: next_state <= AUTO_TURN_RIGHT;   //  |~~~->
              4'b0110: next_state <= AUTO_FORWARD;   //  |__->
              4'b0101: next_state <= AUTO_FORWARD;   //   <-__|
              4'b1x00: next_state <= AUTO_TURN_LEFT; //   <-~~->
              4'b0x00: next_state <= AUTO_TURN_LEFT; //    
              4'b0001: next_state <= AUTO_TURN_LEFT;
              4'b0010: next_state <= AUTO_TURN_RIGHT;
              default next_state <= AUTO_FORWARD;      
            endcase
            end
            else next_state <= state;
        end

assign control_signal_output = res;

endmodule
