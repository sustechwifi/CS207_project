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
input sys_clk, front_detector,back_detector,left_detector,right_detector,
output [3:0]control_signal_from_auto,
output place_barrier_signal_from_auto,destroy_barrier_signal_from_auto,
output [3:0]state_from_auto
    );
        
        reg [3:0]state;
        reg [2:0]move;
        reg [31:0]cnt;
        reg place_barrier_signal,destroy_barrier_signal;
        parameter CHECK=4'b0001;
        parameter CLOSE_DETECT=4'b0010;
        parameter COUNT=4'b0100;
        parameter DOUBLECOUNT=4'b0111;
        parameter DECIDE=4'b0011;
        parameter THINK=4'b1100;
        parameter BACON=4'b0101;
        parameter DESTORY=4'b1101;
        
        parameter TURN=32'd8000_0000;
        parameter DOUBLETURN=32'd16000_0000;
        parameter LAST=32'd4000_0000;
        parameter THINKTIME=32'd1_0000_0000;
        initial
        begin
        state=CHECK;
        cnt=32'd0;
        move=3'b000;
        place_barrier_signal=1'b0;
        destroy_barrier_signal=1'b0;
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
          
          default:
          begin
          move<=3'b000;
          state<=THINK;
          end
          endcase
        
DECIDE:
         case({front_detector,back_detector,left_detector,right_detector})
         
           4'b0011,4'b0111: 
                 begin
                 move<=CLOSE_DETECT;
                 end
                
               4'b1010,4'b1110:
                    begin
                    move<=3'b001;
                    state<=BACON;
                    end
               
                
                 4'b1001,4'b1101:
                  begin
                  move<=3'b010;
                  state<=BACON;
                  end
                  
               4'b1011,4'b1111:
               begin
               move<=3'b010;
               state<=DESTORY;
               end
               
               4'b0000,4'b0010,4'b0100,4'b0110,4'b1000,4'b1100:
               begin
               state<=COUNT;
               move<=3'b001;
               end
               
               4'b0001,4'b0101:
               begin
               state<=CLOSE_DETECT;
               end
               
               endcase//DECIDE
        
BACON:
                   if(cnt<TURN)
                   begin
                     cnt<=cnt+32'd1;
                     place_barrier_signal<=1'b1;
                     end
                     else
                     begin
                     cnt<=32'd0;
                     place_barrier_signal<=1'b0;
                     state<=CLOSE_DETECT;
                     end
                     
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
                    if(cnt<THINKTIME)
                    begin
                    cnt<=cnt+32'd1;
                    move<=3'b000;
                    end
                    else
                    begin
                    cnt<=32'd0;
                    move<=3'b000;
                    state<=DECIDE;
                    end
                    
DOUBLECOUNT:
                   if(cnt<DOUBLETURN)
                     cnt<=cnt+32'd1;
                     else
                     begin
                     cnt<=32'd0;
                     move<=3'b000;
                     state<=CLOSE_DETECT;
                     end
                   
DESTORY:
        begin
        if(cnt<TURN)
          begin
          cnt<=cnt+32'd1;
           move<=3'b000;
           destroy_barrier_signal<=1'b1;
           end
          else
          begin
          move<=3'b010;
          cnt<=32'd0;
          destroy_barrier_signal<=1'b0; 
          state<=DOUBLECOUNT;
          end
        end
         
DOUBLECOUNT:
        if(cnt<DOUBLETURN)
          cnt<=cnt+32'd1;
          else
          begin
          cnt<=32'd0;
          move<=3'b000;
          state<=CLOSE_DETECT;
          end
        endcase//state
        end//always
        
          
         
        assign control_signal_from_auto={move[2],1'b0,move[1],move[0]};
        assign place_barrier_signal_from_auto=place_barrier_signal;
        assign destroy_barrier_signal_from_auto=destroy_barrier_signal;
        assign state_from_auto=4'b1010;
          
       

endmodule
