# Sustech 2022-fall CS207 Digital logic

## Project: Smart car simulating

---

- 游俊涛 12110919 : Manual Driving & Auto Driving
- 陶文晖 12111744 : Semi Driving & Auto Driving

**[Source code](https://github.com/sustechwifi/CS207_project)**

```
https://github.com/sustechwifi/CS207_project
```

---

## Part 0. 结构设计

- 顶层模块定义

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
```

- Inner variable

```
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
```

- State Table

| 参数名                     | state code | 描述    |
|-------------------------|------------|-------|
| OFF                     | 4'b0000    | 未启动   |
| ON                      | 4'b0001    | 已启动   |
| MANUAL_DRIVING_PREPARED | 4'b0010    | 手动挡空挡 |
| MANUAL_DRIVING_STARTING | 4’b0011    | 手动挡就绪 |
| MANUAL_DRIVING_MOVING   | 4'b0100    | 手动挡行驶中 |
| SEMI_AUTO               | 4'b0101    | 半自动就绪 |
| AUTO_DRIVING            | 4'ha       | 全自动就绪 |
| AUTO_FORWARD            | 4'hb       | 全自动行驶中 |
| AUTO_TURN_LEFT          | 4'hc       | 全自动左转 |
| AUTO_TURN_RIGHT         | 4'hd       | 全自动右转 |
| AUTO_TURN_BACK          | 4'he       | 全自动掉头 |

- 状态机

```
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
       
       AUTO_DRIVING, AUTO_FORWARD, AUTO_TURN_LEFT, AUTO_TURN_RIGHT, AUTO_TURN_BACK:
       begin
            next_state <=  state_from_auto; 
            control_signal <= control_signal_from_auto;
            place_barrier_signal <= place_barrier_signal_from_auto;
            destroy_barrier_signal <=  destroy_barrier_signal_from_auto | destroy_barrier;   
            left_cnt <= left_cnt_next; right_cnt <= right_cnt_next;
       end  
       default: next_state <= OFF; 
    endcase
    end
```

- 结构化设计

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
   sys_clk, 
   front_detector,
   back_detector,
   left_detector,
   right_detector, 
   go_strait,
   turn_left,
   turn_right,
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
```

---

## Part 1. Manual Driving

- Power-on and Power-off (button)
- Throttle, Clutch, Brake (switch)
- Turning, Mileage (LED, seg-tubes)

### 1.Power control 
- On & Off

 Use counter `reg [31:0] cnt` to record single second.
 In this part, state will be updated by `next_state` or clear to `OFF`.
 
(sequential logic)
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

### 2. Mileage record
- Store mileage when moving.

If current state is `MANUAL_DRIVING_MOVING`, mileage variable `reg [32:0] mile` will increase each period.
`seg_7` will update in each second, which refer the signal of seg-tubes in EGO1.

(sequential logic)
```
 always@(posedge sys_clk)
    begin
        case(state)
        MANUAL_DRIVING_MOVING:
        begin
            if(mile > 32'd1_0000_0000)
             begin
               seg_7 <= seg_7 + 4'b0001;
               mile <= 32'd0;
             end
            else mile <= mile + 32'd1;
        end
        default:mile <= 32'd0;
        endcase
    end
```

### 3. Throttle, Clutch, Brake switch
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

- Car behavior output. 

In this part, Gate-level circuits is used to
update `direction_left_light` and `direction_right_light`,which connect in LED signal. And
  `wire [3:0] control_output` is used for URAT module control.

(Combinatorial logic)

```
assign direction_left_light = turn_left & ~turn_right;
assign direction_right_light = turn_right & ~turn_left;
assign control_output = {res & ~reverse_gear_shift,res & reverse_gear_shift,turn_left,turn_right};
```

---
## Part 2 Semi-auto driving

```
//TODO ...
```
---

### · Bonus parts below

## Part 3 Automatic driving
```
//TODO ...
```

## Part 4 VGA
```
//TO BE CONTINUE......
```


---