
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
	
	//  pc_ctrl = {pc_sel, pc_ld}
	function [1:0] pc_ctrl (input [3:0] pc_cstate, input [31:0] pc_ir, input [31:0] pc_alu_out);
		case(pc_ir[6:0])
		
			// JAL命令
			7'b1101111: begin 
				// WBのとき
				if (pc_cstate[3] == 1'b1) begin
					pc_ctrl = 2'b11;
					end
					else
						pc_ctrl = 2'b00;
				end
			// JALR命令
			7'b1100111: begin 
				// WBのとき
				if (pc_cstate[3] == 1'b1) begin
					pc_ctrl = 2'b11;
					end
					else
						pc_ctrl = 2'b00;
				end
			// 分岐命令系(BEQ系)
			7'b1100011: begin  
				// WBのとき
				if (pc_cstate[3] == 1'b1) begin
						if (pc_alu_out == 32'b1) // 分岐成功
							pc_ctrl = 2'b11;
							else
								pc_ctrl = 2'b01;
					end
					else
						pc_ctrl = 2'b00;
					end
			default: 
				// WBのとき
				if (pc_cstate[3] == 1'b1)
					pc_ctrl = 2'b01;	
					else
						pc_ctrl = 2'b00;
		endcase
	endfunction
		  

	//  mem_ctrl = {mem_sel, mem_read, mem_write, [3:0]mem_wrbits}
	function [6:0] mem_ctrl (input [3:0] mem_cstate, input [31:0] mem_ir, 
									input [31:0]  mem_addr);
									
		// IFのときmem_sel=0 => pc
		if (mem_cstate[0] == 1'b1) begin
			mem_ctrl = 7'b0_1_0_0000;
			end
			
		// WBのとき	
		else if (mem_cstate[3] == 1'b1) begin
			// Load命令はsel=1, read=1
			if (mem_ir[6:0] == 7'b0000011) begin 
				mem_ctrl = 7'b1_1_0_0000;
				end
			// Store命令はsel=1, read=1, write=1
			else if (mem_ir[6:0] == 7'b0100011) 
				case(mem_ir[14:12]) // オフセットでwrbitsを指定
					3'b000: begin // SB
						if (mem_addr[1:0] == 2'b00)
							mem_ctrl = 7'b1_1_1_0001;
						if (mem_addr[1:0] == 2'b01)
							mem_ctrl = 7'b1_1_1_0010;
						if (mem_addr[1:0] == 2'b10)
							mem_ctrl = 7'b1_1_1_0100;
						if (mem_addr[1:0] == 2'b11)
							mem_ctrl = 7'b1_1_1_1000;
						end
					3'b001: begin // SH
						if (mem_addr[1:0] == 2'b00)
							mem_ctrl = 7'b1_1_1_0011;
						if (mem_addr[1:0] == 2'b10)
							mem_ctrl = 7'b1_1_1_1100;
						end
					3'b010: begin // SW
						mem_ctrl = 7'b1_1_1_1111;
						end
					default: mem_ctrl = 7'b0;
					
				endcase
				else
					mem_ctrl = 7'b0;
			end

		endfunction
	
	
	// ir_ctrl = {ir_ld} 
	function ir_ctrl (input [3:0] ir_cstate);
	
		// IFのときir_ld = 1
		if (ir_cstate[0] == 1'b1)
			ir_ctrl = 1'b1;
			else
				ir_ctrl = 1'b0;
		endfunction
	
	
	// reg1_ctrl = {rs1_addr, rs2_addr, rd_addr}
	function [14:0] reg1_ctrl (input [31:0] reg1_ir);
	
		reg1_ctrl = {reg1_ir[19:15], reg1_ir[24:20], reg1_ir[11:7]};
		endfunction
		
		
	// reg2_ctrl = {a_ld, b_ld}
	function [1:0] reg2_ctrl (input [31:0] reg2_cstate);
	
		// DEのときa_ld, b_ldともに1
		if (reg2_cstate[1] == 1'b1)
			reg2_ctrl = 2'b11;
		else 
			reg2_ctrl = 2'b00;
		endfunction
		
		
	// reg3_ctrl = {[1:0]rd_sel, rd_ld}
	function [2:0] reg3_ctrl (input [31:0] reg3_cstate, input [31:0] reg3_ir);
	
		// WBのとき
		if (reg3_cstate[3] == 1'b1) begin 
			case(reg3_ir[6:0])
			// 演算命令 => creg
				7'b0010011: reg3_ctrl = 3'b10_1; // 即値演算系
				7'b0110011: reg3_ctrl = 3'b10_1; // A+B演算系
				7'b0110111: reg3_ctrl = 3'b10_1; // LUI
				7'b0010111: reg3_ctrl = 3'b10_1; // AUIPC
			// ロード命令 => mem_rddata
				7'b0000011: reg3_ctrl = 3'b00_1; // Load系
			// ジャンプ命令	=> pc
				7'b1101111: reg3_ctrl = 3'b01_1; // JAL
				7'b1100111: reg3_ctrl = 3'b01_1; // JALR
				
				default: reg3_ctrl = 3'b000;
				endcase
			end
			else
				reg3_ctrl = 3'b000;
		endfunction
		
		
	// imm_ctrl = {[31:0]imm}
	function [31:0] imm_ctrl (input [31:0] imm_ir);
	
		// I-type (JALR, Load, 即値演算)
		if ((imm_ir[6:0] == 7'b1100111 || imm_ir[6:0] == 7'b0000011 || imm_ir[6:0] == 7'b0010011) && (imm_ir[14:12] != 3'b001 || imm_ir[14:12] != 3'b101)) begin
			if (imm_ir[31] == 1'b1) begin
				imm_ctrl = {20'b1111_1111_1111_1111_1111, imm_ir[31:20]};
				end
				else begin
					imm_ctrl = {20'b0, imm_ir[31:20]};
					end
			end
			
		// S-type (Store)
		if (imm_ir[6:0] == 7'b0100011) begin
			if (imm_ir[31] == 1'b1) begin
				imm_ctrl = {20'b1111_1111_1111_1111_1111, imm_ir[31:25], imm_ir[11:7]};
				end
				else begin
					imm_ctrl = {20'b0, imm_ir[31:25], imm_ir[11:7]};
					end
			end
			
		// B-type (分岐命令)
		if (imm_ir[6:0] == 7'b1100011) begin
			if (imm_ir[31] == 1'b1) begin
				imm_ctrl = {19'b1111_1111_1111_1111_1111, imm_ir[31], imm_ir[7], imm_ir[30:25], imm_ir[11:8], 1'b0};
				end
				else begin
					imm_ctrl = {19'b0, imm_ir[31], imm_ir[7], imm_ir[30:25], imm_ir[11:8], 1'b0};
					end
			end
			
		// U-type (LUI, AUIPC)
		if (imm_ir[6:0] == 7'b0110111 || imm_ir[6:0] == 7'b0010111) begin
			imm_ctrl = {imm_ir[31:12], 12'b0};
			end
			
		// J-type (JAL)
		if (imm_ir[6:0] == 7'b1101111) begin
			if (imm_ir[31] == 1'b1) begin
				imm_ctrl = {11'b1111_1111_1111, imm_ir[31], imm_ir[19:12], imm_ir[20], imm_ir[30:21], 1'b0};
				end
				else begin
					imm_ctrl = {11'b0, imm_ir[31], imm_ir[19:12], imm_ir[20], imm_ir[30:21], 1'b0};
					end
			end
			
		// 即値シフト
		if ((imm_ir[6:0] == 7'b0010011) && (imm_ir[14:12] == 3'b001 || imm_ir[14:12] == 3'b101)) begin
			if (imm_ir[24] == 1'b1) begin
				imm_ctrl = {20'b1111_1111_1111_1111_1111, imm_ir[31:20]};
				end
				else begin
					imm_ctrl = {20'b0, imm_ir[31:20]};
					end
			end
			
		endfunction
	
	
	// ALU_ctrl = {a_sel, b_sel, [3:0]alu_ctl}
	function [5:0] ALU_ctrl (input [3:0] ALU_cstate, input [31:0] ALU_ir);
	
		// EXのとき
		if (ALU_cstate[2] == 1'b1) begin 
			case(ALU_ir[6:0])
			
				// ADD系 A+B
				7'b0110011: begin 
					if (ALU_ir[14:12] == 3'b000) begin
						if (ALU_ir[30] == 0) // add
							ALU_ctrl = 6'b0_0_1000;
							else // sub
								ALU_ctrl = 6'b0_0_1001;
						end
					if (ALU_ir[14:12] == 3'b001) begin
						ALU_ctrl = 6'b0_0_1101; // sll
						end
					if (ALU_ir[14:12] == 3'b010) begin
						ALU_ctrl = 6'b0_0_0100; // slt
						end
					if (ALU_ir[14:12] == 3'b011) begin
						ALU_ctrl = 6'b0_0_0110; // sltu
						end
					if (ALU_ir[14:12] == 3'b100) begin
						ALU_ctrl = 6'b0_0_1010; // xor
						end
					if (ALU_ir[14:12] == 3'b101) begin
						if (ALU_ir[30] == 1'b0) // srl
							ALU_ctrl = 6'b0_0_1110;
							else // sra
								ALU_ctrl = 6'b0_0_1111;
						end
					if (ALU_ir[14:12] == 3'b110) begin
						ALU_ctrl = 6'b0_0_1011; // or
						end
					if (ALU_ir[14:12] == 3'b111) begin
						ALU_ctrl = 6'b0_0_1100; // and
						end
					end
					
				// ADDI系 A+imm
				7'b0010011: begin
					if (ALU_ir[14:12] == 3'b000) begin
						ALU_ctrl = 6'b0_1_1000; // addi
						end
					if (ALU_ir[14:12] == 3'b010) begin
						ALU_ctrl = 6'b0_1_0100; // slti
						end
					if (ALU_ir[14:12] == 3'b011) begin
						ALU_ctrl = 6'b0_1_0110; // sltiu
						end
					if (ALU_ir[14:12] == 3'b100) begin
						ALU_ctrl = 6'b0_1_1010; // xori
						end
					if (ALU_ir[14:12] == 3'b110) begin
						ALU_ctrl = 6'b0_1_1011; // ori
						end
					if (ALU_ir[14:12] == 3'b111) begin
						ALU_ctrl = 6'b0_1_1100; // andi
						end
					if (ALU_ir[14:12] == 3'b001) begin
						ALU_ctrl = 6'b0_1_1101; // slli
						end
					if (ALU_ir[14:12] == 3'b101) begin
						if (ALU_ir[30] == 1'b0) // srli
							ALU_ctrl = 6'b0_1_1110;
							else // srai
								ALU_ctrl = 6'b0_1_1111;
						end
					end
					
				// Load系 A+imm
				7'b0000011: ALU_ctrl = 6'b0_1_1000;
				
				// Store系 A+imm
				7'b0100011: ALU_ctrl = 6'b0_1_1000;
				
				// LUI imm
				7'b0110111: ALU_ctrl = 6'b0_1_0000;
				
				// AUIPC pc+imm
				7'b0010111: ALU_ctrl = 6'b1_1_1000;
				
				// JAL pc+imm
				7'b1101111: ALU_ctrl = 6'b1_1_1000;
				
				// JALR A+imm
				7'b1100111: ALU_ctrl = 6'b0_1_1000;
				
				// BEQ系 pc+imm
				7'b1100011: ALU_ctrl = 6'b1_1_1000;
				
				default: ALU_ctrl = 6'b0_0_0000; 
				endcase
			end
		
		// WBのとき
		if (ALU_cstate[3] == 1) begin 
			if (ALU_ir[6:0] == 7'b1100011) begin // beq系
				if (ALU_ir[14:12] == 3'b000) begin
					ALU_ctrl = 6'b0_0_0010; // beq
					end
				if (ALU_ir[14:12] == 3'b001) begin
					ALU_ctrl = 6'b0_0_0011; // bne
					end
				if (ALU_ir[14:12] == 3'b100) begin
					ALU_ctrl = 6'b0_0_0100; // blt
					end
				if (ALU_ir[14:12] == 3'b101) begin
					ALU_ctrl = 6'b0_0_0101; // bge
					end
				if (ALU_ir[14:12] == 3'b110) begin
					ALU_ctrl = 6'b0_0_0110; // bltu
					end
				if (ALU_ir[14:12] == 3'b111) begin
					ALU_ctrl = 6'b0_0_0111; // bgeu
					end
				end
			end
		endfunction
				
				
	function c_ctrl(input [3:0] c_cstate);
		// EXのとき
		if (c_cstate[2] == 1'b1) begin
			c_ctrl = 1'b1;
			end
			else
				c_ctrl = 1'b0;
		endfunction
		
		
	// 上から順にfunctonをassignする	
	assign {pc_sel, pc_ld} = pc_ctrl(cstate, ir, alu_out);
	assign {mem_sel, mem_read, mem_write, mem_wrbits} = mem_ctrl(cstate, ir, addr);
	assign ir_ld = ir_ctrl(cstate);
	assign {rs1_addr, rs2_addr, rd_addr} = reg1_ctrl(ir); 
	assign {a_ld, b_ld} = reg2_ctrl(cstate);
	assign {rd_sel, rd_ld} = reg3_ctrl(cstate, ir);
	assign imm = imm_ctrl(ir);
	assign {a_sel, b_sel, alu_ctl} = ALU_ctrl(cstate, ir);
	assign c_ld = c_ctrl(cstate);
				

endmodule // controller
