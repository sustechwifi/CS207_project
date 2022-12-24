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
    input go_strait,

    
    output reg [7:0] seg_en,
    output [7:0] seg_out0,
    output [7:0] seg_out1,
    
    output direction_left_light,
    output direction_right_light,
    
    input contrl,
    output reg [3:0]r,
    output reg [3:0]g,
    output reg [3:0]b,
    output reg hs,
    output reg vs
    );

    parameter   OFF    =   4'b0000;
    parameter   ON     =   4'b0001;
    parameter   MANUAL_DRIVING_PREPARED     =   4'b0010;
    parameter   MANUAL_DRIVING_STARTING     =   4'b0011;
    parameter   MANUAL_DRIVING_MOVING     =   4'b0100;
    parameter   SEMI_AUTO     =   4'b0101;
    parameter   AUTO_DRIVING     =   4'b1010;
    
    
    reg [31:0] cnt = 0;
    reg [3:0] state,next_state; 
    wire[3:0] state_from_manual;
    wire[3:0] state_from_semi_auto;
    wire[3:0] state_from_auto;
    
    reg [31:0] male;
    reg [3:0] seg_7;
    reg clkout;
    reg [2:0] scan_cnt;
    reg [31:0] tim;
    reg [31:0] male_cnt;
    parameter period = 250000; //400Hz
    
      
    
    reg [3:0] control_signal;
    wire[3:0] control_signal_from_manual;
    wire[3:0] control_signal_from_semi_auto;
    wire[3:0] control_signal_from_auto;
    wire front_detector,back_detector,left_detector,right_detector;
    reg place_barrier_signal;
    reg destroy_barrier_signal;
    wire place_barrier_signal_from_auto;
    wire destroy_barrier_signal_from_auto;
    
   reg [2:0]num;
   reg [2:0] mile_0, mile_1, mile_2, mile_3, mile_4, mile_5, mile_6, mile_7;
   wire [23:0] VGA_signal;
   wire [3:0]r1;
   wire [3:0]r2;
   wire [3:0]g1;
   wire [3:0]g2;
   wire [3:0]b1;
   wire [3:0]b2;
   wire vs1;
   wire vs2;
   wire hs1;
   wire hs2;
   always@(sys_clk)
   begin
   if(contrl)
   begin
   r<=r1;
   g<=g1;
   b<=b1;
   vs<=vs1;
   hs<=hs1;
   end
   else
   begin
   r<=r2;
   g<=g2;
   b<=b2;
   vs<=vs2;
   hs<=hs2;
   end
   end
   vga_char_display vga (sys_clk,state,r1,g1,b1,hs1,vs1);
   vga_miles miles (sys_clk,{VGA_signal[2],VGA_signal[1],VGA_signal[0]},{VGA_signal[5],VGA_signal[4],VGA_signal[3]},
   {VGA_signal[8],VGA_signal[7],VGA_signal[6]},{VGA_signal[11],VGA_signal[10],VGA_signal[9]},
   {VGA_signal[14],VGA_signal[13],VGA_signal[12]},{VGA_signal[17],VGA_signal[16],VGA_signal[15]}
   ,{VGA_signal[20],VGA_signal[19],VGA_signal[18]},{VGA_signal[23],VGA_signal[22],VGA_signal[21]},r2,g2,b2,hs2,vs2);
    initial begin
    male = 32'd0;
    seg_7 = 4'b0000;
    state = 4'b0000;
    next_state = 4'b0000;
    cnt <= 32'd0;
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
    
    
    //里程数
    always@(posedge sys_clk, negedge rx)
        begin
            if(~rx)begin
               male <= 0;
               clkout <= 0;
            end
            else begin
            case(state)
            MANUAL_DRIVING_MOVING:
            begin
                if(male == (period>>1)-1)
                   begin
                   clkout <= ~ clkout;
                   male <= 0;
                   end
                 else if(male_cnt > 32'd1_0000_0000)
                    begin
                    male_cnt <= 0;
                    tim <= tim + 1;
                    end
                 else begin
                 male <= male + 1;
                 male_cnt <= male_cnt + 1;
                 end
            end
            default:begin
            male <= 32'd0;
            tim <= 0;
            male_cnt <= 0;
            end
            endcase
            end
        end

    always @(posedge clkout,negedge rx)
    begin
        if(~rx)
            scan_cnt <= 0;
        else begin
            if(scan_cnt == 3'd7)
                scan_cnt <= 0;
            else
                scan_cnt <= scan_cnt + 3'd1;
        end
    end
   
  
   always @(scan_cnt)
   begin
        mile_0 = tim; mile_1 = tim >> 3;mile_2 = tim >> 6;mile_3 = tim >> 9;mile_4 = tim >> 12;
        mile_5 = tim >> 15;mile_6 = tim >> 18; mile_7 = tim >> 21;
        case(scan_cnt)
        3'b000: begin seg_en = 8'h01; num = tim ;end
        3'b001: begin seg_en = 8'h02; num = tim >> 3; end
        3'b010: begin seg_en = 8'h04; num = tim >> 6; end
        3'b011: begin seg_en = 8'h08; num = tim >> 9;end
        3'b100: begin seg_en = 8'h10; num = tim >> 12;end
        3'b101: begin seg_en = 8'h20; num = tim >> 15;end
        3'b110: begin seg_en = 8'h40; num = tim >> 18;end
        3'b111: begin seg_en = 8'h80; num = tim >> 21;end
        default : seg_en = 8'h00;
        endcase
        
   end
   assign VGA_signal = {mile_7,mile_6,mile_5,mile_4,mile_3,mile_2,mile_1,mile_0};
  //状态机
    always@(state,mode)
    begin
       casex(state)
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
               3'b1xx: next_state <= AUTO_DRIVING;
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
      
       SEMI_AUTO: 
       begin 
       next_state <= state_from_semi_auto; 
       control_signal <= control_signal_from_semi_auto;
       end
      
       AUTO_DRIVING:
       begin
            next_state <=  state_from_auto; 
            control_signal <= control_signal_from_auto;
            place_barrier_signal <= place_barrier_signal_from_auto;
            destroy_barrier_signal <=  destroy_barrier_signal_from_auto;  
       end  
       default: next_state <= OFF; 
    endcase
    end

assign test = state;
wire [7:0] useless_seg_en0, useless_seg_en1;
light_7seg_ego1 l1({1'b0,num},seg_out0,useless_seg_en0);
light_7seg_ego1 l2({1'b0,num},seg_out1,useless_seg_en1);

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
  sys_clk, front_detector,back_detector,left_detector,right_detector,
  control_signal_from_auto,place_barrier_signal_from_auto,destroy_barrier_signal_from_auto,state_from_auto
);

semi_auto_driving semi(
   sys_clk, front_detector,back_detector,left_detector,right_detector, go_strait,turn_left,turn_right,
   state_from_semi_auto,
   control_signal_from_semi_auto
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