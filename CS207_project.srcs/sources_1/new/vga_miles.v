`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/12/24 15:10:52
// Design Name: 
// Module Name: vga_miles
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

// vga_char_display.v
`timescale 1ns / 1ps

module vga_miles(
    input clk,
    input [2:0]mile_0, [2:0]mile_1, [2:0]mile_2, [2:0]mile_3, [2:0]mile_4, [2:0]mile_5, [2:0]mile_6, [2:0]mile_7,
    output [3:0]r,
    output [3:0]g,
    output [3:0]b,
    output hs,
    output vs
    );

	// 显示器可显示区域
	parameter UP_BOUND = 32'd31;
	parameter DOWN_BOUND = 32'd510;
	parameter LEFT_BOUND = 32'd144;
	parameter RIGHT_BOUND = 32'd783;
	
	wire pclk;
	reg [1:0] count;
	reg [10:0] hcount, vcount;
    reg [15:0]rgb;
    reg [23:0]state;
    wire exist0, exist1,exist2,exist3,exist4,exist5,exist6,exist7;
initial
begin
count=0;
hcount=0;
vcount=0;
rgb=0;
end
number number0(mile_0,pclk,vcount-32'd168,hcount-32'd664,exist0);
number number1(mile_1,pclk,vcount-32'd168,hcount-32'd592,exist1);
number number2(mile_2,pclk,vcount-32'd168,hcount-32'd520,exist2);
number number3(mile_3,pclk,vcount-32'd168,hcount-32'd448,exist3);
number number4(mile_4,pclk,vcount-32'd168,hcount-32'd376,exist4);
number number5(mile_5,pclk,vcount-32'd168,hcount-32'd304,exist5);
number number6(mile_6,pclk,vcount-32'd168,hcount-32'd232,exist6);
number number7(mile_7,pclk,vcount-32'd168,hcount-32'd160,exist7);
	// 设置显示信号值
	always @ (posedge pclk)
	begin
    if(vcount>32'd168&&vcount<32'd312&&hcount>32'd160&&hcount<32'd232)
    begin
	  if(exist7==1'b1)
	  rgb<=16'b1000_0000_0000;
      else
      rgb<=16'b0000_1000_0000;
	  end
	if(vcount>32'd168&&vcount<32'd312&&hcount>32'd232&&hcount<32'd304)
          begin
            if(exist6==1'b1)
            rgb<=16'b1000_0000_0000;
            else
            rgb<=16'b0000_1000_0000;
            end
    if(vcount>32'd168&&vcount<32'd312&&hcount>32'd304&&hcount<32'd376)
                begin
                  if(exist5==1'b1)
                  rgb<=16'b1000_0000_0000;
                  else
                  rgb<=16'b0000_1000_0000;
                  end
     if(vcount>32'd168&&vcount<32'd312&&hcount>32'd376&&hcount<32'd448)
                      begin
                        if(exist4==1'b1)
                        rgb<=16'b1000_0000_0000;
                        else
                        rgb<=16'b0000_1000_0000;
                        end             
    if(vcount>32'd168&&vcount<32'd312&&hcount>32'd448&&hcount<32'd520)
                            begin
                              if(exist3==1'b1)
                              rgb<=16'b1000_0000_0000;
                              else
                              rgb<=16'b0000_1000_0000;
                              end
    if(vcount>32'd168&&vcount<32'd312&&hcount>32'd520&&hcount<32'd592)
                               begin
                               if(exist2==1'b1)
                               rgb<=16'b1000_0000_0000;
                               else
                               rgb<=16'b0000_1000_0000;
                               end          
 if(vcount>32'd168&&vcount<32'd312&&hcount>32'd592&&hcount<32'd664)
begin
if(exist1==1'b1)
 rgb<=16'b1000_0000_0000;
else
rgb<=16'b0000_1000_0000;
end             
if(vcount>32'd168&&vcount<32'd312&&hcount>32'd664&&hcount<32'd736)
begin
if(exist0==1'b1)
 rgb<=16'b1000_0000_0000;
else
rgb<=16'b0000_1000_0000;
end                                                               
end//always
 
	assign {r,g,b}=rgb;
	// 获得像素时钟25MHz
	assign pclk = count[1];
	always @ (posedge clk)
	begin
			count <= count+1'b1;
	end
	
	// 列计数与行同步
	assign hs = (hcount < 32'd96) ? 1'b0 : 1'b1;
	always @ (posedge pclk)
	begin
		if (hcount == 32'd799)
			hcount <= 0;
		else
			hcount <= hcount+1'b1;
	end
	
	// 行计数与场同步
	assign vs = (vcount < 32'd2) ? 1'b0 : 1'b1;
	always @ (posedge pclk)
	begin
	    if (hcount == 32'd799) begin
			if (vcount == 32'd520)
				vcount <= 0;
			else
				vcount <= vcount+1'b1;
		end
	end

endmodule
 


