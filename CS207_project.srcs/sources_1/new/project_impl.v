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
    output direction_right_light,
    output front_detector,
    output back_detector,
    output left_detector,
    output right_detector
    );

    parameter   OFF    =   4'b0000;
    parameter   ON     =   4'b0001;
    parameter   MANUAL_DRIVING_PREPARED     =   4'b0010;
    parameter   MANUAL_DRIVING_STARTING     =   4'b0011;
    parameter   MANUAL_DRIVING_MOVING     =   4'b0100;
    parameter   SEMI_AUTO     =   4'b0101;
    //TODO other states in semi auto  5-9
    //...
    
    parameter   AUTO_DRIVING     =   4'b1010;
    parameter   AUTO_FORWARD     =   4'b1011;
    parameter   AUTO_TURN_LEFT   =   4'b1100;
    parameter   AUTO_TURN_RIGHT  =   4'b1101;
    parameter   AUTO_TURN_BACK   =   4'b1110;
    
    reg [31:0] cnt = 0,auto_cnt = 0;
    reg [3:0] state,next_state; 
    wire[3:0] state_from_manual;
    wire[3:0] state_from_semi_auto;
    wire[3:0] state_from_auto;
    
    reg flag = 1'b0;
    reg [3:0] tmp;
    
    reg [31:0] male = 0;
    reg [3:0] seg_7 = 4'h0;
      
    wire [7:0] LED1,LED2,LED_EN;  
    
    reg [3:0] control_signal;
    wire[3:0] control_signal_from_manual;
    wire[3:0] control_signal_from_semi_auto;
    wire[3:0] control_signal_from_auto;
    
    //TODO any other parameters for semi auto
    //...
     
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
    
    
    always@(posedge sys_clk)
    begin
        casex(state)
        4'b11xx:
        begin
            if(auto_cnt > 32'd2_0000_0000)
             begin
               auto_cnt <= 0;
             end
            else auto_cnt <= auto_cnt + 32'd1;
        end
        default:auto_cnt <= 0;
        endcase
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
            control_signal <= 4'b0000;
            end
       ON :
        begin
            if(mode == 3'b0)
                next_state <= ON;
            else 
            begin
             casex(mode)
               3'b1xx: next_state <= AUTO_FORWARD;
               3'b01x: next_state <= SEMI_AUTO;
               3'b001: next_state <= MANUAL_DRIVING_PREPARED;
               3'bxxx: next_state <= ON;
              endcase
            end
         end
       MANUAL_DRIVING_PREPARED :   begin next_state <= state_from_manual; control_signal <= control_signal_from_manual;end
       MANUAL_DRIVING_STARTING :   begin next_state <= state_from_manual; control_signal <= control_signal_from_manual;end
       MANUAL_DRIVING_MOVING   :   begin next_state <= state_from_manual; control_signal <= control_signal_from_manual;end
       
       SEMI_AUTO: begin next_state <= state_from_semi_auto; control_signal <= control_signal_from_semi_auto;end
       //TODO other state in semi auto
       //SEMI_AUTO_{YOUR_STATE1}: begin next_state <= state_from_semi_auto; control_signal <= control_signal_from_semi_auto;end
         
       AUTO_DRIVING     :  begin next_state <=  state_from_auto; control_signal <= control_signal_from_auto; end
       AUTO_FORWARD     :  begin next_state <=  state_from_auto; control_signal <= control_signal_from_auto; end
       AUTO_TURN_LEFT   :  begin next_state <=  state_from_auto; control_signal <= control_signal_from_auto; end
       AUTO_TURN_RIGHT  :  begin next_state <=  state_from_auto; control_signal <= control_signal_from_auto; end
       AUTO_TURN_BACK   :  begin next_state <=  state_from_auto; control_signal <= control_signal_from_auto; end
         
       default: next_state <= OFF; 
    endcase
    end

assign test = state;

manual_driving manual(
    state,
    state_from_manual,
    control_signal_from_manual,
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
    direction_right_light
);   


auto_driving auto(
    auto_cnt,
    state,
    state_from_semi_auto,
    control_signal_from_auto,
        
    front_detector,
    back_detector,
    left_detector,
    right_detector
);

semi_auto_driving semi(
   //TODO any other parameters if needed;
   //... 
    state,
    state_from_auto,
    control_signal_from_semi_auto,
        
    front_detector,
    back_detector,
    left_detector,
    right_detector
);


SimulatedDevice main(
    sys_clk,
    rx,
    tx,
    control_signal[1],  //左
    control_signal[0],  //右
    control_signal[3],  //前
    control_signal[2],  //后
    1'b0,
    1'b0,
    front_detector,
    left_detector,
    right_detector,
    back_detector
);
    
endmodule

