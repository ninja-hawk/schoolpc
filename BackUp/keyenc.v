
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

function inkey(input [15:0] keys);
  begin
    casex (keys)
      16'b0xxx_xxxx_xxxx_xxxx: encoder = 1;
      16'bx0xx_xxxx_xxxx_xxxx: encoder = 1;
      16'bxx0x_xxxx_xxxx_xxxx: encoder = 1;
      16'bxxx0_xxxx_xxxx_xxxx: encoder = 1;
      16'bxxxx_0xxx_xxxx_xxxx: encoder = 1;
      16'bxxxx_x0xx_xxxx_xxxx: encoder = 1;
      16'bxxxx_xx0x_xxxx_xxxx: encoder = 1;
      16'bxxxx_xxx0_xxxx_xxxx: encoder = 1;
      16'bxxxx_xxxx_0xxx_xxxx: encoder = 1;
      16'bxxxx_xxxx_x0xx_xxxx: encoder = 1;
      16'bxxxx_xxxx_xx0x_xxxx: encoder = 1;
      16'bxxxx_xxxx_xxx0_xxxx: encoder = 1;
      16'bxxxx_xxxx_xxxx_0xxx: encoder = 1;
      16'bxxxx_xxxx_xxxx_x0xx: encoder = 1;
      16'bxxxx_xxxx_xxxx_xx0x: encoder = 1;
      16'bxxxx_xxxx_xxxx_xxx0: encoder = 1;
      default: encoder = 0;
    endcase
  end
endfunction


function [3:0] encoder(input [15:0] keys);
  begin
    casex (keys)
      16'b0xxx_xxxx_xxxx_xxxx: encoder = 4'b0000;
      16'bx0xx_xxxx_xxxx_xxxx: encoder = 4'b0001;
      16'bxx0x_xxxx_xxxx_xxxx: encoder = 4'b0010;
      16'bxxx0_xxxx_xxxx_xxxx: encoder = 4'b0011;
      16'bxxxx_0xxx_xxxx_xxxx: encoder = 4'b0100;
      16'bxxxx_x0xx_xxxx_xxxx: encoder = 4'b0001;
      16'bxxxx_xx0x_xxxx_xxxx: encoder = 4'b0110;
      16'bxxxx_xxx0_xxxx_xxxx: encoder = 4'b0111;
      16'bxxxx_xxxx_0xxx_xxxx: encoder = 4'b1000;
      16'bxxxx_xxxx_x0xx_xxxx: encoder = 4'b1001;
      16'bxxxx_xxxx_xx0x_xxxx: encoder = 4'b1010;
      16'bxxxx_xxxx_xxx0_xxxx: encoder = 4'b1011;
      16'bxxxx_xxxx_xxxx_0xxx: encoder = 4'b1100;
      16'bxxxx_xxxx_xxxx_x0xx: encoder = 4'b1101;
      16'bxxxx_xxxx_xxxx_xx0x: encoder = 4'b1110;
      16'bxxxx_xxxx_xxxx_xxx0: encoder = 4'b1111;
      default: encoder = 4'bx;
    endcase
  end
endfunction

always @(posedge inkey(keys))
begin
  key_val <= encoder(keys);
end


endmodule // keyenc