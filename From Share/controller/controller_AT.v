
// @file controller.v
// @breif controller(コントローラ)
// @author Yusuke Matsunaga (松永 裕介)
//
// Copyright (C) 2019 Yusuke Matsunaga
// All rights reserved.
//
// [概要]
// データパスを制御する信号を生成する．
// フェイズは phasegen が生成するので
// このモジュールは完全な組み合わせ回路となる．
//
// [入力]
// cstate:     動作フェイズを表す4ビットの信号
// ir:         IRレジスタの値
// addr:       メモリアドレス(mem_wrbitsの生成に用いる)
// alu_out:    ALUの出力(分岐命令の条件判断に用いる)
//
// [出力]
// pc_sel:     PCの入力選択
// pc_ld:      PCの書き込み制御
// mem_sel:    メモリアドレスの入力選択
// mem_read:   メモリの読み込み制御
// mem_write:  メモリの書き込み制御
// mem_wrbits: メモリの書き込みビットマスク
// ir_ld:      IRレジスタの書き込み制御
// rs1_addr:   RS1アドレス
// rs2_addr:   RS2アドレス
// rd_addr:    RDアドレス
// rd_sel:     RDの入力選択
// rd_ld:      RDの書き込み制御
// a_ld:       Aレジスタの書き込み制御
// b_ld:       Bレジスタの書き込み制御
// a_sel:      ALUの入力1の入力選択
// b_sel:      ALUの入力2の入力選択
// imm:        即値
// alu_ctl:    ALUの機能コード
// c_ld:       Cレジスタの書き込み制御
module controller(input [3:0]   cstate,
		  input [31:0] 	ir,
		  input [31:0]  addr,
		  input [31:0] 	alu_out,
		  output 	pc_sel,
		  output 	pc_ld,
		  output 	mem_sel,
		  output 	mem_read,
		  output 	mem_write,
		  output [3:0] 	mem_wrbits,
		  output 	ir_ld,
		  output [4:0] 	rs1_addr,
		  output [4:0] 	rs2_addr,
		  output [4:0] 	rd_addr,
		  output [1:0] 	rd_sel,
		  output 	rd_ld,
		  output 	a_ld,
		  output 	b_ld,
		  output 	a_sel,
		  output 	b_sel,
		  output [31:0] imm,
		  output [3:0] 	alu_ctl,
		  output 	c_ld);
		  
// pc control
function [1:0] f_pc (input [3:0] cstate, input [31:0] ir, input [31:0] alu_out); //pc_sel,pc_ld
	begin
	if( (ir[6:0] == 7'b1101111 || ir[6:0] == 7'b1100111) && cstate == 4'b1000) begin
	f_pc = 2'b11;
	end
	else if( ir[6:0] == 7'b1100011) begin
		if(cstate == 4'b1000) begin
			if(alu_out == 32'b1) begin
				f_pc = 2'b11;
				end
				else if (alu_out == 32'b0) begin
				f_pc = 2'b01;
				end
				else begin
				f_pc = 2'b00;
				end
			end
	end
	else if(cstate == 4'b1000) begin
	f_pc = 2'b01;
	end
	else begin
	f_pc = 2'b00;
	end
	
	end
	endfunction
	
	wire [1:0] tmp_pc;
	assign tmp_pc = f_pc(cstate, ir, alu_out);
	assign {pc_sel, pc_ld} = tmp_pc;
	
	
// mem control mem_sel,
function [6:0] f_mem(input [3:0] cstate, input [31:0] ir, input [31:0] addr);// mem_sel, mem_read, mem_write, [3:0] mem_wrbits,
	begin
	
	if(cstate == 4'b0001) begin // IF
	f_mem[6] = 0;
	f_mem[5] = 1;
	end
	else if((ir[6:0] == 7'b0000011 || ir[6:0] == 7'b0100011) && cstate == 4'b1000) begin //(load or store) and WB
	f_mem[6] = 1;
	end
	
	if(ir[6:0] == 7'b0000011 && cstate == 4'b1000) begin //load and WB
	f_mem[5] = 1;
	end
	
	if (ir[6:0] == 7'b0100011 && cstate == 4'b1000) begin //store and WB
	f_mem[4] = 1;
	
		if(ir[14:12] == 3'b000) begin //sb
		case (addr[1:0])
		2'b00 : f_mem[3:0] = 4'b0001;
		2'b01 : f_mem[3:0] = 4'b0010;
		2'b10 : f_mem[3:0] = 4'b0100;
		2'b11 : f_mem[3:0] = 4'b1000;
		endcase
		end
		
		else if(ir[14:12] == 3'b001) begin //sh
		case (addr[1:0])
		2'b00 : f_mem[3:0] = 4'b0011;
		2'b10 : f_mem[3:0] = 4'b1100;
		endcase
		end
		
		else if(ir[14:12] == 3'b010) begin //sw
		f_mem[3:0] = 4'b1111;
		end
		
		end
	
	end
	endfunction
	
	
	wire [6:0] mem;
	assign mem = f_mem(cstate, ir, addr);
	assign {mem_sel, mem_read, mem_write, mem_wrbits} = mem;
	
	
// ir control
function f_ir(input [3:0] cstate);
	begin
	if (cstate == 4'b0001) begin
	f_ir = 1;
	end
	else begin
	f_ir = 0;
	end
	end
	endfunction
	
	assign ir_ld = f_ir(cstate);
	
	
// reg control_1
	assign rs1_addr = ir[19:15];
	assign rs2_addr = ir[24:20];
	assign rd_addr = ir[11:7];
	
	
// reg control_2
function [1:0] f_reg2(input [3:0] cstate);
	begin
	if (cstate == 4'b0010) begin
	f_reg2 = 2'b11;
	end
	else begin
	f_reg2 = 2'b00;
	end
	end
	endfunction
	
	wire [1:0] reg2;
	assign reg2 = f_reg2(cstate);
	assign {a_ld, b_ld} = reg2;

// reg control_3
function [2:0] f_reg3(input [3:0] cstate, input [31:0] ir);
	begin
	
	if((ir[6:0] == 7'b0110011 || ir[6:0] == 7'b0110111 || ir[6:0] == 7'b0010111 || ir[6:0] == 7'b0010011) && cstate == 4'b1000) begin
	f_reg3[2:1] = 2'b10;
	f_reg3[0] = 1;
	end
	
	else if(ir[6:0] == 7'b0000011 && cstate == 4'b1000) begin
	f_reg3[2:1] = 2'b00;
	f_reg3[0] = 1;
	end
	
	else if((ir[6:0] == 7'b1101111 || ir[6:0] == 7'b1100111) && cstate == 4'b1000) begin
	f_reg3[2:1] = 2'b01;
	f_reg3[0] = 1;
	end
	
	else begin
	f_reg3 = 3'b000;
	end
	end
	endfunction
	
	wire [2:0] reg3;
	assign reg3 = f_reg3(cstate, ir);
	assign {rd_sel, rd_ld} = reg3;
	
	
// imm generator
function [31:0] f_imm(input [31:0] ir);
	begin
	
	if(ir[6:0] == 7'b0010011 || ir[6:0] == 7'b1100111 || ir[6:0] == 7'b0000011) begin //I_type (and shift type)
		if(ir[14:12] == 3'b001 || ir[14:12] == 3'b101) begin
		f_imm = {27'b0, ir[24:20]};
		end
		else begin
		f_imm = { {20{ir[31]}}, ir[31:20]};
		end
	end
	
	else if(ir[6:0] == 7'b0100011) begin //S_type
	f_imm = { {20{ir[31]}}, ir[31:25], ir[11:7]};
	end
	
	else if(ir[6:0] == 7'b1100011) begin //B_type
	f_imm = { {19{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0 };
	end
	
	else if(ir[6:0] == 7'b0110111) begin //U_type,  LUI
	f_imm = {ir[31:12], 12'b0};
	end
	
	else if(ir[6:0] == 7'b0010111) begin //U_type,  AUIPC
	f_imm = {ir[31:12], 12'b0};
	end
	
	else if(ir[6:0] == 7'b1101111) begin //J_type
	f_imm = {{19{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};
	end
	
	end
	endfunction
	
	wire [31:0] tmp_imm;
	assign tmp_imm = f_imm(ir);
	assign imm = tmp_imm;

	
// ALU control
function [5:0] f_ALU (input [3:0] cstate, input [31:0] ir); //[3:0] alu_ctl and a_sel, b_sel
	begin
	
	if (cstate == 4'b0100) begin
	
		if(ir[6:0] == 7'b0110111) begin //LUI
		f_ALU = 6'b000001;
		end
		
		
		else if((ir[6:0] == 7'b0110011 && ir[14:12] == 3'b000 && ir[30] == 0) 
		 ) begin //ADD
		f_ALU = 6'b100000;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b010) begin // slt
		f_ALU = 6'b010000;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b011) begin // sltu
		f_ALU = 6'b011000;
		end
		
		else if(ir[6:0] == 7'b1100111 
		|| (ir[6:0] == 7'b0010011 && ir[14:12] == 3'b000)
		|| ir[6:0] == 7'b0000011
		|| ir[6:0] == 7'b0100011) begin //JALR,ADDI,LOAD,STORE
		f_ALU = 6'b100001;
		end
		
		
		else if(ir[6:0] == 7'b0010111 
		|| ir[6:0] == 7'b1101111
		|| (ir[6:0] == 7'b1100011 && ir[14:12] == 3'b000 && cstate == 4'b0100)
		|| (ir[6:0] == 7'b1100011 && ir[14:12] == 3'b001 && cstate == 4'b0100)
		|| (ir[6:0] == 7'b1100011 && ir[14:12] == 3'b100 && cstate == 4'b0100)
		|| (ir[6:0] == 7'b1100011 && ir[14:12] == 3'b101 && cstate == 4'b0100)
		|| (ir[6:0] == 7'b1100011 && ir[14:12] == 3'b110 && cstate == 4'b0100)
		|| (ir[6:0] == 7'b1100011 && ir[14:12] == 3'b111 && cstate == 4'b0100)
		) begin //AUIPC,JAL,{BEQ,BNE,BLT,BGE,BLTU,BGEU(EX)}
		f_ALU = 6'b100011;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b000 && ir[30] == 1) begin //SUB
		f_ALU = 6'b100111;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b100) begin //XOR
		f_ALU = 6'b101011;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b110) begin //OR
		f_ALU = 6'b101111;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b111) begin //AND
		f_ALU = 6'b110011;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b001) begin //SLL
		f_ALU = 6'b110111;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b101 && ir[30] == 0) begin //SRL
		f_ALU = 6'b111011;
		end
		
		else if(ir[6:0] == 7'b0110011 && ir[14:12] == 3'b101 && ir[30] == 1) begin //SRA
		f_ALU = 6'b111111;
		end
		
	end
	
	else if(cstate == 4'b1000) begin
	if(ir[6:0] == 7'b1100011 && ir[14:12] == 3'b000 ) begin //BEQ
		f_ALU = 6'b001000;
		end
		if(ir[6:0] == 7'b1100011 && ir[14:12] == 3'b001 ) begin //BNE
		f_ALU = 6'b001100;
		end
		if(ir[6:0] == 7'b1100011 && ir[14:12] == 3'b100 ) begin //BLT
		f_ALU = 6'b010000;
		end
		if(ir[6:0] == 7'b1100011 && ir[14:12] == 3'b101 ) begin //BGE
		f_ALU = 6'b010100;
		end
		if(ir[6:0] == 7'b1100011 && ir[14:12] == 3'b110 ) begin //BLTU
		f_ALU = 6'b011000;
		end
		if(ir[6:0] == 7'b1100011 && ir[14:12] == 3'b111) begin //BGEU
		f_ALU = 6'b011100;
		end
	
	end
	end
	endfunction
	
	wire [5:0] tmp_ALU;
	assign tmp_ALU = f_ALU(cstate, ir);
	assign {alu_ctl, a_sel, b_sel} = tmp_ALU;
		
	
	//f_ALUの値から。
	
// c_reg control
function f_c(input [3:0] cstate);
	begin
	
	if (cstate == 4'b0100) begin
	f_c = 1;
	end
	else begin
	f_c = 0;
	end
	
	end
	endfunction
	
	assign c_ld = f_c(cstate);
	

endmodule // controller
