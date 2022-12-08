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
input [31:0] cnt,
input [3:0]state,
output reg [3:0] state_output,
output [3:0] control_signal_output,

input place_barrier_signal,
input destroy_barrier_signal,
output reg place_barrier_ouput,
output reg destroy_barrier_ouput,

input [1:0] left_cnt,
input [1:0] right_cnt,
output reg [1:0] left_cnt_next,
output reg [1:0] right_cnt_next,

input front_detector,
input back_detector,
input left_detector,
input right_detector
    );
        parameter   AUTO_DRIVING     =   4'b1010;
        parameter   AUTO_FORWARD     =   4'b1011;
        parameter   AUTO_TURN_LEFT   =   4'b1100;
        parameter   AUTO_TURN_RIGHT  =   4'b1101;
        parameter   AUTO_TURN_BACK   =   4'b1110;
        
        reg [3:0] next_state;
        reg [3:0] res;
        
        always@(state)begin
        place_barrier_ouput <= place_barrier_signal;
        destroy_barrier_ouput <= destroy_barrier_signal;
             case(state)
             AUTO_DRIVING:
                begin
                  //TODO
                  res <= 4'b0000;
                  state_output <= next_state;
                end
             AUTO_FORWARD:
                begin
                    res <= 4'b1000;
                    state_output <= next_state;
                end
             AUTO_TURN_LEFT:
                begin
                    if(cnt > 32'd8000_0000)
                    begin
                        state_output <= AUTO_DRIVING;
                        if(cnt < 32'd1_5000_0000)
                        begin
                            place_barrier_ouput = 1'b1;
                            state_output <= AUTO_TURN_LEFT;
                            res <= 4'b1000;
                        end
                    end
                    else begin
                        res <= 4'b0010;
                        state_output <= AUTO_TURN_LEFT;
                        place_barrier_ouput = 1'b0;
                    end
                end
              AUTO_TURN_RIGHT:
                     begin
                        if(cnt > 32'd8000_0000)
                         begin
                             state_output <= AUTO_DRIVING;
                             if(cnt < 32'd1_5000_0000)
                             begin
                                place_barrier_ouput <= 1'b1;
                                state_output <= AUTO_TURN_LEFT;
                                res <= 4'b1000;
                             end
                         end
                        else begin
                             res <= 4'b0001;
                             state_output <= AUTO_TURN_RIGHT;
                             place_barrier_ouput = 1'b0;
                        end
                     end
              AUTO_TURN_BACK:
                      begin
                        if(cnt > 32'd1_7000_0000)
                         begin
                           state_output <= AUTO_DRIVING;
                           place_barrier_ouput <= 1'b0;
                         end
                        else begin
                           res <= 4'b0001;
                           state_output <= AUTO_TURN_BACK;
                         end
                      end
             default : begin
             state_output <= state;
             res <= 4'b0000;
             end
             endcase
        end
        
       always@(front_detector,back_detector,left_detector, right_detector)begin
            left_cnt_next <= left_cnt;
            right_cnt_next <= right_cnt;
            if(state == AUTO_DRIVING || state == AUTO_FORWARD)begin
            casex({front_detector,back_detector,left_detector, right_detector})
              4'b1011: begin next_state <= AUTO_TURN_BACK;right_cnt_next = right_cnt + 2'b10; end  // |~|
              4'b0x11: next_state <= AUTO_FORWARD;   // | |
              4'b1x01: begin left_cnt_next <= left_cnt + 2'b01; next_state <= AUTO_TURN_LEFT;end   //  <-~~~|
              4'b1x10: begin right_cnt_next <= right_cnt + 2'b01; next_state <= AUTO_TURN_RIGHT;  end //  |~~~->
              4'b0110: next_state <= AUTO_FORWARD;   //  |__->
              4'b0101: next_state <= AUTO_FORWARD;   //   <-__|
              //belows are in crossing
              4'b1x00, 4'b0x00,4'b0x01,4'b0x10: begin
                case(left_cnt^right_cnt)
                2'b00: // north
                    begin
                        if(right_detector)
                            next_state <= AUTO_FORWARD;
                        else begin right_cnt_next <= right_cnt + 2'b01; next_state <= AUTO_TURN_RIGHT;end
                    end
                2'b10: // south
                    begin
                        if(left_detector)
                          next_state <= AUTO_FORWARD;
                        else begin left_cnt_next <= left_cnt + 2'b01; next_state <= AUTO_TURN_LEFT;end
                    end
                2'b01: 
                      case({left_cnt,right_cnt})
                      4'b0001,4'b1011: // east
                        begin
                         if(front_detector)
                           begin left_cnt_next <= left_cnt + 2'b01; next_state <= AUTO_TURN_LEFT;end
                         else next_state <= AUTO_FORWARD;
                        end
                       4'b0100,4'b1110: // west
                        begin
                         if(right_detector)
                            next_state <= AUTO_FORWARD;
                         else begin right_cnt_next <= right_cnt + 2'b01; next_state <= AUTO_TURN_RIGHT;end
                        end 
                      endcase
                2'b11:
                    case({left_cnt,right_cnt})
                       4'b0011,4'b1001: // west
                          begin
                             if(right_detector)
                               next_state <= AUTO_FORWARD;
                             else begin right_cnt_next <= right_cnt + 2'b01; next_state <= AUTO_TURN_RIGHT;end
                          end              
                       4'b0110,4'b1100: // east
                         begin
                            if(front_detector)
                              begin left_cnt_next <= left_cnt + 2'b01; next_state <= AUTO_TURN_LEFT;end
                            else next_state <= AUTO_FORWARD;
                         end
                       endcase
                endcase
              end
              default next_state <= AUTO_FORWARD;      
            endcase
            end
            else begin
            next_state <= state;
            end
        end

assign control_signal_output = res;

endmodule
