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
    reg [3:0] state,next_state; 
    wire[3:0] state_from_module;
    
    reg flag = 1'b0;
    reg [3:0] tmp;
    
    reg [31:0] male = 0;
    reg [3:0] seg_7 = 4'h0;
      
    wire [7:0] LED1,LED2,LED_EN;  
    
    wire front_detector;
    wire back_detector;
    wire left_detector;
    wire right_detector;
    
    wire signal_forward;
    wire signal_back;
    
    initial begin
    state = 4'b0;
    next_state = 4'b0;
    end
    
    //开关
    always@(posedge sys_clk or posedge power_off)
        if (power_off)
             begin
              state <= OFF;
              cnt <= 32'd0;
             end
        else if(power_on)
           begin
           if(cnt > 32'd1_0000_0000 && state == OFF) 
              begin
              state <= ON;
              cnt <= 32'd0;
              end
           else cnt <= cnt + 32'd1;
           end
        else  begin
        cnt <= 32'd0;
        state <= next_state;
        end
    
    //里程数
    always@(posedge sys_clk)
    begin
        case(state)
        MANUAL_DRIVING_MOVING:
        begin
            if(male > 32'd1_0000_0000)
             begin
               seg_7 <= seg_7 + 4'b0001;
               male <= 0;
             end
            else male <= male + 32'd1;
        end
        default:male <= male;
        endcase
    end

   
  //状态机
    always@(state,mode)
    begin
       case(state)
       OFF: 
            begin          
            next_state <= OFF;
            end
       ON :
        begin
            if(mode == 3'b0)
                next_state <= ON;
            else 
            begin
             casex(mode)
               3'b1xx: next_state <= AUTO_DRIVING;
               3'b01x: next_state <= SEMI_AUTO;
               3'b001: next_state <= MANUAL_DRIVING_PREPARED;
               3'bxxx: next_state <= ON;
              endcase
            end
         end             
       default: next_state <= state_from_module; 
    endcase
    end

assign test = state;

manual_driving manual(
    state,
    state_from_module,
    throttle,
    brake,
    clutch,
    reverse_gear_shift,
    turn_left,
    turn_right,
    seg_en,
    seg_out0,
    seg_out1,
    direction_left_light,
    direction_right_light,
    signal_forward,
    signal_back
);   


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

