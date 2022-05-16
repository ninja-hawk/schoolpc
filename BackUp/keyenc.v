
// @file keyenc.v
// @brief キー入力用のエンコーダ
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// 16個のキー入力用のプライオリティ付きエンコーダ
//
// [入出力]
// keys: キー入力の値
// key_in: いずれかのキーが押された時に1となる出力
// key_val: キーの値(0 - 15)
module keyenc(input [15:0] keys,
	      output 	   key_in,
	      output [3:0] key_val);

function [0:0] inner(input [15:0]input_keys);
	begin
	if (input_keys == 16'b0)
	begin inner = 0;end	
	else
	begin inner = 1;end
	end
endfunction 

function [3:0] encoder(input [15:0] in_keys);
  begin
    casex (in_keys)
		16'bxxxx_xxxx_xxxx_xxx1: encoder = 4'b0000;
      16'bxxxx_xxxx_xxxx_xx1x: encoder = 4'b0001;
      16'bxxxx_xxxx_xxxx_x1xx: encoder = 4'b0010;
      16'bxxxx_xxxx_xxxx_1xxx: encoder = 4'b0011;
      16'bxxxx_xxxx_xxx1_xxxx: encoder = 4'b0100;
      16'bxxxx_xxxx_xx1x_xxxx: encoder = 4'b0101;
      16'bxxxx_xxxx_x1xx_xxxx: encoder = 4'b0110;
      16'bxxxx_xxxx_1xxx_xxxx: encoder = 4'b0111;
      16'bxxxx_xxx1_xxxx_xxxx: encoder = 4'b1000;
      16'bxxxx_xx1x_xxxx_xxxx: encoder = 4'b1001;
      16'bxxxx_x1xx_xxxx_xxxx: encoder = 4'b1010;
      16'bxxxx_1xxx_xxxx_xxxx: encoder = 4'b1011;
      16'bxxx1_xxxx_xxxx_xxxx: encoder = 4'b1100;
      16'bxx1x_xxxx_xxxx_xxxx: encoder = 4'b1101;
      16'bx1xx_xxxx_xxxx_xxxx: encoder = 4'b1110;
      16'b1xxx_xxxx_xxxx_xxxx: encoder = 4'b1111;
      default: encoder = 4'b0;
    endcase
  end
endfunction
assign key_in = inner(keys);
assign key_val = encoder(keys);



endmodule // keyenc