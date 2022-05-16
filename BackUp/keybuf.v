
// @file keybuf.v
// @brief キー入力バッファ
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// 16個のキー入力用のプライオリティ付きエンコーダ
//
// [入出力]
// clock:   クロック
// reset:   リセット
// key_in:  いずれかのキーが押された時に1となる信号
// key_val: キーの値(0 - 15)
// clear:   クリア信号
// out:     バッファの値
module keybuf(input         clock,
	      input 	    reset,
	      input 	    key_in,
	      input [3:0]   key_val,
	      input 	    clear,
	      output [31:0] out);			

reg [31:0] a;

always @(posedge clock or negedge reset)
	begin
		if(!reset)
			begin a = 32'h0; end
		else if(clear)
			begin a <= 32'h0 ; end
		else if(key_in)
			begin
			a <= (a << 4) + key_val;
			end

	end

assign out = a;
endmodule // keyenc
