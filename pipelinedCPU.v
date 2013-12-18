module PIPELINED_CPU(clk);

	// Inputs
	input clk;

	// Registers
	// reg [31:0] PC, Regfile[0:31], Memory[0:1023], MDR, A, B, ALUResult, IR;
	reg [31:0] PCReg, Regfile[0:31], Memory[0:1023], ForwardReg0[0:2], ForwardReg1[0:2], ForwardReg2[0:2];
	reg [2:0]  stateA, stateB, stateC, stateD, stateE;

	// Parameters for the registers that are between the stages
	parameter PC 			= 0;
	parameter IR 			= 1;
	parameter A 			= 2;
	parameter B 			= 3;
	parameter ID_ALU_RESULT	= 4;
	parameter EX_ALU_RESULT	= 5;
	parameter MDR			= 6;
	parameter JUMP_BRANCH_1	= 7;
	parameter JUMP_BRANCH_2	= 8;

	// Parameters for the registers that help with forwarding
	parameter FORWARD_DATA 	= 0;
	parameter WRITE_VAL		= 1;
	parameter DEST_REG		= 2;

	// WRITE_VAL represents
	parameter NO_WRITE 				= 0;
	parameter WRITE_FORWARD_DATA 	= 1;
	parameter WRITE_MEM				= 2;

	// reg JUMP_BRANCH_1 and JUMP_BRANCH_2 possible values
	parameter 	INACTIVE 	= 0;	// no, don't
	parameter 	ACTIVE 		= 1;	// yes, execute it

	reg [31:0] IFIDReg [0:9], IDEXReg [0:9], EXMEMReg [0:9], MEMWBReg [0:9]; 

	// Wires
	wire [5:0] opcodeID, opcodeEX, opcodeMEM, opcodeWB, funcID, funcEX;
	wire [4:0] rs, rtID, rtWB, rd, sa;
	wire [31:0] immediateID, immediateEX, immediateWB;
	wire [25:0] target;
	wire [31:0] inputA, inputB;

	// R-type instructions (ADD, SUB, SLT, JR)
	// opcode(6), rs(5), rt(5), rd(5), sa(5), func(6)
	// NOTE: sa is the shift amount

	// I-type instructions (LW, SW, XORI, BNE)
	// opcode(6), rs(5), rt(5), immediate(16)

	// J-type instructions (J, JAL)
	// opcode(6), target(26)


	// Assign wires
	assign opcodeID = IFIDReg[IR][31:26];
	assign opcodeEX = IDEXReg[IR][31:26];
	assign opcodeMEM = EXMEMReg[IR][31:26];
	assign opcodeWB = MEMWBReg[IR][31:26];

	assign funcID = IFIDReg[IR][5:0];
	assign funcEX = IDEXReg[IR][5:0];

	assign rs = IFIDReg[IR][25:21];
	assign rtID = IFIDReg[IR][20:16];
	assign rtWB = MEMWBReg[IR][20:16];
	assign rd = MEMWBReg[IR][15:11];
	
	assign immediateID = {{16{IFIDReg[IR][15]}}, IFIDReg[IR][15:0]};
	assign immediateEX = {{16{IDEXReg[IR][15]}}, IDEXReg[IR][15:0]};
	assign immediateWB = {{16{MEMWBReg[IR][15]}}, MEMWBReg[IR][15:0]};

	//assign sa = IR[10:6];
	//assign target = IR[25:0];

	// opcodes
	parameter OP_LI   = 6'b001001;
	parameter OP_LW   = 6'b100011;
	parameter OP_SW   = 6'b101011;
	parameter OP_J    = 6'b000010;
	parameter OP_JAL  = 6'b000011;
	parameter OP_BNE  = 6'b000101;
	parameter OP_XORI = 6'b001110;
	parameter OP_R_TYPE  = 6'b000000;

	// func codes
	parameter FUNC_JR   = 6'b001000;
	parameter FUNC_ADD  = 6'b100000;
	parameter FUNC_SUB  = 6'b100010;
	parameter FUNC_SLT  = 6'b101010;
	parameter FUNC_SYSCALL = 6'b001100;

	// stateA definitions
	parameter IDLE 	= -1;
	parameter IF 	=  0;
	parameter ID	=  1;
	parameter EX 	=  2;
	parameter MEM 	=  3;
	parameter WB 	=  4;

	assign inputA = 
		((IDEXReg[IR][25:21] == ForwardReg0[DEST_REG]) && ForwardReg0[WRITE_VAL] == WRITE_FORWARD_DATA) ? ForwardReg0[FORWARD_DATA]:
		((IDEXReg[IR][25:21] == ForwardReg0[DEST_REG]) && ForwardReg0[WRITE_VAL] == WRITE_MEM) ? Memory[ForwardReg0[FORWARD_DATA]]:
		((IDEXReg[IR][25:21] == ForwardReg1[DEST_REG]) && ForwardReg1[WRITE_VAL] == WRITE_FORWARD_DATA) ? ForwardReg1[FORWARD_DATA]:
		((IDEXReg[IR][25:21] == ForwardReg1[DEST_REG]) && ForwardReg1[WRITE_VAL] == WRITE_MEM) ? Memory[ForwardReg1[FORWARD_DATA]]:
		((IDEXReg[IR][25:21] == ForwardReg2[DEST_REG]) && ForwardReg2[WRITE_VAL] == WRITE_FORWARD_DATA) ? ForwardReg2[FORWARD_DATA]:
		((IDEXReg[IR][25:21] == ForwardReg2[DEST_REG]) && ForwardReg2[WRITE_VAL] == WRITE_MEM) ? Memory[ForwardReg2[FORWARD_DATA]]:
			IDEXReg[A];

	assign inputB = 
		((IDEXReg[IR][20:16] == ForwardReg0[DEST_REG]) && ForwardReg0[WRITE_VAL] == WRITE_FORWARD_DATA) ? ForwardReg0[FORWARD_DATA]:
		((IDEXReg[IR][20:16] == ForwardReg0[DEST_REG]) && ForwardReg0[WRITE_VAL] == WRITE_MEM) ? Memory[ForwardReg0[FORWARD_DATA]]:
		((IDEXReg[IR][20:16] == ForwardReg1[DEST_REG]) && ForwardReg1[WRITE_VAL] == WRITE_FORWARD_DATA) ? ForwardReg1[FORWARD_DATA]:
		((IDEXReg[IR][20:16] == ForwardReg1[DEST_REG]) && ForwardReg1[WRITE_VAL] == WRITE_MEM) ? Memory[ForwardReg1[FORWARD_DATA]]:
		((IDEXReg[IR][20:16] == ForwardReg2[DEST_REG]) && ForwardReg2[WRITE_VAL] == WRITE_FORWARD_DATA) ? ForwardReg2[FORWARD_DATA]:
		((IDEXReg[IR][20:16] == ForwardReg2[DEST_REG]) && ForwardReg2[WRITE_VAL] == WRITE_MEM) ? Memory[ForwardReg2[FORWARD_DATA]]:
			IDEXReg[B];

	integer i;
	initial begin 
		PCReg = 0;
		stateA = IF; stateB = IDLE; stateC = IDLE; stateD = IDLE; stateE = IDLE; 
		for ( i=0; i<32; i = i+1 ) begin
      		Regfile[i] = 0000_0000_0000_0000_0000_0000_0000_0000;
   		end
   		
   		Memory[1021] = 'h00000001;
   		Memory[1022] = 'h00000002;

   		ForwardReg0[0] = 'h00000000;
   		ForwardReg0[1] = 'h00000000;
   		ForwardReg0[2] = 'h00000000;

   		ForwardReg1[0] = 'h00000000;
   		ForwardReg1[1] = 'h00000000;
   		ForwardReg1[2] = 'h00000000;

   		ForwardReg2[0] = 'h00000000;
   		ForwardReg2[1] = 'h00000000;
   		ForwardReg2[2] = 'h00000000;

   		IFIDReg[JUMP_BRANCH_1] 	= ACTIVE;
   		IDEXReg[JUMP_BRANCH_1] 	= ACTIVE;
   		EXMEMReg[JUMP_BRANCH_1]	= ACTIVE;
   		MEMWBReg[JUMP_BRANCH_1] = ACTIVE;
   		IFIDReg[JUMP_BRANCH_2] 	= ACTIVE;
   		IDEXReg[JUMP_BRANCH_2] 	= ACTIVE;
   		EXMEMReg[JUMP_BRANCH_2]	= ACTIVE;
   		MEMWBReg[JUMP_BRANCH_2] = ACTIVE;

		$readmemb("datahazard.dat", Memory);

	end

	always @(posedge clk) begin

		case (stateA)
			IF: begin
				IFIDReg[IR] <= Memory[PCReg];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) || opcodeID == OP_J || opcodeID == OP_JAL)) begin
					PCReg <= PCReg + 1;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
					IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
				end
				IFIDReg[PC] <= PCReg + 1;
				stateA <= ID;
				stateB <= IF;
			end
			
			ID: begin
				IDEXReg[A] <= Regfile[rs];
				IDEXReg[B] <= Regfile[rtID];
				IDEXReg[IR] <= IFIDReg[IR];
				IDEXReg[PC] <= IFIDReg[PC];
				IDEXReg[JUMP_BRANCH_2] <= IFIDReg[JUMP_BRANCH_2];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR))) begin 
					IDEXReg[JUMP_BRANCH_1] <= IFIDReg[JUMP_BRANCH_1];
				end 
				if(opcodeID == OP_BNE) begin
					IDEXReg[ID_ALU_RESULT] <= PCReg + immediateID;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
				end
				else if (opcodeID == OP_J || opcodeID == OP_JAL) begin
					PCReg <= {IFIDReg[PC][31:28],IFIDReg[IR][25],IFIDReg[IR][25],IFIDReg[IR][25:0]};
					IFIDReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else if (opcodeID == OP_R_TYPE || opcodeID == OP_XORI || opcodeID == OP_LW || opcodeID == OP_SW) begin
					if (funcID == FUNC_SYSCALL) stateA <= -1;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
				end

				stateA <= EX;

			end

			EX: begin
				EXMEMReg[IR] <= IDEXReg[IR];
				EXMEMReg[PC] <= IDEXReg[PC];
				EXMEMReg[JUMP_BRANCH_1] <= IDEXReg[JUMP_BRANCH_1];
				EXMEMReg[JUMP_BRANCH_2] <= IDEXReg[JUMP_BRANCH_2];
				if (opcodeEX == OP_BNE) begin
					if (inputA != inputB) begin 
						PCReg <= IDEXReg[ID_ALU_RESULT];
						IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
					end
					else begin
						PCReg <= PCReg + 1;
						IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= ACTIVE;
					end
				end
				else if (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) begin
					PCReg <= inputA;
					IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
					IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else begin
					if (IDEXReg[JUMP_BRANCH_1] == ACTIVE && IDEXReg[JUMP_BRANCH_2] == ACTIVE) begin
						if(opcodeEX == OP_LW || opcodeEX == OP_SW) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA + immediateEX;
							EXMEMReg[B] <= inputB;
						end
						else if (opcodeEX == OP_XORI) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA^immediateEX;
						end
						else if (opcodeEX == OP_R_TYPE) begin
							if (funcEX == FUNC_JR) begin
								PCReg <= inputA;
							end
							else if (funcEX == FUNC_ADD) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA + inputB;
							end
							else if (funcEX == FUNC_SUB) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA - inputB;
							end
							else if (funcEX == FUNC_SLT) begin
								EXMEMReg[EX_ALU_RESULT] <= (inputA < inputB) ? 1 : 0;
							end
						end
					end
				end
				
				stateA <= MEM;

			end

			MEM: begin
				MEMWBReg[IR] <= EXMEMReg[IR];
				MEMWBReg[PC] <= EXMEMReg[PC];
				MEMWBReg[JUMP_BRANCH_1] <= EXMEMReg[JUMP_BRANCH_1];
				MEMWBReg[JUMP_BRANCH_2] <= EXMEMReg[JUMP_BRANCH_2];
				MEMWBReg[EX_ALU_RESULT] <= EXMEMReg[EX_ALU_RESULT];
				if (EXMEMReg[JUMP_BRANCH_1] == ACTIVE && EXMEMReg[JUMP_BRANCH_2] == ACTIVE) begin
					if(opcodeMEM == OP_LW) begin
						MEMWBReg[MDR] <= Memory[EXMEMReg[EX_ALU_RESULT]];
					end
					else if(opcodeMEM == OP_SW ) begin
						Memory[EXMEMReg[EX_ALU_RESULT]] <= EXMEMReg[B];
					end
				end
			
				stateA <= WB;
			
			end

			WB: begin
				if (MEMWBReg[JUMP_BRANCH_1] == ACTIVE && MEMWBReg[JUMP_BRANCH_2] == ACTIVE) begin
					if (opcodeWB == OP_LW) Regfile[rtWB] <= MEMWBReg[MDR];
					
					else if(opcodeWB == OP_XORI) Regfile[rtWB] <= MEMWBReg[EX_ALU_RESULT];
					
					else if(opcodeWB == OP_R_TYPE) Regfile[rd] <= MEMWBReg[EX_ALU_RESULT];
					
					else if (opcodeWB == OP_LI) begin
						Regfile[rtWB] <= immediateWB;
					end

					else if (opcodeWB == OP_JAL) begin
						// Store PC in $ra
						Regfile[31]<= MEMWBReg[PC];
					end
				end
			end

		endcase

		// Second Instruction (StateB)
		case (stateB)
			IF: begin
				IFIDReg[IR] <= Memory[PCReg];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) || opcodeID == OP_J || opcodeID == OP_JAL)) begin
					PCReg <= PCReg + 1;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
					IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
				end
				IFIDReg[PC] <= PCReg + 1;
				stateB <= ID;
				stateC <= IF;
			end
			
			ID: begin
				IDEXReg[A] <= Regfile[rs];
				IDEXReg[B] <= Regfile[rtID];
				IDEXReg[IR] <= IFIDReg[IR];
				IDEXReg[PC] <= IFIDReg[PC];
				IDEXReg[JUMP_BRANCH_2] <= IFIDReg[JUMP_BRANCH_2];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR))) begin 
					IDEXReg[JUMP_BRANCH_1] <= IFIDReg[JUMP_BRANCH_1];
				end 
				if(opcodeID == OP_BNE) begin
					IDEXReg[ID_ALU_RESULT] <= PCReg + immediateID;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
				end
				else if (opcodeID == OP_J || opcodeID == OP_JAL) begin
					PCReg <= {IFIDReg[PC][31:28],IFIDReg[IR][25],IFIDReg[IR][25],IFIDReg[IR][25:0]};
					IFIDReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else if (opcodeID == OP_R_TYPE || opcodeID == OP_XORI || opcodeID == OP_LW || opcodeID == OP_SW) begin
					if (funcID == FUNC_SYSCALL) stateB <= -1;
				end

				stateB <= EX;

			end

			EX: begin
				EXMEMReg[IR] <= IDEXReg[IR];
				EXMEMReg[PC] <= IDEXReg[PC];
				EXMEMReg[JUMP_BRANCH_1] <= IDEXReg[JUMP_BRANCH_1];
				EXMEMReg[JUMP_BRANCH_2] <= IDEXReg[JUMP_BRANCH_2];
				if (opcodeEX == OP_BNE) begin
					if (inputA != inputB) begin 
						PCReg <= IDEXReg[ID_ALU_RESULT];
						IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
					end
					else begin
						PCReg <= PCReg + 1;
						IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= ACTIVE;
					end
				end
				else if (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) begin
					PCReg <= inputA;
					IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
					IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else begin
					if (IDEXReg[JUMP_BRANCH_1] == ACTIVE && IDEXReg[JUMP_BRANCH_2] == ACTIVE) begin
						if(opcodeEX == OP_LW || opcodeEX == OP_SW) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA + immediateEX;
							EXMEMReg[B] <= inputB;
						end
						else if (opcodeEX == OP_XORI) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA^immediateEX;
						end
						else if (opcodeEX == OP_R_TYPE) begin
							if (funcEX == FUNC_JR) begin
								PCReg <= inputA;
							end
							else if (funcEX == FUNC_ADD) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA + inputB;
							end
							else if (funcEX == FUNC_SUB) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA - inputB;
							end
							else if (funcEX == FUNC_SLT) begin
								EXMEMReg[EX_ALU_RESULT] <= (inputA < inputB) ? 1 : 0;
							end
						end
					end
				end
				
				stateB <= MEM;

			end

			MEM: begin
				MEMWBReg[IR] <= EXMEMReg[IR];
				MEMWBReg[PC] <= EXMEMReg[PC];
				MEMWBReg[JUMP_BRANCH_1] <= EXMEMReg[JUMP_BRANCH_1];
				MEMWBReg[JUMP_BRANCH_2] <= EXMEMReg[JUMP_BRANCH_2];
				MEMWBReg[EX_ALU_RESULT] <= EXMEMReg[EX_ALU_RESULT];
				if (EXMEMReg[JUMP_BRANCH_1] == ACTIVE && EXMEMReg[JUMP_BRANCH_2] == ACTIVE) begin
					if(opcodeMEM == OP_LW) begin
						MEMWBReg[MDR] <= Memory[EXMEMReg[EX_ALU_RESULT]];
					end
					else if(opcodeMEM == OP_SW ) begin
						Memory[EXMEMReg[EX_ALU_RESULT]] <= EXMEMReg[B];
					end
				end
			
				stateB <= WB;
			
			end

			WB: begin
				if (MEMWBReg[JUMP_BRANCH_1] == ACTIVE && MEMWBReg[JUMP_BRANCH_2] == ACTIVE) begin
					if (opcodeWB == OP_LW) Regfile[rtWB] <= MEMWBReg[MDR];
					
					else if(opcodeWB == OP_XORI) Regfile[rtWB] <= MEMWBReg[EX_ALU_RESULT];
					
					else if(opcodeWB == OP_R_TYPE) Regfile[rd] <= MEMWBReg[EX_ALU_RESULT];
					
					else if (opcodeWB == OP_LI) begin
						Regfile[rtWB] <= immediateWB;
					end

					else if (opcodeWB == OP_JAL) begin
						// Store PC in $ra
						Regfile[31]<= MEMWBReg[PC];
					end
				end
			end
		endcase

		// Third Instruction (StateC)
		case (stateC)
			IF: begin
				IFIDReg[IR] <= Memory[PCReg];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) || opcodeID == OP_J || opcodeID == OP_JAL)) begin
					PCReg <= PCReg + 1;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
					IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
				end
				IFIDReg[PC] <= PCReg + 1;
				stateC <= ID;
				stateD <= IF;
			end
			
			ID: begin
				IDEXReg[A] <= Regfile[rs];
				IDEXReg[B] <= Regfile[rtID];
				IDEXReg[IR] <= IFIDReg[IR];
				IDEXReg[PC] <= IFIDReg[PC];
				IDEXReg[JUMP_BRANCH_2] <= IFIDReg[JUMP_BRANCH_2];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR))) begin 
					IDEXReg[JUMP_BRANCH_1] <= IFIDReg[JUMP_BRANCH_1];
				end 
				if(opcodeID == OP_BNE) begin
					IDEXReg[ID_ALU_RESULT] <= PCReg + immediateID;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
				end
				else if (opcodeID == OP_J || opcodeID == OP_JAL) begin
					PCReg <= {IFIDReg[PC][31:28],IFIDReg[IR][25],IFIDReg[IR][25],IFIDReg[IR][25:0]};
					IFIDReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else if (opcodeID == OP_R_TYPE || opcodeID == OP_XORI || opcodeID == OP_LW || opcodeID == OP_SW) begin
					if (funcID == FUNC_SYSCALL) stateC <= -1;
				end

				stateC <= EX;

			end

			EX: begin
				EXMEMReg[IR] <= IDEXReg[IR];
				EXMEMReg[PC] <= IDEXReg[PC];
				EXMEMReg[JUMP_BRANCH_1] <= IDEXReg[JUMP_BRANCH_1];
				EXMEMReg[JUMP_BRANCH_2] <= IDEXReg[JUMP_BRANCH_2];
				if (opcodeEX == OP_BNE) begin
					if (inputA != inputB) begin 
						PCReg <= IDEXReg[ID_ALU_RESULT];
						IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
					end
					else begin
						PCReg <= PCReg + 1;
						IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= ACTIVE;
					end
				end
				else if (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) begin
					PCReg <= inputA;
					IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
					IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else begin
					if (IDEXReg[JUMP_BRANCH_1] == ACTIVE && IDEXReg[JUMP_BRANCH_2] == ACTIVE) begin
						if(opcodeEX == OP_LW || opcodeEX == OP_SW) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA + immediateEX;
							EXMEMReg[B] <= inputB;
						end
						else if (opcodeEX == OP_XORI) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA^immediateEX;
						end
						else if (opcodeEX == OP_R_TYPE) begin
							if (funcEX == FUNC_JR) begin
								PCReg <= inputA;
							end
							else if (funcEX == FUNC_ADD) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA + inputB;
							end
							else if (funcEX == FUNC_SUB) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA - inputB;
							end
							else if (funcEX == FUNC_SLT) begin
								EXMEMReg[EX_ALU_RESULT] <= (inputA < inputB) ? 1 : 0;
							end
						end
					end
				end
				
				stateC <= MEM;

			end

			MEM: begin
				MEMWBReg[IR] <= EXMEMReg[IR];
				MEMWBReg[PC] <= EXMEMReg[PC];
				MEMWBReg[JUMP_BRANCH_1] <= EXMEMReg[JUMP_BRANCH_1];
				MEMWBReg[JUMP_BRANCH_2] <= EXMEMReg[JUMP_BRANCH_2];
				MEMWBReg[EX_ALU_RESULT] <= EXMEMReg[EX_ALU_RESULT];
				if (EXMEMReg[JUMP_BRANCH_1] == ACTIVE && EXMEMReg[JUMP_BRANCH_2] == ACTIVE) begin
					if(opcodeMEM == OP_LW) begin
						MEMWBReg[MDR] <= Memory[EXMEMReg[EX_ALU_RESULT]];
					end
					else if(opcodeMEM == OP_SW ) begin
						Memory[EXMEMReg[EX_ALU_RESULT]] <= EXMEMReg[B];
					end
				end
			
				stateC <= WB;
			
			end

			WB: begin
				if (MEMWBReg[JUMP_BRANCH_1] == ACTIVE && MEMWBReg[JUMP_BRANCH_2] == ACTIVE) begin
					if (opcodeWB == OP_LW) Regfile[rtWB] <= MEMWBReg[MDR];
					
					else if(opcodeWB == OP_XORI) Regfile[rtWB] <= MEMWBReg[EX_ALU_RESULT];
					
					else if(opcodeWB == OP_R_TYPE) Regfile[rd] <= MEMWBReg[EX_ALU_RESULT];
					
					else if (opcodeWB == OP_LI) begin
						Regfile[rtWB] <= immediateWB;
					end

					else if (opcodeWB == OP_JAL) begin
						// Store PC in $ra
						Regfile[31]<= MEMWBReg[PC];
					end
				end
			end
		endcase

		// Fourth Instruction (StateD)
		case (stateD)
			IF: begin
				IFIDReg[IR] <= Memory[PCReg];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) || opcodeID == OP_J || opcodeID == OP_JAL)) begin
					PCReg <= PCReg + 1;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
					IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
				end
				IFIDReg[PC] <= PCReg + 1;
				stateD <= ID;
				stateE <= IF;
			end
			
			ID: begin
				IDEXReg[A] <= Regfile[rs];
				IDEXReg[B] <= Regfile[rtID];
				IDEXReg[IR] <= IFIDReg[IR];
				IDEXReg[PC] <= IFIDReg[PC];
				IDEXReg[JUMP_BRANCH_2] <= IFIDReg[JUMP_BRANCH_2];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR))) begin 
					IDEXReg[JUMP_BRANCH_1] <= IFIDReg[JUMP_BRANCH_1];
				end 
				if(opcodeID == OP_BNE) begin
					IDEXReg[ID_ALU_RESULT] <= PCReg + immediateID;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
				end
				else if (opcodeID == OP_J || opcodeID == OP_JAL) begin
					PCReg <= {IFIDReg[PC][31:28],IFIDReg[IR][25],IFIDReg[IR][25],IFIDReg[IR][25:0]};
					IFIDReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else if (opcodeID == OP_R_TYPE || opcodeID == OP_XORI || opcodeID == OP_LW || opcodeID == OP_SW) begin
					if (funcID == FUNC_SYSCALL) stateD <= -1;
				end

				stateD <= EX;

			end

			EX: begin
				EXMEMReg[IR] <= IDEXReg[IR];
				EXMEMReg[PC] <= IDEXReg[PC];
				EXMEMReg[JUMP_BRANCH_1] <= IDEXReg[JUMP_BRANCH_1];
				EXMEMReg[JUMP_BRANCH_2] <= IDEXReg[JUMP_BRANCH_2];
				if (opcodeEX == OP_BNE) begin
					if (inputA != inputB) begin 
						PCReg <= IDEXReg[ID_ALU_RESULT];
						IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
					end
					else begin
						PCReg <= PCReg + 1;
						IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= ACTIVE;
					end
				end
				else if (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) begin
					PCReg <= inputA;
					IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
					IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else begin
					if (IDEXReg[JUMP_BRANCH_1] == ACTIVE && IDEXReg[JUMP_BRANCH_2] == ACTIVE) begin
						if(opcodeEX == OP_LW || opcodeEX == OP_SW) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA + immediateEX;
							EXMEMReg[B] <= inputB;
						end
						else if (opcodeEX == OP_XORI) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA^immediateEX;
						end
						else if (opcodeEX == OP_R_TYPE) begin
							if (funcEX == FUNC_JR) begin
								PCReg <= inputA;
							end
							else if (funcEX == FUNC_ADD) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA + inputB;
							end
							else if (funcEX == FUNC_SUB) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA - inputB;
							end
							else if (funcEX == FUNC_SLT) begin
								EXMEMReg[EX_ALU_RESULT] <= (inputA < inputB) ? 1 : 0;
							end
						end
					end
				end
				
				stateD <= MEM;

			end

			MEM: begin
				MEMWBReg[IR] <= EXMEMReg[IR];
				MEMWBReg[PC] <= EXMEMReg[PC];
				MEMWBReg[JUMP_BRANCH_1] <= EXMEMReg[JUMP_BRANCH_1];
				MEMWBReg[JUMP_BRANCH_2] <= EXMEMReg[JUMP_BRANCH_2];
				MEMWBReg[EX_ALU_RESULT] <= EXMEMReg[EX_ALU_RESULT];
				if (EXMEMReg[JUMP_BRANCH_1] == ACTIVE && EXMEMReg[JUMP_BRANCH_2] == ACTIVE) begin
					if(opcodeMEM == OP_LW) begin
						MEMWBReg[MDR] <= Memory[EXMEMReg[EX_ALU_RESULT]];
					end
					else if(opcodeMEM == OP_SW ) begin
						Memory[EXMEMReg[EX_ALU_RESULT]] <= EXMEMReg[B];
					end
				end
			
				stateD <= WB;
			
			end

			WB: begin
				if (MEMWBReg[JUMP_BRANCH_1] == ACTIVE && MEMWBReg[JUMP_BRANCH_2] == ACTIVE) begin
					if (opcodeWB == OP_LW) Regfile[rtWB] <= MEMWBReg[MDR];
					
					else if(opcodeWB == OP_XORI) Regfile[rtWB] <= MEMWBReg[EX_ALU_RESULT];
					
					else if(opcodeWB == OP_R_TYPE) Regfile[rd] <= MEMWBReg[EX_ALU_RESULT];
					
					else if (opcodeWB == OP_LI) begin
						Regfile[rtWB] <= immediateWB;
					end

					else if (opcodeWB == OP_JAL) begin
						// Store PC in $ra
						Regfile[31]<= MEMWBReg[PC];
					end
				end
			end
		endcase

		// Fifth Instruction (StateE)
		case (stateE)
			IF: begin
				IFIDReg[IR] <= Memory[PCReg];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) || opcodeID == OP_J || opcodeID == OP_JAL)) begin
					PCReg <= PCReg + 1;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
					IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
				end
				IFIDReg[PC] <= PCReg + 1;
				stateE <= ID;
				stateA <= IF;
			end
			
			ID: begin
				IDEXReg[A] <= Regfile[rs];
				IDEXReg[B] <= Regfile[rtID];
				IDEXReg[IR] <= IFIDReg[IR];
				IDEXReg[PC] <= IFIDReg[PC];
				IDEXReg[JUMP_BRANCH_2] <= IFIDReg[JUMP_BRANCH_2];
				if (!(opcodeEX == OP_BNE || (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR))) begin 
					IDEXReg[JUMP_BRANCH_1] <= IFIDReg[JUMP_BRANCH_1];
				end 
				if(opcodeID == OP_BNE) begin
					IDEXReg[ID_ALU_RESULT] <= PCReg + immediateID;
					IFIDReg[JUMP_BRANCH_1] <= ACTIVE;
				end
				else if (opcodeID == OP_J || opcodeID == OP_JAL) begin
					PCReg <= {IFIDReg[PC][31:28],IFIDReg[IR][25],IFIDReg[IR][25],IFIDReg[IR][25:0]};
					IFIDReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else if (opcodeID == OP_R_TYPE || opcodeID == OP_XORI || opcodeID == OP_LW || opcodeID == OP_SW) begin
					if (funcID == FUNC_SYSCALL) stateE <= -1;
				end

				stateE <= EX;

			end

			EX: begin
				EXMEMReg[IR] <= IDEXReg[IR];
				EXMEMReg[PC] <= IDEXReg[PC];
				EXMEMReg[JUMP_BRANCH_1] <= IDEXReg[JUMP_BRANCH_1];
				EXMEMReg[JUMP_BRANCH_2] <= IDEXReg[JUMP_BRANCH_2];
				if (opcodeEX == OP_BNE) begin
					if (inputA != inputB) begin 
						PCReg <= IDEXReg[ID_ALU_RESULT];
						IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
					end
					else begin
						PCReg <= PCReg + 1;
						IFIDReg[JUMP_BRANCH_2] <= ACTIVE;
						IDEXReg[JUMP_BRANCH_1] <= ACTIVE;
					end
				end
				else if (opcodeEX == OP_R_TYPE && funcEX == FUNC_JR) begin
					PCReg <= inputA;
					IFIDReg[JUMP_BRANCH_2] <= INACTIVE;
					IDEXReg[JUMP_BRANCH_1] <= INACTIVE;
				end
				else begin
					if (IDEXReg[JUMP_BRANCH_1] == ACTIVE && IDEXReg[JUMP_BRANCH_2] == ACTIVE) begin
						if(opcodeEX == OP_LW || opcodeEX == OP_SW) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA + immediateEX;
							EXMEMReg[B] <= inputB;
						end
						else if (opcodeEX == OP_XORI) begin
							EXMEMReg[EX_ALU_RESULT] <= inputA^immediateEX;
						end
						else if (opcodeEX == OP_R_TYPE) begin
							if (funcEX == FUNC_JR) begin
								PCReg <= inputA;
							end
							else if (funcEX == FUNC_ADD) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA + inputB;
							end
							else if (funcEX == FUNC_SUB) begin
								EXMEMReg[EX_ALU_RESULT] <= inputA - inputB;
							end
							else if (funcEX == FUNC_SLT) begin
								EXMEMReg[EX_ALU_RESULT] <= (inputA < inputB) ? 1 : 0;
							end
						end
					end
				end
				
				stateE <= MEM;

			end

			MEM: begin
				MEMWBReg[IR] <= EXMEMReg[IR];
				MEMWBReg[PC] <= EXMEMReg[PC];
				MEMWBReg[JUMP_BRANCH_1] <= EXMEMReg[JUMP_BRANCH_1];
				MEMWBReg[JUMP_BRANCH_2] <= EXMEMReg[JUMP_BRANCH_2];
				MEMWBReg[EX_ALU_RESULT] <= EXMEMReg[EX_ALU_RESULT];
				if (EXMEMReg[JUMP_BRANCH_1] == ACTIVE && EXMEMReg[JUMP_BRANCH_2] == ACTIVE) begin
					if(opcodeMEM == OP_LW) begin
						MEMWBReg[MDR] <= Memory[EXMEMReg[EX_ALU_RESULT]];
					end
					else if(opcodeMEM == OP_SW ) begin
						Memory[EXMEMReg[EX_ALU_RESULT]] <= EXMEMReg[B];
					end
				end
			
				stateE <= WB;
			
			end

			WB: begin
				if (MEMWBReg[JUMP_BRANCH_1] == ACTIVE && MEMWBReg[JUMP_BRANCH_2] == ACTIVE) begin
					if (opcodeWB == OP_LW) Regfile[rtWB] <= MEMWBReg[MDR];
					
					else if(opcodeWB == OP_XORI) Regfile[rtWB] <= MEMWBReg[EX_ALU_RESULT];
					
					else if(opcodeWB == OP_R_TYPE) Regfile[rd] <= MEMWBReg[EX_ALU_RESULT];
					
					else if (opcodeWB == OP_LI) begin
						Regfile[rtWB] <= immediateWB;
					end

					else if (opcodeWB == OP_JAL) begin
						// Store PC in $ra
						Regfile[31]<= MEMWBReg[PC];
					end
				end
			end
		endcase

		if (opcodeEX == OP_R_TYPE) begin 
			ForwardReg0[WRITE_VAL] <= WRITE_FORWARD_DATA;
			ForwardReg0[DEST_REG] <= IDEXReg[IR][15:11];
			if (funcEX == FUNC_ADD) begin
				ForwardReg0[FORWARD_DATA] <= inputA + inputB;
			end
			else if (funcEX == FUNC_SUB) begin
				ForwardReg0[FORWARD_DATA] <= inputA - inputB;
			end
			else if (funcEX == FUNC_SLT) begin
				ForwardReg0[FORWARD_DATA] <= (inputA < inputB) ? 1 : 0;
			end
		end
		else if (opcodeEX == OP_XORI) begin
			ForwardReg0[WRITE_VAL] <= WRITE_FORWARD_DATA;
			ForwardReg0[DEST_REG] <= IDEXReg[IR][20:16];
			ForwardReg0[FORWARD_DATA] <= inputA^immediateEX;
		end
		else if (opcodeEX == OP_LI) begin
			ForwardReg0[WRITE_VAL] <= WRITE_FORWARD_DATA;
			ForwardReg0[DEST_REG] <= IDEXReg[IR][20:16];
			ForwardReg0[FORWARD_DATA] <= immediateEX;
		end
		else if (opcodeEX == OP_LW) begin
			ForwardReg0[WRITE_VAL] <= WRITE_MEM;
			ForwardReg0[DEST_REG] <= IDEXReg[IR][20:16];
			ForwardReg0[FORWARD_DATA] <= inputA + immediateEX;
		end
		else begin
			ForwardReg0[WRITE_VAL] <= NO_WRITE;
			ForwardReg0[DEST_REG] <= NO_WRITE;
			ForwardReg0[FORWARD_DATA] <= NO_WRITE;
		end

		ForwardReg1[FORWARD_DATA] <= ForwardReg0[FORWARD_DATA];
		ForwardReg1[WRITE_VAL] <= ForwardReg0[WRITE_VAL];
		ForwardReg1[DEST_REG] <= ForwardReg0[DEST_REG];
		
		ForwardReg2[FORWARD_DATA] <= ForwardReg1[FORWARD_DATA];	
		ForwardReg2[WRITE_VAL] <= ForwardReg1[WRITE_VAL];
		ForwardReg2[DEST_REG] <= ForwardReg1[DEST_REG];

	end

	initial
	$monitor( "time:", $time, , " $v1:", Regfile[3], " $t1:", Regfile[9], " $t2:", Regfile[10], " $t3:", Regfile[11],  " $t4:", Regfile[12], " $t5:", Regfile[13], " $t6:", Regfile[14], " $t7:", Regfile[15], " $s0:", Regfile[16], " $s1:", Regfile[17], " $sp:", Regfile[29], " $ra:", Regfile[31] );

endmodule


module PIPELINED_CPU_TESTBENCH();
  // Inputs
  reg clk;

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end


  PIPELINED_CPU MY_CPU( clk );

  
endmodule
