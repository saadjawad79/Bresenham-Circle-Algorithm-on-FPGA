module bresenhamcircle(CLOCK_50,
KEY, SW, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
   input CLOCK_50;	
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] VGA_R;
	output [9:0] VGA_G;
	output [9:0] VGA_B;
	output VGA_HS;
	output VGA_VS;
	output VGA_BLANK_N;
	output VGA_SYNC_N;
	output VGA_CLK;	

wire rst;
wire [4:0]radius;
wire [2:0] colour;

assign rst = ~KEY[0];
assign radius = SW[7:3];
assign colour = SW[2:0];

wire [4:0]x;
wire [4:0]y;
wire running;
wire loop;

wire [7:0]x_out;
wire [7:0]y_out;	
wire [3:0]p_state;

fsm f1(CLOCK_50, running, rst, x, y, x_out, y_out, p_state);

datapath d1(x, y, running, loop, radius, p_state, rst);

vga_adapter VGA(
			.resetn(KEY[2]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x_out),
			.y(y_out),
			.plot(SW[9]),
			/* Signalsgs for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N), 
			.VGA_SYNC(VGA_SYNC_N), 
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";
		defparam VGA.USING_DE1 = "TRUE";
					
endmodule


module fsm(clk, running, rst, x_in, y_in, x_out, y_out, p_state);
input clk, running, rst;
input [4:0]x_in;
input [4:0]y_in;
output reg [7:0]x_out;
output reg [7:0]y_out;
output reg [3:0]p_state;

reg [3:0] n_state; 
reg [7:0] temp;
always@(*) //next state logic
begin
if(!running)
begin
case(p_state) 
0:n_state = 1;
1:n_state = 2;
2:n_state = 3;
3:n_state = 4;
4:n_state = 5;
5:n_state = 6;
6:n_state = 7;
7:n_state = 8;
8:n_state = 0;
endcase
end
else
n_state = p_state;
end

always@(posedge clk or negedge rst) //state register
begin
if(~rst)
p_state <= 0;
else 
p_state <= n_state;
end

always@(*) //output logic
begin
if(~rst)
begin
x_out = 80;
y_out = 60;
end
else
begin
if(p_state[1])
x_out  = 80-(x_in);
else
x_out = 80+x_in;

if(p_state[0])
y_out  = 60-(y_in);
else
y_out = 60+y_in; 

if(p_state[2])
begin
temp = x_out;
x_out = y_out;
y_out = temp;
end



if(p_state[3])
begin
x_out = 80;
y_out = 60;
end
end
end
endmodule


module datapath(x, y, running, loop, radius, p_state, rst); //datapath
output reg [4:0]x;
output reg [4:0]y;
reg [6:0]d;
output reg running;
output loop;
input rst;
input [4:0]radius;
input [3:0]p_state;

assign loop = (x < y) ? 1 : 0;
always@(*)
begin
running = (p_state == 8);
if(rst)
begin
x = 0;
y = radius;
d = 3-2*radius;
end
else if(loop) begin

if(running) begin
x = x + 1;
if(d < 0) begin
d = d + 4*x + 6;
running = 0;
end
else begin
d = d + 4*(x-y) + 10;
y = y - 1;
running = 0;
end
end
end
end

endmodule

