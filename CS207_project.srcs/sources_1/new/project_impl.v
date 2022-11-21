`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/19 09:25:56
// Design Name: 
// Module Name: project_impl
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


module project_impl(
    input sys_clk,
    input rx, //bind to N5 pin
    output tx, //bind to T4 pin
    
//  input place_barrier_signal,
//  input destroy_barrier_signal,
    output front_detector,
    output back_detector,
    output left_detector,
    output right_detector,

    input power_on,
    input power_off,
    input [2:0] mode,
    output[3:0] test,
    
    input throttle,
    input brake,
    input clutch,
    input reverse_gear_shift,
    
    input turn_left,
    input turn_right,
    
    output [7:0] seg_en,
    output [7:0] seg_out0,
    output [7:0] seg_out1,
    
    output direction_left_light,
    output direction_right_light
    );

    parameter   OFF    =   4'b0000;
    parameter   ON     =   4'b0001;
    parameter   MANUAL_DRIVING_PREPARED     =   4'b0010;
    parameter   MANUAL_DRIVING_STARTING     =   4'b0011;
    parameter   MANUAL_DRIVING_MOVING     =   4'b0100;
    parameter   SEMI_AUTO     =   4'h6;
    parameter   AUTO_DRIVING     =   4'ha;
    
    reg [31:0] cnt = 0;
    reg [3:0] state; 
    reg flag = 1'b0;
    reg [3:0] tmp;
    
    reg [31:0] male = 0;
    reg [3:0] seg_7 = 4'h0;
      
    wire [7:0] LED1,LED2,LED_EN;  
    
    initial begin
    state = 2'b0;
    end
    
    always@(posedge sys_clk or posedge power_off)
        if (power_off)
             begin
              flag <= 1'b0;
              cnt <= 32'd0;
             end
        else if(power_on)
           begin
           if(cnt > 32'd5000_0000) 
              begin
              flag <= 1'b1;
              cnt <= 0;
              end
           else cnt <= cnt + 32'd1;
           end
        else  begin
        cnt <= 32'd0;
        flag <= 1'b0;
        end
    
    always@(posedge sys_clk)
    begin
      if(power_off) 
            state <= OFF;
       case(state)
       OFF: 
            begin
               male <= 0;
               seg_7 <= 4'h0;
            if(flag)
                 state <= ON;
            else state <= OFF;
            end
       ON :
        begin
            if(power_off)
                state <= OFF;
            else if(mode == 3'b0)
                state <= ON;
            else 
            begin
             casex(mode)
               3'b1xx: state <= AUTO_DRIVING;
               3'b01x: state <= SEMI_AUTO;
               3'b001: state <= MANUAL_DRIVING_PREPARED;
               3'bxxx: state <= OFF;
              endcase
            end
         end
         
       MANUAL_DRIVING_PREPARED:
        begin
         tmp = {throttle,brake,clutch,reverse_gear_shift};
         casex(tmp)
            4'b101x:state <= MANUAL_DRIVING_STARTING;
            4'b1x0x:state <= OFF;
            4'bxxxx:state <= MANUAL_DRIVING_PREPARED;
         endcase
        end  
        MANUAL_DRIVING_STARTING:
        begin
           tmp = {throttle,brake,clutch,reverse_gear_shift};
           casex(tmp)
             4'b100x:state <= MANUAL_DRIVING_MOVING;
             4'b01xx:state <= MANUAL_DRIVING_PREPARED;
             4'bxxxx:state <= MANUAL_DRIVING_STARTING;
           endcase
        end
        MANUAL_DRIVING_MOVING:
        begin
           if(male > 32'd1_0000_0000)
               begin
               seg_7 <= seg_7 + 4'b0001;
               male <= 32'd0;
               end
           else  male <= male + 32'd1;
           tmp = {throttle,brake,clutch,reverse_gear_shift};
           casex(tmp)
                4'b01xx:state <= MANUAL_DRIVING_PREPARED;
                4'b0001:state <= OFF;
                4'b00xx:state <= MANUAL_DRIVING_STARTING;
                4'b0x1x:state <= MANUAL_DRIVING_STARTING;
                4'b1xxx:state <= MANUAL_DRIVING_MOVING;
           endcase
        end
        
       SEMI_AUTO:
        begin
            state <= OFF;  
        end  
       AUTO_DRIVING:
          begin
             state <= OFF;  
          end
       default: state <= OFF;
    endcase
    end
    
light_7seg_ego1 l1(seg_7,LED1,LED_EN);
light_7seg_ego1 l2(seg_7,LED2,LED_EN);
assign seg_en = LED_EN;
assign seg_out0 = LED1;
assign seg_out1= LED2;
assign test = state;
assign direction_left_light = turn_left;
assign direction_right_light = turn_right;

wire signal_forward,signal_back;
check_moving c(state,reverse_gear_shift,signal_forward,signal_back);

SimulatedDevice main(
sys_clk,
rx,
tx,
turn_left,
turn_right,
signal_forward,
signal_back,
1'b0,
1'b0,
front_detector,
back_detector,
left_detector,
right_detector
);
endmodule



module priority_encoder(
input [2:0] in,
output reg [2:0] out
);
always@(*)
   casex(in)
    3'b1xx: out = 3'b100;
    3'b01x: out = 3'b010;
    3'b001: out = 3'b001;
    3'bxxx: out = 3'b000;
   endcase
endmodule

module check_moving(
input [3:0] state,
input reverse,
output forward_signal,
output back_signal
);
reg res;
always@ *
begin
casex(state)
4'b0100:res = 1'b1;
4'bxxxx:res = 1'b0;
endcase
end
assign forward_signal = res & ~reverse;
assign back_signal = res & reverse;
endmodule

module change_direction(
input left,right,
output left_signal,right_signal
);
wire res;

assign left_signal = left & ~right;
assign right_signal = right & ~left;
endmodule
