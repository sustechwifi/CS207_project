# Sustech 2022-fall CS207 Digital logic

## Project: Smart car simulating

- 游俊涛 12110919 (50%) :  Manual Driving & Auto Driving & Structure design 
- 陶文晖 12111744 (50%) :  Semi Driving & Auto Driving & VGA

**[Source code](https://github.com/sustechwifi/CS207_project)**

```
https://github.com/sustechwifi/CS207_project
```

---
## Part 0. Overview

<img src="img_8.png" alt="img_8.png" style="zoom: 50%;" />


## Part 1. Top module design

project_impl.v  

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
    input sys_clk,                  system clock pulse of 100M Hz.            P17
    input rx,                       reset signal.                             N5
    output tx,                      UATL tx output.                           T4          
    input power_on,                 power-on signal.                          U4              button
    input power_off,                power-off signal.                         R14             button
    input [2:0] mode,               select 3 dirving modes.                   {P4,P3,P2}      switch
    output[3:0] test,               show current state in LED.                {F6,G4.G3,J4}   LED 
    input throttle,                 throttle signal in manual driving.        R2              switch
    input brake,                    brake signal in manual driving.           M4              switch
    input clutch,                   clutch signal in manual driving           N4              switch
    input reverse_gear_shift,       turn-back signal in manual driving        R1              switch
    input turn_left,                turn left signal in manual/semi-auto      V1              button
    input turn_right,               turn right signal in manual/semi-auto     R11             button
    input go_strait,                go ahead signal in semi-auto driving      R15             button
    output reg [7:0] seg_en,        mileage tubes enable siganl               {G2-G6}         
    output [7:0] seg_out0,          right group of mileage tubes              {B4-D5}         7seg-tube
    output [7:0] seg_out1,          left group of mileage tubes               {D4-H2}         7seg-tube
    output direction_left_light,    left turn signals when manual driving.    V1              LED
    output direction_right_light    right turn signals when manual driving.   R11             LED
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
    reg [31:0] mile;
    reg [3:0] seg_7;
    reg clkout;
    reg [2:0] scan_cnt;
    reg [31:0] tim;
    reg [31:0] mile_cnt;
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
   OFF & ON://...
         
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

Current `state` in state machine will be the input in each sub-module. And `next_state` and `control_signal` will be updated by sub-module outputs.

If the `state` is not in the work states of a sub-module, the output state in this module will not change. 

- manual_driving.v
```
manual_driving manual(
    state,                         current state in top module.
    state_from_manual,             output next state from manual-driving.
    control_signal_from_manual,    output control signal from manual-driving.
    throttle,                      
    brake,
    clutch,
    reverse_gear_shift,
    turn_left,
    turn_right,
    direction_left_light,
    direction_right_light
);   

```

+ semi_auto_driving.v
```
semi_auto_driving semi(
   sys_clk, 
   front_detector,                   detector's signal from UART
   back_detector,
   left_detector,
   right_detector, 
   go_strait,                        
   turn_left,
   turn_right,
   state_from_semi_auto,              output next state from semi-auto driving.
   control_signal_from_semi_auto      output control signal from semi-auto driving.
);

```

+ auto_driving.v
```
auto_driving auto(
  sys_clk, 
  front_detector,
  back_detector,
  left_detector,
  right_detector,
  control_signal_from_auto,                    output control signal from auto driving.
  place_barrier_signal_from_auto,              output placing barrier signal from auto driving.
  destroy_barrier_signal_from_auto,            output destroying barrier signal from auto driving.
  state_from_auto                              output next state from auto driving.
);
```

+ SimulatedDevice.v 
---

## Part 2. Power & Manual Driving

project_impl.v &  manual_driving.v

> Power-on and Power-off (button)
> 
> Throttle, Clutch, Brake (switch)
> 
> Turning, Mileage (LED, seg-tubes)

### State diagram 

<img src="img_6.png" alt="img_6.png" style="zoom:50%;" />

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

If `cnt` is enough, Change `state` to `ON`.

(Sequential logic)
```
always@(posedge sys_clk or posedge power_off)
    if (power_off) begin state <= OFF; cnt <= 32'd0; end
    else if(power_on) 
     begin
       if(cnt > 32'd1_0000_0000 && state == OFF) 
          begin state <= ON; cnt <= 32'd0; end
       else cnt <= cnt + 32'd1;
     end
    else  begin cnt <= 32'd0; state <= next_state; end
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
          begin tmp = {throttle,brake,clutch,reverse_gear_shift};
              res = 1'b0;
              casex(tmp)
               4'b101x:next_state <= MANUAL_DRIVING_STARTING;
               4'b1x0x:next_state <= OFF;
               4'bxxxx:next_state <= MANUAL_DRIVING_PREPARED;
              endcase
          end  
      MANUAL_DRIVING_STARTING: //... omitted
      MANUAL_DRIVING_MOVING:  //.... omitted 
      default: begin res = 1'b0; next_state <= state; end
    endcase
   end
```

### Mileage record

- Defined in top module.

If current state is `MANUAL_DRIVING_MOVING`, mileage variable `reg [32:0] mile` will increase each period.

Using `scan_cnt` to match `period` with 250 Hz, and `mile_cnt` to update mileage every second.

(Sequential logic)
```
always@(posedge sys_clk, negedge rx)
    begin
        if(~rx) begin mile <= 0; clkout <= 0; end
        else 
     case(state)
        MANUAL_DRIVING_MOVING:
        begin
            if(mile == (period>>1)-1)
               begin
                    clkout <= ~ clkout;
                    mile <= 0;
               end
             else if(mile_cnt > 32'd1_0000_0000)
                begin
                    mile_cnt <= 0;
                    tim <= tim + 1;
                end
             else 
                begin
                    mile <= mile + 1;
                    mile_cnt <= mile_cnt + 1;
                end
        end
        default: begin mile <= 32'd0; tim <= 0; mile_cnt <= 0; end
      endcase
    end
    
always @(posedge clkout,negedge rx) begin 
    if(~rx) scan_cnt <= 0;
        else  begin
            if(scan_cnt == 3'd7) scan_cnt <= 0;
            else scan_cnt <= scan_cnt + 3'd1;
        end
    end
```


`reg [7:0] seg_7` will be updated in each second, which refer the signal and show different hexadecimal number of seg-tubes in EGO1.

Using `>>` operator to catch number specific location. e.g, current mile number is `32'd 0000 1145`, `scan_cnt` is `3'b011`. This time only the 3rd is able to light with number 1, we use `mile >> 12` to get the hexadecimal bit `1`.

(Sequential logic)
```
reg [7:0]num;  
always @(scan_cnt)
   begin
        case(scan_cnt)
           3'b000: begin seg_en = 8'h01; num = tim ;      end
           3'b001: begin seg_en = 8'h02; num = tim >> 4;  end
           3'b010: begin seg_en = 8'h04; num = tim >> 8;  end
           3'b011: begin seg_en = 8'h08; num = tim >> 12; end
           //...omitted
            default : seg_en = 8'h00;
        endcase
end

wire [7:0] useless_seg_en0, useless_seg_en1;
light_7seg_ego1 l1({1'b0,num},seg_out0,useless_seg_en0);
light_7seg_ego1 l2({1'b0,num},seg_out1,useless_seg_en1);
```


### Direction control

- Defined in module `manual_driving`

In this part, gate-level circuits is used to update `direction_left_light` and `direction_right_light`,which connect in LED signal. And `wire [3:0] control_output` is used for `UART` module controlling.

(Combinatorial logic)

```
assign direction_left_light = turn_left & ~turn_right;
assign direction_right_light = turn_right & ~turn_left;
assign control_output = {res & ~reverse_gear_shift,res & reverse_gear_shift,turn_left,turn_right};
```


## Part 3. Semi-auto driving

semi_auto_driving.v

> State detect
> 
> Semi-auto driving command (multi button)

---

- State diagram

<img src="img_7.png" alt="img_7.png" style="zoom:50%;" />


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
      
    CLOSE_DETECT: //... omitted
    COUNT: //... omitted
    THINK: //... omitted
    DOUBLECOUNT: //... omitted
    
    DECIDE:
       case({front_detector,back_detector,left_detector,right_detector})
        4'b0011,4'b0111:  move<=3'b100;
        4'b1001,4'b1101:beginmove<=3'b010;state<=COUNT;end
        4'b1011: begin move<=3'b010; state<=DOUBLECOUNT; end
        4'b1010,4'b1110: begin move<=3'b001;state<=COUNT; end
        default:beginstate<=WAIT;move<=3'b000;end
      endcase
      
    WAIT: //... omitted
    endcase
   end
```

## Part 3 (Bonus). Automatic driving

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
| BEACON         | 4'b0101     | Place a new beacon.                              |
| DESTORY        | 4'b1101     | Collect the last beacon.                         |

- Details

Some details ,like auto-turing, counter and detector, are similar with semi-auto driving mode mentioned above. Find these parts in `Part 2: semi-auto driving`.

When in crossing, it will firstly place a beacon with state `beacon` and then turn `right`. Follow this process and destroy the latest beacon with state `DESTORY` in impasse.   

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
              //... omitted
              4'b1010,4'b1110:begin move<=3'b001; state<=beacon; end
              4'b1001,4'b1101:begin move<=3'b010; state<=beacon; end  
              4'b1011,4'b1111:begin move<=3'b010; state<=DESTORY; end
              //... omitted
               endcase
    beacon:
         if(cnt<TURN) begin cnt<=cnt+32'd1; place_barrier_signal<=1'b1; end
         else begin cnt<=32'd0; place_barrier_signal<=1'b0; state<=CLOSE_DETECT; end
                                    
    DESTORY: begin
        if(cnt<TURN) begin cnt<=cnt+32'd1; move<=3'b000; destroy_barrier_signal<=1'b1; end
        else begin move<=3'b010; cnt<=32'd0; destroy_barrier_signal<=1'b0; state<=DOUBLECOUNT; end
   end
```

- URAT control signal output

```
assign control_signal_from_auto={move[2],1'b0,move[1],move[0]};
assign place_barrier_signal_from_auto=place_barrier_signal;
assign destroy_barrier_signal_from_auto=destroy_barrier_signal;
assign state_from_auto=4'b1010;
```

## Part 4 (Bonus). VGA

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

## Part 5. Summary

> Timeline
> 
> Insights
> 
> Conclusion
---

+ Time & version control

<img src="img_4.png" alt="img_4.png" style="zoom:50%;" />

+ Finding & Insights

```
TODO 
```

+ Conclusion

阿巴阿巴阿巴阿巴阿巴阿巴阿巴阿巴。
