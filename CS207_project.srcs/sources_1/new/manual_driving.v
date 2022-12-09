module manual_driving(
    input[3:0] state,
    output reg [3:0] next_state,
    output [3:0] control_output,
    
    input throttle,
    input brake,
    input clutch,
    input reverse_gear_shift,
    
    input turn_left,
    input turn_right,
    
    output direction_left_light,
    output direction_right_light
    );
    parameter   OFF    =   4'b0000;
    parameter   MANUAL_DRIVING_PREPARED     =   4'b0010;
    parameter   MANUAL_DRIVING_STARTING     =   4'b0011;
    parameter   MANUAL_DRIVING_MOVING     =   4'b0100;
    

    reg [3:0] tmp;
    reg res;

always@(state)
    begin
       case(state)
     MANUAL_DRIVING_PREPARED:
          begin
              tmp = {throttle,brake,clutch,reverse_gear_shift};
              res = 1'b0;
              casex(tmp)
               4'b101x:next_state <= MANUAL_DRIVING_STARTING;
               4'b1x0x:next_state <= OFF;
               4'bxxxx:next_state <= MANUAL_DRIVING_PREPARED;
              endcase
              end  
      MANUAL_DRIVING_STARTING:
          begin
              tmp = {throttle,brake,clutch,reverse_gear_shift};
              res = 1'b0;
                casex(tmp)
                  4'b100x:next_state <= MANUAL_DRIVING_MOVING;
                  4'b01xx:next_state <= MANUAL_DRIVING_PREPARED;
                  4'bxxxx:next_state <= MANUAL_DRIVING_STARTING;
                 endcase
          end
       MANUAL_DRIVING_MOVING:
           begin
              tmp = {throttle,brake,clutch,reverse_gear_shift};
              res = 1'b1;
              casex(tmp)
               4'b01xx:next_state <= MANUAL_DRIVING_PREPARED;
               4'b0001:next_state <= OFF;
               4'b00xx:next_state <= MANUAL_DRIVING_STARTING;
               4'b0x1x:next_state <= MANUAL_DRIVING_STARTING;
               4'b1xxx:next_state <= MANUAL_DRIVING_MOVING;
              endcase
          end               
       default: 
       begin
       res = 1'b0;
       next_state <= state; 
       end
    endcase
    end

assign direction_left_light = turn_left & ~turn_right;
assign direction_right_light = turn_right & ~turn_left;
assign control_output = {res & ~reverse_gear_shift,res & reverse_gear_shift,turn_left,turn_right};
endmodule


