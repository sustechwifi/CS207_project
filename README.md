# Sustech 2022-fall CS207 Digital logic

## Project: Smart car simulating

- 游俊涛 12110919 (50%) :  Manual Driving & Auto Driving & Structure design 
- 陶文晖 12111744 (50%) :  Semi Driving & Auto Driving & VGA

**[Source code](https://github.com/sustechwifi/CS207_project)**

```
https://github.com/sustechwifi/CS207_project
```

## Catalogue
Part 0. Overview and User Manual

Part 1. Top module design

Part 2. Power & Manual Driving

Part 3 (Bonus). Automatic driving

Part 4 (Bonus). VGA

Part 5. Summary

---
## Part 0. Overview

<img src="VGA IMAGES/EP.png" style="zoom: 67%;" />

<img src="../../Documents/Tencent Files/2587433598/FileRecv/用户使用.jpg" style="zoom:67%;" />

## Part 1. Top module design

project_impl.v  

> Pins & Variables
> 
> State table & machine
> 
> Sub modules
---
<img src="../../Documents/Tencent Files/2587433598/FileRecv/组织结构图.jpg" style="zoom:80%;" />

### Pins & Variables

- Module definition

```
module project_impl(
input sys_clk,               clock pulse of 100M Hz.        P17
input rx,                    reset signal.                  N5
output tx,                   UATL tx output.                T4          
input power_on,              power-on signal.               U4            
input power_off,             power-off signal.              R14           
input [2:0] mode,            select 3 dirving modes.        {P4,P3,P2}    
output[3:0] test,            show current state in LED.     {F6,G4.G3,J4} 
input throttle,              throttle signal in manual.     R2            
input brake,                 brake signal in manual .       M4            
input clutch,                clutch signal in manual.       N4            
input reverse_gear_shift,    turn back signal in manual.    R1            
input turn_left,             left signal in manual/semi.    V1            
input turn_right,            right signal in manual/semi.   R11           
input go_strait,             go ahead signal in semi-auto.  R15           
output reg [7:0] seg_en,     mileage tubes enable siganl.   {G2-G6}         
output [7:0] seg_out0,       right group of mileage tubes.  {B4-D5}       
output [7:0] seg_out1,       left group of mileage tubes.   {D4-H2}       
output direction_left_light, left turn signals in manual.   V1            
output direction_right_light right turn signals in manual.  R11
output reg [3:0]r,g,b        VGA RGB colour                 {F5-E7}
output reg hs,vs             VGA hs and vs                  D7,C4 
input contrl                 VGA state                      P5
);
```

<img src="VGA IMAGES/part1.jpg" style="zoom:50%;" />

- Inner variables

    + States control and power-signal counter
    ```
    reg [31:0] cnt = 0; // counter of Power-on button
    reg [3:0] state,next_state; // current state and next_state
    wire[3:0] state_from_manual;   // next_state output from manual-driving 
    wire[3:0] state_from_semi_auto;
    wire[3:0] state_from_auto;
    ```

    + Mileages counter

    ```
    parameter period = 250000; //400Hz
    reg [31:0] mile; // counter of tim
    reg [3:0] seg_7;
    reg clkout; // clock pulse in each period.
    reg [2:0] scan_cnt; // enable a specific tube.
    reg [31:0] tim; // mileages amount, +1 after single second.
    reg [31:0] mile_cnt; // +1 after single period
    ```

    + Control signals from automatic state machine

    ```
    reg [3:0] control_signal; // 4 direction control input signal to UART
    wire[3:0] control_signal_from_manual; // control signal output from manual
    wire[3:0] control_signal_from_semi_auto;
    wire[3:0] control_signal_from_auto;
    wire front_detector,back_detector,left_detector,right_detector;
    reg place_barrier_signal,destroy_barrier_signal;
    wire place_barrier_signal_from_auto,destroy_barrier_signal_from_auto;
    ```
  
  + VGA
  ```
  reg [2:0]num;
  reg [2:0] mile_0, mile_1, mile_2, mile_3, mile_4, mile_5, mile_6, mile_7; 
  //seg_7 octal numbers
  wire [23:0] VGA_signal;
  wire [3:0]r1,r2,g1,g2,b1,b2;
  wire vs1,vs2,hs1,hs2;
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

<img src="../../Documents/Tencent Files/2587433598/FileRecv/主模块状态流程图.png" style="zoom: 33%;" />

`next_state` and `control_signal` are updated by each mode.

```
always@(state,mode)
    begin
       casex(state)
   OFF & ON: //...
   MANUAL_DRIVING_PREPARED, MANUAL_DRIVING_STARTING, MANUAL_DRIVING_MOVING :   
       begin 
            next_state <= state_from_manual; 
            control_signal <= control_signal_from_manual;
       end
   SEMI_AUTO: //... similar with above
   AUTO_DRIVING:
       begin
            //...  similar with above
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
    state,                         //current state in top module.
    state_from_manual,             //output next state from manual.
    control_signal_from_manual,    //output control signal from manual.
    throttle,brake,clutch,reverse_gear_shift,
    turn_left,turn_right,
    direction_left_light,direction_right_light
);   

```

+ semi_auto_driving.v
```
semi_auto_driving semi(
   sys_clk, 
   front_detector,back_detector,left_detector, right_detector, 
   //detector's signal from UART
   go_strait,                        
   turn_left, turn_right,
   state_from_semi_auto,          //output next state from semi-auto driving.
   control_signal_from_semi_auto  //output control signal from semi-auto.
);

```

+ auto_driving.v

输入为sys_clk时钟信号，前后左右探测器信号（均为1bit）

输出前后左右移动信号（4bit）,放置，摧毁路障信号(均1bit), `[3:0]state`状态信号。

```
auto_driving auto(
  sys_clk, 
  front_detector,back_detector,left_detector,right_detector,
  control_signal_from_auto,               //output control signal from auto driving.
  place_barrier_signal_from_auto,         //output placing barrier signal from auto.
  destroy_barrier_signal_from_auto,       //output destroying barrier signal from auto.
  state_from_auto                         //output next state from auto driving.
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

<img src="img/img_6.png" alt="img_6.png" style="zoom:50%;" />

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

MANUAL_DRIVING_STARTING, MANUAL_DRIVING_MOVING are omitted

(Combinatorial logic)
```
always@(state)
    begin
       case(state)
     MANUAL_DRIVING_PREPARED:
          begin tmp = {throttle,brake,clutch,reverse_gear_shift};
              casex(tmp)
               4'b101x:next_state <= MANUAL_DRIVING_STARTING;
               4'b1x0x:next_state <= OFF;
               4'bxxxx:next_state <= MANUAL_DRIVING_PREPARED;
              endcase
          end  
     MANUAL_DRIVING_STARTING, MANUAL_DRIVING_MOVING:  //.... omitted 
     default: begin res = 1'b0; next_state <= state; end
   endcase
  end
```

### Mileage record

- Defined in top module.

If current state is `MANUAL_DRIVING_MOVING`, mileage variable `reg [32:0] mile` will increase each period.

Using `scan_cnt` to match `period` with 250 Hz, and `mile_cnt` to update mileage every second.

Some codes are the reused in `lab12`.

(Sequential logic)
```
always@(posedge sys_clk, negedge rx)
    begin if(~rx) begin mile <= 0; clkout <= 0; end
    else 
     case(state)
       MANUAL_DRIVING_MOVING:
        begin
            if(mile == (period>>1)-1) //... see in lab12
            else if(mile_cnt > 32'd1_0000_0000) // update tim
            else // update mile_cnt and mile 
        end
       default: begin mile <= 32'd0; tim <= 0; mile_cnt <= 0; end
     endcase
   end
    
always @(posedge clkout,negedge rx) begin 
     //... see in lab12
  end
```


`reg [7:0] seg_7` will be updated in each second, which refer the signal and show different hexadecimal number of seg-tubes in EGO1.

Using `>>` operator to catch number specific location. e.g, current mile number is `32'd 0000 1145`, `scan_cnt` is `3'b011`. This time only the 3rd is able to light with number 1, we use `mile >> 12` to get the hexadecimal bit `1`.

(Sequential logic)
```
always @(scan_cnt) begin
    mile_0 = tim; mile_1 = tim >> 3;mile_2 = tim >> 6;mile_3 = tim >> 9;
    mile_4 = tim >> 12; mile_5 = tim >> 15;mile_6 = tim >> 18; mile_7 = tim >> 21;
    case(scan_cnt)
      3'b000: begin seg_en = 8'h01; num = tim ;end
      3'b001: begin seg_en = 8'h02; num = tim >> 3; end
      3'b010: begin seg_en = 8'h04; num = tim >> 6; end
      3'b011 - 3'b111: //... omitted
      default : seg_en = 8'h00;
    endcase
   end
assign VGA_signal = {mile_7,mile_6,mile_5,mile_4,mile_3,mile_2,mile_1,mile_0};
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

<img src="VGA IMAGES/半自动流程图(改).png" style="zoom:33%;" />


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

For example, when the 4 bits signal is `4'b0011`, which means that the car should keep moving.

After user choose direction, it will switch state into `COUNT` or `DOUBLECOUNT`.

When turning, the detector will be closed with its state stay in  `COUNT` or `DOUBLECOUNT`.

Keep turning with enough time, it will switch state into `CHECK` again and open its detector.

Counters' implement parts are omitted.

输入为前后左右四个探测器（均1bit），用户输入的前进（go_strait），左转(turn_left)，右转(turn_right)，
输出小车行动指令（[3:0] control_signal_from_semi_auto），以及当前半自动状态（[3:0]state_output）

半自动模式输出一个4比特的移动信号，对应前后左右。

最初状态为探测状态（打开探测器）：

探测结果：

仅能直走时：直走；

仅能转弯时：转到思考状态

有岔路：进入等待状态

等待状态：

用户输入结果：

左转：输出左转信号，进入计时状态；

右转：输出右转信号，进入计时状态；

直走：进入关闭探测前进状态；

回头：输出左转信号，进入双倍计时状态；

计时状态：

不对输出信号进行改变，仅计数0.8s

计时结束进入关闭探测前进状态；

双倍计时状态：

不对输出信号进行改变，仅计数1.7s

计时结束进入关闭探测前进状态；

思考状态：

用于等待探测器稳定，仅计数0.8s

确定得到稳定结果后进入决策模式；

决策模式：

探测结果：

仅能转弯时：转弯；

仅能直走时：直走（进入关闭探测前进状态）；

遇见死路：回头（输出左转信号，进入双倍计时状态）；

左转示例：

通过将移动输出变为0010后进入持续0.8s的计时状态，

计时完毕后进入持续0.4s的关闭探测器直走状态，

右转类似，直走则直接进入关闭探测器直走状态。

之后进入开启探测器状态，

检查到岔路口后停下，等待指令，如果没有，则自行转弯或直走

(Sequential logic)
```
always@(posedge sys_clk) begin case(state)
    CHECK:
  case({front_detector,back_detector,left_detector,right_detector})
        4'b0011,4'b0111: move<=3'b100;
        4'b1001,4'b1101, 4'b1011, 4'b1010,4'b1110: begin move<=3'b000; state<=THINK;end
      default: begin state<=WAIT; move<=3'b000; end
      endcase
    DECIDE:
       case({front_detector,back_detector,left_detector,right_detector})
        4'b0011,4'b0111:  move<=3'b100;
        4'b1001,4'b1101:beginmove<=3'b010;state<=COUNT;end
        4'b1011: begin move<=3'b010; state<=DOUBLECOUNT; end
        4'b1010,4'b1110: begin move<=3'b001;state<=COUNT; end
        default:beginstate<=WAIT;move<=3'b000;end
      endcase
    WAIT,CLOSE_DETECT,COUNT,THINK,DOUBLECOUNT: //... omitted
  endcase
 end
```

## Part 3 (Bonus). Automatic driving

auto_driving.v

> State analysis
> 
> Place & Destroy beacon (to UART)

- State used

<img src="VGA IMAGES/自动流程图（改）.png" style="zoom:33%;" />

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

输入为sys_clk时钟信号，前后左右探测器信号（均为1bit）

输出前后左右移动信号（4bit）,放置，摧毁路障信号（均1bit）,[3:0]state状态信号

此模式输出一个4比特的移动信号，对应前后左右。

全自动模式转弯的原理与半自动类似，在此不多赘述。

与半自动的区别仅在于遇见岔路时，转弯时以及遇见死路的行为。

遇见岔路时：

优先右转，次之直走。

转弯时：

输出对应的转弯信号时进入放置障碍状态（与半自动的计时类似），

区别在于此状态会将输出放置信号设置为1，在计时结束后将放置障碍信号归0；

遇见死路：

输出左转信号，进入双倍计时状态；

在双倍计时状态结束后会进入破坏状态。

破坏状态：破坏最近放置的两个障碍，后进入关闭探测器直走状态。

本自动行驶思路脱胎于右手定则，小车转弯时将会放置一个路障，因此可以破坏掉环形地图，保持右手定则的正确性。

```
always@(posedge sys_clk) begin case(state)
    CHECK,CLOSE_DETECT,COUNT,THINK,DOUBLECOUNT://...
    DECIDE:
         case({front_detector,back_detector,left_detector,right_detector})
           begin
              //... auto turning cases are omitted
              4'b1010,4'b1110:begin move<=3'b001; state<=beacon; end
              4'b1001,4'b1101:begin move<=3'b010; state<=beacon; end  
              4'b1011,4'b1111:begin move<=3'b010; state<=DESTORY; end
         endcase
    BEACON:
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

vga_char_display.v, vga_miles.v

>Task1. VGA available 
>> Use switch to control VGA to display something.
> 
> Task2. use VGA to show the state
>> Let VGA show the state of the car.
> 
> Task3. use VGA to show the Mileage record
>> Let VGA show the Mileage record. (real-time synchronization)

---

+ MODULE 1：vga_char_display
```
module vga_char_display(
  input clk,
  input  [3:0]state,
  output [3:0]r,
  output [3:0]g,
  output [3:0]b,
  output  hs,
  output  vs
);
```

+ 显示器可显示区域（提醒开发者）

```
parameter UP_BOUND = 32'd31;
parameter DOWN_BOUND = 32'd510;
parameter LEFT_BOUND = 32'd144;
parameter RIGHT_BOUND = 32'd783;
```
+ 参数以及变量
```
wire pclk;//像素时钟
reg [10:0] hcount, vcount;//场行扫描信号
reg [15:0]rgb;//三原色
parameter SEMI=4'b0101;
parameter AUTO=4'b1010;
reg [599:0]char1[79:0];//manual NO START
reg [503:0]char2[111:0];//semi
reg [400:0]char3[159:0];//auto
reg [479:0]char4[79:0];// manual:START
reg [519:0]char5[79:0];//moving
reg [199:0]char6[199:0];//on
reg [239:0]char7[159:0];//off
```

+ MANUAL:START的字模点阵（示例一个点阵）
  
```    
 always@(posedge clk)
 begin
 char4[0]<=480'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
 char4[1]<=480'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
 char4[2]<=480'h00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00;
 //char4[3] - char4[42]
 char4[45]<=480'h00_00_3E_00_00_00_03_E0_0F_80_00_1E_00_0E_00_00_00_3E_00_00_01_FE_00_00_00_00_00_00_00_00_00_00_00_1F_00_00_1E_00_0E_00_01_80_00_07_C0_03_03_E0_00_C0_00_1E_00_0E_00_0F_E1_E1_F8_70;
 char4[46]<=480'h00_00_3E_00_00_00_03_E0_0F_80_00_3F_FF_FE_00_00_00_3E_00_00_01_FC_00_00_00_00_00_00_00_00_00_00_00_1F_00_00_3F_FF_FE_00_01_80_00_07_C0_03_07_E0_00_C0_00_3F_FF_FE_00_0F_E1_E3_F8_70;
 ......
 end
    
assign {r,g,b}=rgb;    
```

+ 获得像素时钟25MHz

```    
assign pclk = count[1];
always @ (posedge clk)
begin
    count <= count+1'b1;
end
```

+ 列计数与行同步
```
assign hs = (hcount < 32'd96) ? 1'b0 : 1'b1;
always @ (posedge pclk)
       begin
           if (hcount == 32'd799) hcount <= 0;
           else hcount <= hcount+1'b1;
       end

```

+ 行计数与场同步

  ```
  assign vs = (vcount < 32'd2) ? 1'b0 : 1'b1;
  always @ (posedge pclk)
  begin
      if (hcount == 32'd799) begin
          if (vcount == 32'd520) vcount <= 0;
          else vcount <= vcount+1'b1;
      end
  end     
  ```

+ 设置显示信号值

```
    always @ (posedge pclk)
    begin
    case(state)
    4'b0000://OFF
     if(vcount>32'd180&&vcount<32'd340&&hcount>32'd280&&hcount<32'd520)//fix
          begin
            if(char7[vcount-32'd180][hcount-32'd280]==1'b1)
              rgb<=16'b1000_0000_0000;
            else
              rgb<=16'b0000_1000_0000;
           end  
    4'b0001://on       ... 
    4'b0010://no start ...	
    4'b0011://start    ...   
    4'b0100://moving   ...
    SEMI:
    AUTO:
    endcase
   end
```

+  其它字符的点阵

``` 
always@(posedge clk)//off
always@(posedge clk)//on
......
endmodule
```

### 效果展示

  此处展示小车的启动(ON),熄火(OFF)

<img src="VGA IMAGES/ON2.jpg" style="zoom: 50%;" />

<img src="VGA IMAGES/OFF1.jpg" style="zoom: 50%;" />
  手动档中的未启动，启动，与前行状态（MANUAL:NO START,MANUAL:START,MANUAL:MOVING）
<img src="VGA IMAGES/NO START 1.jpg" style="zoom: 50%;" />

<img src="VGA IMAGES/NO START 2.jpg" style="zoom: 50%;" />
  小车半自动挡（SEMI AUTO），与自动档（AUTO）
<img src="VGA IMAGES/AUTO1.jpg" style="zoom: 50%;" />
  该模块需输入时钟信号，当前小车的状态(4bit)，输出场行同步信号vs hs(1bit,1bit)以及RGB(4bit,4bit,4bit)信号。

  补充：通过取字模的方式形成点阵，在行列扫描到有字的特定位置时输出红色，否则输出绿色（因设置的绿色较浅，主要显示为黑色）。因为字符点阵代码行太多，此处仅展示部分代码示意。

+ MODULE2: vga_miles

```
module vga_miles(
    input clk,//时钟
    //里程对应的八位八进制数字
    input [2:0]mile_0, [2:0]mile_1, [2:0]mile_2, [2:0]mile_3, [2:0]mile_4, [2:0]mile_5, [2:0]mile_6, [2:0]mile_7,
    output [3:0]r,g,b
    output hs,vs
);
```

+ 显示器可显示区域(提醒开发者)
```
parameter UP_BOUND = 32'd31;
parameter DOWN_BOUND = 32'd510;
parameter LEFT_BOUND = 32'd144;
parameter RIGHT_BOUND = 32'd783;
```

+ 初始化
+ 设置显示信号值
+ 获得像素时钟25MHz
+ 列计数与行同步
+ 行计数与场同步
+ 传入八进制数，返回相应像素点阵

```
number number0(mile_0,pclk,vcount-32'd168,hcount-32'd664,exist0);
// ... 1-6
number number7(mile_7,pclk,vcount-32'd168,hcount-32'd160,exist7);
```
### 效果展示

本模块实时展示开发板上八位八进制里程数。

<img src="VGA IMAGES/MILES1.jpg" style="zoom: 50%;" />

<img src="VGA IMAGES/MILES2.jpg" style="zoom: 50%;" />

输入为八位八进制数（均为3bit），时钟，输出VS HS RGB（已在VGA第一部分介绍）。

在屏幕中均匀选取八块位置，连接八个小模块(详见模块3 number)获得该行列是否应有亮像素点的信息，如果有，则对应位置像素为红色，否则为绿色（因设置的绿色较浅，主要为黑色）。


+ MODULE3: number
```
module number(
   input  [2:0]num,
   input clk,
   input [10:0]vcount,
   input [10:0]hcount, 
   output reg exist
);
```
+ 参数以及变量
  
```
 reg [15:0]rgb;
 reg [71:0]char0[143:0];
 // char1-char6[143:0]...
 reg [71:0]char7[143:0];
```

+ 返回该位置是否应有亮像素点         
            
```         
always@(posedge clk) begin
    case(num)
      3'd0: exist<=char0[vcount][hcount];e
      // 1-6 ...
      3'd7: exist<=char7[vcount][hcount];
    endcase
end             

```

+ 显示点阵(以显示0的点阵为例`char0[143:0]`)
```
always@(posedge clk) //0
   begin
     char0[0]<=72'h	00_00_00_00_00_00_00_00_00;
     char0[1]<=72'h	00_00_00_00_00_00_00_00_00;
     // char0[2-141] ...
     char0[142]<=72'h	00_00_00_00_00_00_00_00_00;
     char0[143]<=72'h	00_00_00_00_00_00_00_00_00;
   end

always@(posedge clk)... //1
always@(posedge clk)... //2
......
endmodule
```

Brief introduction 

本模块储存了 0-7 数字的点阵，输入为`[2:0]num`（需要显示的数字）,clk(时钟), vcount（对应屏幕的行）, hcount（对应屏幕的列）

输出1bit的exist（表这个位置是否有亮点）

VGA整体协调：

在主模块中添加了一个开发板输入contrl，当contrl为0，显示里程数，为1则显示状态，实现了两种显示自由切换。

## Part 5. Summary

> Timeline
> 
> Insights
> 
> Conclusion
---

+ Time & version control

<img src="img/img_9.png" alt="img_9.png" style="zoom:50%;" />  <img src="img/img_10.png" alt="img_10.png" style="zoom:50%;" />


各部分完成时间：

11 周末：开关，手动挡（除里程显示），模式选择，上板测试，未进行模块划分和结构化设计。

12-13 周：进行结构拆分和摸索自动化设计。

13 周末：完成三个模式的结构划分，全自动模式初步实现自动行驶（未实现寻路功能）。

14 周：完成半自动模块设计，开始完善全自动模式和编写报告。

15 周：完成全自动模块设计，开始摸索VGA功能，继续完善报告。

15 周末：完成VGA相关功能和报告，项目所有基本和Bonus部分结束。

16 周：进行细节完善，录制视频。


+ Finding & Insights

项目启动时间较早，后期跟进和完善的时间比较自由。

使用 github 进行版本管理，方便代码同步和共享。

先确定核心代码，再整合到结构中，这样不会写代码不会顾此失彼。

成员沟通效率高，回复及时，态度认真是保质保量完成项目的关键因素。

+ Conclusion

通过智能小车这个项目，很好地将数字逻辑的lab课中的知识点，尤其是对 verliog 这门硬件描述语言进行实战。提升了与队友的配合和交流的能力，在克服一系列外界环境影响后将项目做好。

很好地将逻辑门，逻辑代数，状态机，计数器，寄存器等知识点从理论到实践，对融会贯通理论课内容有很大帮助。————游俊涛

VGA很好地锻炼了学生的自学能力。

感觉做报告和录视频比写代码还复杂。

彩蛋：对于一些人提出的空气墙问题，DEMO如果小车的前探测器（其它未知）图像上与小车障碍相叠时消除，小车的前探测器将会一直返回1（也就是说它觉得它的前面永远会有一个障碍物）————陶文晖