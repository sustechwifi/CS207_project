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
input sys_clk, front_detector,back_detector,left_detector,right_detector, go_strait,turn_left,turn_right,
output [3:0] state_output,
output [3:0] control_signal_from_semi_auto
    );
    
    reg [3:0]state;
    reg [2:0]move;
    reg [31:0]cnt;
    parameter WAIT=3'b000;
    parameter CHECK=3'b001;
    parameter CLOSE_DETECT=3'b010;
    parameter COUNT=3'b100;
    parameter DOUBLECOUNT=3'b111;
    parameter DECIDE=3'b011;
    parameter THINK=3'b110;
    parameter TURN=32'd8000_0000;
    parameter DOUBLETURN=32'd1_6000_0000;
    parameter LAST=32'd4000_0000;
    parameter SEMI_AUTO = 4'b0101;
    
    initial
    begin
    state=CHECK;
    end//initial
    
    always@(posedge sys_clk)
    begin
    case(state)
    CHECK:
      case({front_detector,back_detector,left_detector,right_detector})
      4'b0011,4'b0111: 
      begin
      move<=3'b100;
      end
      
      4'b1001,4'b1101, 4'b1011, 4'b1010,4'b1110:
      begin
      move<=3'b000;
      state<=THINK;
      end
      
      default:
      begin
      state<=WAIT;
      move<=3'b000;
      end
      endcase
      
    CLOSE_DETECT:
      if(cnt<LAST)
      begin
      move<=3'b100;
      cnt<=cnt+32'd1;
      end
      else
      begin
      cnt<=32'd0;
      state<=CHECK;
      end
      
    COUNT:
      if(cnt<TURN)
      cnt<=cnt+32'd1;
      else
      begin
      cnt<=32'd0;
      state<=CLOSE_DETECT;
      end
      
    THINK:
     if(cnt<TURN)
     cnt<=cnt+32'd1;
     else
     begin
     cnt<=32'd0;
     state<=DECIDE;
     end
     
    DOUBLECOUNT:
    if(cnt<DOUBLETURN)
      cnt<=cnt+32'd1;
      else
      begin
      cnt<=32'd0;
      state<=CLOSE_DETECT;
      end
    
    DECIDE:
       case({front_detector,back_detector,left_detector,right_detector})
     4'b0011,4'b0111: 
     begin
     move<=3'b100;
     end
     
     4'b1001,4'b1101:
     begin
     move<=3'b010;
     state<=COUNT;
     end
     
     4'b1011:
    begin
    move<=3'b010;
    state<=DOUBLECOUNT;
    end
     
     4'b1010,4'b1110:
      begin
      move<=3'b001;
      state<=COUNT;
      end
      
    default:
        begin
        state<=WAIT;
        move<=3'b000;
        end
        endcase
    WAIT:
      case({go_strait,turn_left,turn_right})
      3'b100: 
      begin
      state<=CLOSE_DETECT;
      end
      
      3'b010:
      begin
        move<=3'b010;
        state<=COUNT;
      end
    
      3'b001:
      begin
       move<=3'b001;
       state<=COUNT;
      end
      
      endcase//wait
      
    endcase//state
    end//always
      
     
       assign control_signal_from_semi_auto={move[2],1'b0,move[1],move[0]};
       assign state_output=4'b0101;
       endmodule
