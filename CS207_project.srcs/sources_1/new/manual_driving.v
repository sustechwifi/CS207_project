module manual_driving(
    input [3:0]state_input,
    output [3:0]state_output,
    
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
    
    output signal_forward,
    output signal_back
    );

    parameter   OFF    =   4'b0000;
    parameter   ON     =   4'b0001;
    parameter   MANUAL_DRIVING_PREPARED     =   4'b0010;
    parameter   MANUAL_DRIVING_STARTING     =   4'b0011;
    parameter   MANUAL_DRIVING_MOVING     =   4'b0100;
    parameter   SEMI_AUTO     =   4'h6;
    parameter   AUTO_DRIVING     =   4'ha;
    
    reg [3:0] tmp;
    reg [31:0] male = 0;
    reg [3:0] seg_7 = 4'h0;
      
    wire [7:0] LED1,LED2,LED_EN;  
    
    reg [3:0]state;
    initial begin
    state = state_input;
    end
    
    always@(state)
    begin
       case(state)
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
       default: state <= OFF;
    endcase
    end
    
light_7seg_ego1 l1(seg_7,LED1,LED_EN);
light_7seg_ego1 l2(seg_7,LED2,LED_EN);
check_moving c(state,reverse_gear_shift,signal_forward,signal_back);

assign seg_en = LED_EN;
assign seg_out0 = LED1;
assign seg_out1= LED2;
assign direction_left_light = turn_left;
assign direction_right_light = turn_right;
assign state_output = state;
endmodule
