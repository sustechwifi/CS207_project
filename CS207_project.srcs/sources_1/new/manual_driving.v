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
    
    input clk,
    output reg direction_left_light,
    output reg direction_right_light
    );
    parameter   OFF    =   4'b0000;
    parameter   MANUAL_DRIVING_PREPARED     =   4'b0010;
    parameter   MANUAL_DRIVING_STARTING     =   4'b0011;
    parameter   MANUAL_DRIVING_MOVING     =   4'b0100;
    

    reg [3:0] tmp;
    reg res;
    reg [31:0]cnt;
    reg [31:0]cnt1;
    
initial
begin
cnt=1'b0;
direction_left_light=1'b0;
direction_right_light=1'b0;
end

always@(state)
    begin
       case(state)
     MANUAL_DRIVING_PREPARED:
          begin
              tmp = {throttle,brake,clutch,reverse_gear_shift};
              res = 1'b0;
              casex(tmp)
               4'b101x:next_state <= MANUAL_DRIVING_STARTING;
               4'b100x:next_state <= OFF;
               default:next_state <= MANUAL_DRIVING_PREPARED;
              endcase
              end  
      MANUAL_DRIVING_STARTING:
          begin
              tmp = {throttle,brake,clutch,reverse_gear_shift};
              res = 1'b0;
                casex(tmp)
                  4'b100x:next_state <= MANUAL_DRIVING_MOVING;
                  4'bx1xx:next_state <= MANUAL_DRIVING_PREPARED;
                  4'b1011:next_state <= MANUAL_DRIVING_MOVING;
                  default:next_state <= MANUAL_DRIVING_STARTING;
                 endcase
          end
       MANUAL_DRIVING_MOVING:
           begin
              tmp = {throttle,brake,clutch,reverse_gear_shift};
              res = 1'b1;
              casex(tmp)
               4'bx1xx:next_state <= MANUAL_DRIVING_PREPARED;
               4'b1001:next_state <= OFF;
               4'b00xx:next_state <= MANUAL_DRIVING_STARTING;
               4'b1010:next_state <= MANUAL_DRIVING_STARTING;
               default:
               next_state<=MANUAL_DRIVING_MOVING;
              endcase
          end               
       default: 
       begin
       res = 1'b0;
       next_state <= state; 
       end
    endcase
    end
    
always@(posedge clk)
begin

if(turn_left & ~turn_right)
begin
if(cnt==32'd4000_0000)
begin
cnt<=1'b0;
direction_left_light <=~direction_left_light;
end//count
else
begin
cnt<=cnt+1'b1;
end//else
end//cnt
else
direction_left_light <=1'b0;

if(turn_right & ~turn_left)
begin
if(cnt==32'd4000_0000)
begin
cnt<=1'b0;
direction_right_light <=~direction_right_light;
end//count
else
begin
cnt<=cnt+1'b1;
end

end//right
else
direction_right_light <=1'b0;

end//clk

assign control_output = {res & ~reverse_gear_shift,res & reverse_gear_shift,turn_left,turn_right};
endmodule


