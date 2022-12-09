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
    
    input destroy_barrier,
    
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
    
    reg [31:0] male;
    reg [3:0] seg_7;
      
    
    reg [3:0] control_signal;
    wire[3:0] control_signal_from_manual;
    wire[3:0] control_signal_from_semi_auto;
    wire[3:0] control_signal_from_auto;
    
    reg place_barrier_signal;
    reg destroy_barrier_signal;
    wire place_barrier_signal_from_auto;
    wire destroy_barrier_signal_from_auto;
    
    reg [1:0]left_cnt;
    reg [1:0]right_cnt;
    wire [1:0] left_cnt_next;
    wire [1:0] right_cnt_next;
    
    //TODO any other parameters for semi auto
    //...
     
    initial begin
    male = 32'd0;
    seg_7 = 4'b0000;
    state = 4'b0000;
    next_state = 4'b0000;
    cnt <= 32'd0;
    left_cnt <= 2'd0;
    right_cnt <= 2'd0;
    auto_cnt <= 32'd0;
    place_barrier_signal <= 1'b0;
    destroy_barrier_signal <= 1'b0;
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
    
    //auto driving cnt
    always@(posedge sys_clk)
    begin
        casex(state)
        4'b11xx:
        begin
            if(auto_cnt > 32'd2_0000_0000)
             begin
               auto_cnt <= 32'd0;
             end
            else auto_cnt <= auto_cnt + 32'd1;
        end
        default:auto_cnt <= 32'd0;
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
                   male <= 32'd0;
                 end
                else male <= male + 32'd1;
            end
            default:male <= 32'd0;
            endcase
        end

   
  //状态机
    always@(state,mode)
    begin
       casex(state)
       OFF: 
            begin          
            next_state <= OFF;
            control_signal <= 4'b0000;
            left_cnt <= 2'b0;
            right_cnt <= 2'b0;
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
       MANUAL_DRIVING_PREPARED, MANUAL_DRIVING_STARTING, MANUAL_DRIVING_MOVING :   
       begin 
            next_state <= state_from_manual; 
            control_signal <= control_signal_from_manual;
       end
      
       SEMI_AUTO: begin next_state <= state_from_semi_auto; control_signal <= control_signal_from_semi_auto;end
       //TODO other state in semi auto
       //SEMI_AUTO_{YOUR_STATE1}: begin next_state <= state_from_semi_auto; control_signal <= control_signal_from_semi_auto;end
       
       AUTO_DRIVING, AUTO_FORWARD, AUTO_TURN_LEFT, AUTO_TURN_RIGHT, AUTO_TURN_BACK:
       begin
            next_state <=  state_from_auto; 
            control_signal <= control_signal_from_auto;
            place_barrier_signal <= place_barrier_signal_from_auto;
            destroy_barrier_signal <=  destroy_barrier_signal_from_auto | destroy_barrier;   
            left_cnt <= left_cnt_next;
            right_cnt <= right_cnt_next;
       end  
       default: next_state <= OFF; 
    endcase
    end

assign test = state;
light_7seg_ego1 l1(seg_7,seg_out0,seg_en);
light_7seg_ego1 l2(seg_7,seg_out1,seg_en);

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
    direction_left_light,
    direction_right_light
);   


auto_driving auto(
    auto_cnt,
    state,
    state_from_auto,
    control_signal_from_auto,

    place_barrier_signal_from_auto,
    destroy_barrier_signal_from_auto,
    left_cnt,
    right_cnt,
    left_cnt_next,
    right_cnt_next,    
        
    front_detector,
    back_detector,
    left_detector,
    right_detector
);

semi_auto_driving semi(
   //TODO any other parameters if needed;
   //... 
    state,
    state_from_semi_auto,
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
    place_barrier_signal,
    destroy_barrier_signal,
    front_detector,
    left_detector,
    right_detector,
    back_detector
);
    
endmodule

