module bresenhamcircle(CLOCK_50, LEDR,
KEY, VGA_R, VGA_G, VGA_B,
				VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_CLK);
	output [9:0]LEDR;
   input CLOCK_50;	
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
wire [2:0]colour;

assign rst = KEY[1];

wire [4:0]x;
wire [4:0]y;
wire running;
wire loop;
wire done;

assign LEDR[0] = done;
assign LEDR[1] = running;
wire [7:0]x_out_circle;
wire [7:0]y_out_circle;
wire [7:0]x_out_clear;
wire [7:0]y_out_clear;	
wire [3:0]p_state;
wire [2:0]colour_print;
wire [7:0]x_out;
wire [7:0]y_out;
wire [7:0]x_center;
wire [6:0]y_center;

assign x_out = (KEY[3])?x_out_circle:x_out_clear;
assign y_out = (KEY[3])?y_out_circle:y_out_clear;
assign colour_print = (KEY[3])?colour:3'b000;

lfsr l1(KEY[2], rst, x_center);

lfsr l2(KEY[2], rst, y_center);

lfsr l3(KEY[2], rst, colour);

clearscreen c1(CLOCK_50, KEY[3], x_out_clear, y_out_clear);
fsm f1(CLOCK_50, running, rst, x, y, x_out_circle, y_out_circle, p_state, done, x_center, y_center);
datapath d1(CLOCK_50, x, y, running, loop, x_center, y_center, rst, done);

vga_adapter VGA(
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(colour_print),
			.x(x_out),
			.y(y_out),
			.plot(1),
			/* Signalsgs for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N), 
			.VGA_SYNC(VGA_SYNC_N), 
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "1y_centerx120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "image.colour.mif";
		defparam VGA.USING_DE1 = "TRUE";
					
endmodule


module fsm(clk, running, rst, x_in, y_in, x_out, y_out, p_state, done, x_center, y_center);
input clk, running, rst;
input [7:0]x_center;
input [7:0]y_center;
input [4:0]x_in;
input [4:0]y_in;
output reg [7:0]x_out;
output reg [7:0]y_out;
output reg [3:0]p_state;
output reg done;
reg [3:0] n_state; 
always@(*) //next state logic
begin
if(running)
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

always@(posedge clk or posedge rst) //state register
begin
if(rst)
p_state <= 0;
else 
p_state <= n_state;
end

always@(*) //output logic
begin
if(rst)
begin
x_out = 0;
y_out = 0;
done = 0;
end
else
begin

case(p_state)
0:begin x_out = x_center+x_in; y_out = y_center+y_in; done = 0; end
1:begin x_out = x_center+x_in; y_out = y_center-y_in; end
2:begin x_out = x_center-x_in; y_out = y_center+y_in; end
3:begin x_out = x_center-x_in; y_out = y_center-y_in; end
4:begin x_out = x_center+y_in; y_out = y_center+x_in; end
5:begin x_out = x_center+y_in; y_out = y_center-x_in; end
6:begin x_out = x_center-y_in; y_out = y_center+x_in; end
7:begin x_out = x_center-y_in; y_out = y_center-x_in; end
8:begin x_out = 0; y_out = 0; done = 1; end
endcase

end

end
endmodule


module datapath(clk, x, y, running, loop, x_center, y_center, rst, done); //datapath
output reg [4:0]x;
output reg [4:0]y;
input done;
reg [7:0]d;
output reg running;
output loop;
input rst;
input [7:0]x_center;
input [6:0]y_center;
wire [4:0] max_x;
wire [4:0] max_y;
assign max_x = 160-x_center;
assign max_y = 120-y_center;
input clk;
reg [4:0]radius;
assign loop = (x <= y) ? 1 : 0;
always@(posedge clk or posedge rst)
begin
if(rst)
begin
x <= 0;
y <= radius;
d <= 3-2*radius;
end
else if(loop) begin
if((max_x)>(max_y))
radius = 160 - x_center; 
else
radius = 120 - y_center;
running <= 1;
if(done == 1) begin
running <= 0;
x <= x + 1;
if(d[7] == 1) begin
d <= d + 4*x + 6;
end
else begin
d <= d + 4*(x-y) + 10;
y <= y - 1;
end
end
end
end

endmodule


