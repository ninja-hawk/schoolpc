module adder32(input [31:0] in1, input [31:0] in2, input in_carry, output [31:0] out, output out_carry);
	wire carry1,carry2,carry3,carry4,carry5,carry6, carry7;
	assign {carry1, out[3:0]} = in1[3:0] + in2[3:0] + in_carry;
	assign {carry2, out[7:3]} = in1[7:3] + in2[7:3] + carry1;
	assign {carry3, out[11:7]} = in1[11:7] + in2[11:7] + carry2;
	assign {carry4, out[15:11]} = in1[15:11] + in2[15:11] + carry3;
	assign {carry5, out[19:15]} = in1[19:15] + in2[19:15] + carry4;
	assign {carry6, out[23:19]} = in1[23:19] + in2[23:19] + carry5;
	assign {carry7, out[27:23]} = in1[27:23] + in2[27:23] + carry6;
	assign {out_carry, out[31:27]} = in1[31:27] + in2[31:27] + carry7;
	
endmodule
