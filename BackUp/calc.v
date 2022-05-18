
// @file calc.v
// @brief 簡単な電卓
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// 簡単な電卓を実装する．
// * clear が押されたら ibuf, cbuf をクリアする．
// * plus が押されたら ibuf の値を cbuf に転送して ibuf をクリアする．
// * equal が押されたら cbuf に ibuf の値を足して ibuf をクリアする．
//
// [入出力]
// clock:   クロック
// reset:   リセット
// keys:    テンキーの値
// clear:   クリア信号
// plus:    `+'信号
// equal:   `='信号
// ibuf:    入力バッファの値
// cbuf:    計算結果バッファの値
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


module calc(input         clock,
	    input 	  reset,
	    input [15:0]  keys,
	    input 	  clear,
	    input 	  plus,
	    input 	  equal,
	    output reg [31:0] ibuf,
	    output reg [31:0] cbuf);
		 		 
		 
reg key_in;
reg[3:0] key_value;
keyenc enc(keys, key_in, key_value);
reg [31:0] REGA, REGB;
reg carry,carry_o,REGB_o;
reg equal_reg;
		 
always @(posedge clock or negedge reset)
begin
	if(!reset)
	begin REGA <= 0; REGB <= 0; carry=0; equal_reg <=0; end
	else if(clear)
	begin REGA <= 0; REGB <= 0; carry=0; equal_reg <=0; end
	else if(key_in)
	begin 
		REGA <= (REGA << 4) + key_value;
		if(plus)
		begin 
		adder32 add1(REGB, REGA, carry,REGB_o,carry_o);
		REGB <= REGB_o;
		carry <= carry_o;
		REGA <= 0;
		end
		else if(equal)
		begin
		adder32 add2(REGB, REGA, carry,REGB_o,carry_o);
		REGB <= REGB_o;
		carry <= 0;
		REGA <= 0;
		end
	end
	ibuf <= REGA;
	cbuf <= (equal_reg == 0)?REGA:REGB;

end

endmodule // calc
