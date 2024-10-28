module clearscreen(CLOCK_50, rst, x_out , y_out);
	input CLOCK_50;	
	input rst;
	wire [2:0] color = 3'b000;
	output [7:0] x_out;
	output [6:0] y_out;
	wire change;
	fsm_clear f1(.clk(CLOCK_50), .rst(rst), .change(change), .colour(color));
   datapath_clear d1(.clk(CLOCK_50), .rst(rst), .x(x_out), .y(y_out), .change(change));
	

endmodule



module fsm_clear(clk, rst, change, colour);
output [2:0] colour;
input change;
input rst;
input clk;
reg [2:0] p_state; 
reg [2:0] n_state;
assign colour=000;

always@(*)
begin
if(change)
case(p_state)
0:n_state = 1;
1:n_state = 2;
2:n_state = 3;
3:n_state = 4;
4:n_state = 5;
5:n_state = 6;
6:n_state = 7;
7:n_state = 0;
endcase
else
n_state = p_state;
end 

always@(posedge clk or posedge rst)
begin
if(rst) begin
p_state <= 0;
end
else begin
p_state <= n_state;
end
end

endmodule

module datapath_clear(clk, rst, x, y, change);
input clk, rst;
output reg [7:0]x;
output reg [6:0]y;
output change;
assign change = (x == 159);
always@(posedge clk or posedge rst)
begin
if(rst) begin
y <= 0;
x <= 0;
end
else begin
x <= x + 1;
if(change)
y <= y + 1;
else
y <= y;
end
end

endmodule
