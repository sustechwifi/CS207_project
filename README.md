# Sustech 2022-fall CS207 Digital logic

## Project: Smart car simulating

- 游俊涛 12110919 : Manual Driving & Auto Driving & Structure design
- 陶文晖 12111744 : Semi Driving & Auto Driving & VGA

**[Source code](https://github.com/sustechwifi/CS207_project)**

```
https://github.com/sustechwifi/CS207_project
```

---

## Part 1. Overview

project_impl.v  (top module)

> Pins & Variables
> 
> State table & machine
> 
> Sub modules
---

### Pins & Variables

- Module definition

```
module project_impl(
    input sys_clk,
    input rx, 
    output tx,
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
    output direction_right_light
);
```

- Inner variables

    + States control and power-signal counter
    ```
    reg [31:0] cnt = 0;
    reg [3:0] state,next_state; 
    wire[3:0] state_from_manual;
    wire[3:0] state_from_semi_auto;
    wire[3:0] state_from_auto;
    ```

    + Mileages counter

    ```
    parameter period = 250000; //400Hz
    reg [31:0] male;
    reg [3:0] seg_7;
    reg clkout;
    reg [2:0] scan_cnt;
    reg [31:0] tim;
    reg [31:0] male_cnt;
    ```

    + Control signals from automatic state machine

    ```
    reg [3:0] control_signal;
    wire[3:0] control_signal_from_manual;
    wire[3:0] control_signal_from_semi_auto;
    wire[3:0] control_signal_from_auto;
    wire front_detector,back_detector,left_detector,right_detector;
    reg place_barrier_signal;
    reg destroy_barrier_signal;
    wire place_barrier_signal_from_auto;
    wire destroy_barrier_signal_from_auto;
    ```

### State table

| Parameter Name          | state code | description        |
|-------------------------|------------|--------------------|
| OFF                     | 4'b0000    | Power-off          |
| ON                      | 4'b0001    | Power-on           |
| MANUAL_DRIVING_PREPARED | 4'b0010    | Manual Neutral     |
| MANUAL_DRIVING_STARTING | 4’b0011    | Manual start       |
| MANUAL_DRIVING_MOVING   | 4'b0100    | Moving             |
| SEMI_AUTO               | 4'b0101    | Semi-auto start    |
| AUTO_DRIVING            | 4'ha       | Auto-driving start |


### State machine

```
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
```

### Sub modules

```
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

semi_auto_driving semi(
   sys_clk, 
   front_detector,
   back_detector,
   left_detector,
   right_detector, 
   go_strait,
   turn_left,turn_right,
   state_from_semi_auto,
   control_signal_from_semi_auto
);

auto_driving auto(
  sys_clk, 
  front_detector,
  back_detector,
  left_detector,
  right_detector,
  control_signal_from_auto,
  place_barrier_signal_from_auto,
  destroy_barrier_signal_from_auto,
  state_from_auto
);

SimulatedDevice utrl(
 //...
);
endmodule
```

---

## Part 1. Power & Manual Driving

project_impl.v &  manual_driving.v

> Power-on and Power-off (button)
> 
> Throttle, Clutch, Brake (switch)
> 
> Turning, Mileage (LED, seg-tubes)

### States used


| Parameter Name          | state code | description        |
|-------------------------|------------|--------------------|
| OFF                     | 4'b0000    | Power-off          |
| ON                      | 4'b0001    | Power-on           |
| MANUAL_DRIVING_PREPARED | 4'b0010    | Manual Neutral     |
| MANUAL_DRIVING_STARTING | 4’b0011    | Manual start       |
| MANUAL_DRIVING_MOVING   | 4'b0100    | Moving             |

### Power control 

- Defined in `top module`.

 Use counter `reg [31:0] cnt` to record single second.
 In this part, state will be updated by `next_state` or clear to `OFF`.

(Sequential logic)
```
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
```

### Throttle, Clutch, Brake control

- Defined in module `manual_driving`.

Input the current `state` with control signal and output `next_state`.
Finite state machine implemented below.

(Combinatorial logic)
```
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
```

### Mileage record

- Defined in top module.

If current state is `MANUAL_DRIVING_MOVING`, mileage variable `reg [32:0] mile` will increase each period.
`seg_7` will update in each second, which refer the signal of seg-tubes in EGO1.

(Sequential logic)
```
always@(posedge sys_clk, negedge rx)
    begin
        if(~rx)
        begin
           male <= 0;
           clkout <= 0;
        end
        else 
          begin
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
             else 
                begin
                    male <= male + 1;
                    male_cnt <= male_cnt + 1;
                end
        end
        default:
            begin
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
        else 
            begin
            if(scan_cnt == 3'd7)
                scan_cnt <= 0;
            else
                scan_cnt <= scan_cnt + 3'd1;
        end
    end
   
reg [7:0]num;
   
always @(scan_cnt)
   begin
        case(scan_cnt)
           3'b000: begin seg_en = 8'h01; num = tim ;      end
           3'b001: begin seg_en = 8'h02; num = tim >> 4;  end
           3'b010: begin seg_en = 8'h04; num = tim >> 8;  end
           3'b011: begin seg_en = 8'h08; num = tim >> 12; end
           3'b100: begin seg_en = 8'h10; num = tim >> 16; end
           3'b101: begin seg_en = 8'h20; num = tim >> 20; end
           3'b110: begin seg_en = 8'h40; num = tim >> 24; end
           3'b111: begin seg_en = 8'h80; num = tim >> 28; end
            default : seg_en = 8'h00;
        endcase
end

wire [7:0] useless_seg_en0, useless_seg_en1;
light_7seg_ego1 l1({1'b0,num},seg_out0,useless_seg_en0);
light_7seg_ego1 l2({1'b0,num},seg_out1,useless_seg_en1);
```


### Direction control

- Defined in module `manual_driving`

In this part, gate-level circuits is used to update `direction_left_light` and `direction_right_light`,which connect in LED signal. And `wire [3:0] control_output` is used for `URAT` module controlling.

(Combinatorial logic)

```
assign direction_left_light = turn_left & ~turn_right;
assign direction_right_light = turn_right & ~turn_left;
assign control_output = {res & ~reverse_gear_shift,res & reverse_gear_shift,turn_left,turn_right};
```


## Part 2: Semi-auto driving

semi_auto_driving.v

> State detect
> 
> Semi-auto driving command (multi button)

---

- States used

| Parameter Name  | state code | description                                      |
|-----------------|------------|--------------------------------------------------|
| WAIT            | 3'b000     | Waiting for choose direction.                    |
| CHECK           | 3'b001     | Open detector when moving                        |
| CLOSE_DETECT    | 3'b010     | Close detector until made choice.                |                           |
| COUNT           | 3'b100     | Keep counting when turning.                      |
| DOUBLECOUNT     | 3'b111     | Keep counting when turning twice.                |
| DECIDE          | 3'b011     | When turning left/right, keep going for a while. |
| THINK           | 3'b110     | Stop for a while when auto-turning.              |
| SEMI_AUTO       | 4'b0101    | Semi-auto driving prepared.                      |

- Details

When car keeps moving, its state will be `CHECK`.

When surroundings has change: Using detectors' signal from 4 directions `{front_detector,back_detector,left_detector,right_detector}` , it will switch state into `WAIT` in crossing, or `THINK` with auto-turning into corresponding direction at corner.
For example, when the 4 bits signal is `4'b0011` ,which means that the car should keep moving.

After user choose direction, it will switch state into `COUNT` or `DOUBLECOUNT`.

When turning, the detector will be closed with its state stay in  `COUNT` or `DOUBLECOUNT`.

Keep turning with enough time, it will switch state into `CHECK` again and open its detector.

(Sequential logic)
```
always@(posedge sys_clk)
    begin case(state)
    CHECK:
      case({front_detector,back_detector,left_detector,right_detector})
        4'b0011,4'b0111: move<=3'b100;
        4'b1001,4'b1101, 4'b1011, 4'b1010,4'b1110: begin move<=3'b000; state<=THINK;end
      default: begin state<=WAIT; move<=3'b000; end
      endcase
      
    CLOSE_DETECT:
      if(cnt<LAST) begin move<=3'b100; cnt<=cnt+32'd1; end
      else begin cnt<=32'd0; state<=CHECK;end
      
    COUNT:
      if(cnt<TURN) cnt<=cnt+32'd1;
      else begin cnt<=32'd0; state<=CLOSE_DETECT; end
      
    THINK:
     if(cnt<TURN) cnt<=cnt+32'd1;
     else begin cnt<=32'd0; state<=DECIDE; end
     
    DOUBLECOUNT:
    if(cnt<DOUBLETURN) cnt<=cnt+32'd1;
      else begin cnt<=32'd0; state<=CLOSE_DETECT; end
    
    DECIDE:
       case({front_detector,back_detector,left_detector,right_detector})
        4'b0011,4'b0111:  move<=3'b100;
        4'b1001,4'b1101:beginmove<=3'b010;state<=COUNT;end
        4'b1011: begin move<=3'b010; state<=DOUBLECOUNT; end
        4'b1010,4'b1110: begin move<=3'b001;state<=COUNT; end
        default:beginstate<=WAIT;move<=3'b000;end
      endcase
      
    WAIT:
      case({go_strait,turn_left,turn_right})
        3'b100: state<=CLOSE_DETECT;
        3'b010: begin move<=3'b010; state<=COUNT;end
        3'b001: begin move<=3'b001; state<=COUNT; end
      endcase
    endcase
   end
```

## Part 3 (Bonus): Automatic driving

auto_driving.v

> State analysis
> 
> Place & Destroy beacon (to UART)

- State used

| Parameter Name | state code  | description                                      |
|----------------|-------------|--------------------------------------------------|
| CHECK          | 4'b0001     | Open detector when moving                        |
| CLOSE_DETECT   | 4'b0010     | Close detector until made choice.                |                           |
| COUNT          | 4'b0100     | Keep counting when turning.                      |
| DOUBLECOUNT    | 4'b1111     | Keep counting when turning twice.                |
| DECIDE         | 4'b0011     | When turning left/right, keep going for a while. |
| THINK          | 4'b1100     | Stop for a while when auto-turning.              |
| BACON          | 4'b0101     | Place a new bacon.                               |
| DESTORY        | 4'b1101     | Collect the last bacon.                          |

- Details

Some details ,like auto-turing, counter and detector, are similar with semi-auto driving mode mentioned above. Find these parts in `Part 2: semi-auto driving`.

When in crossing, it will firstly place a bacon with state `BACON` and then turn `right`. Follow this process and destroy the latest bacon with state `DESTORY` in impasse.   

(Sequential logic)
```
 always@(posedge sys_clk)
        begin
        case(state)
        
    CHECK://...
    CLOSE_DETECT://...
    COUNT://...               
    THINK://...
    DOUBLECOUNT: //...
        
    DECIDE:
         case({front_detector,back_detector,left_detector,right_detector})
           begin
              //... 
              4'b1010,4'b1110:begin move<=3'b001; state<=BACON; end
              4'b1001,4'b1101:begin move<=3'b010; state<=BACON; end  
              4'b1011,4'b1111:begin move<=3'b010; state<=DESTORY; end
              //...
               endcase
    BACON:
         if(cnt<TURN) begin cnt<=cnt+32'd1; place_barrier_signal<=1'b1; end
         else begin cnt<=32'd0; place_barrier_signal<=1'b0; state<=CLOSE_DETECT; end
                                    
    DESTORY: begin
        if(cnt<TURN) begin
            cnt<=cnt+32'd1;
            move<=3'b000;
            destroy_barrier_signal<=1'b1;
          end
         else begin
            move<=3'b010;
            cnt<=32'd0;
            destroy_barrier_signal<=1'b0; 
            state<=DOUBLECOUNT;
         end
   end
```

- URAT control signal output

```
assign control_signal_from_auto={move[2],1'b0,move[1],move[0]};
assign place_barrier_signal_from_auto=place_barrier_signal;
assign destroy_barrier_signal_from_auto=destroy_barrier_signal;
assign state_from_auto=4'b1010;
```

## Part 4 (Bonus): VGA

VGA interface

>Task1. VGA available 
>> Use switch to control VGA to display something.
> 
> Task2. use VGA to show the state
>> Let VGA show the state of the car.
> 
> Task3. use VGA to show the Mileage record
>> Let VGA show the Mileage record. (real-time synchronization)

---

```
//TO BE CONTINUE......
```

## Part 5: Summary

> Timeline
> 
> Insights
> 
> Conclusion
---

+ Time & version control

![img_4.png](img_4.png)

+ Finding & Insights

```
TODO 
```

+ Conclusion

阿巴阿巴阿巴阿巴阿巴阿巴阿巴阿巴。
