module CPU(clk);

	// Inputs
	input clk;

	// Registers
	// reg [31:0] PC, Regfile[0:31], Memory[0:1023], MDR, A, B, ALUResult, IR;
	reg [31:0] PC, Regfile[0:31], Memory[0:1023];
	reg [2:0]  stateA, stateB, stateC, stateD, stateE;


	parameter PC 			= 0;
	parameter IR 			= 1;
	parameter A 			= 2;
	parameter B 			= 3;
	parameter ID_ALUResult	= 4;
	parameter EX_ALUResult	= 5;
	parameter MDR			= 6;

	reg [31:0] IFIDReg [0:7], IDEXReg [0:7], EXMEMReg [0:7], MEMWBReg [0:7]; 

	// Wires
	wire [5:0] opcode, func;
	wire [4:0] rs, rtID, rtWB, rd, sa;
	wire [31:0] immediateID, immediateEX, immediateWB;
	wire [25:0] target;

	// R-type instructions (ADD, SUB, SLT, JR)
	// opcode(6), rs(5), rt(5), rd(5), sa(5), func(6)
	// NOTE: sa is the shift amount

	// I-type instructions (LW, SW, XORI, BNE)
	// opcode(6), rs(5), rt(5), immediate(16)

	// J-type instructions (J, JAL)
	// opcode(6), target(26)


	// Assign wires
	assign opcode = IR[31:26];
	assign rs = IFIDReg[IR][25:21];
	assign rtID = IFIDReg[IR][20:16];
	assign rtWB = MEMWBReg[IR][20:16];
	assign rd = MEMWBReg[IR][15:11];
	assign sa = IR[10:6];
	assign func = IR[5:0];
	assign immediateID = {{16{IFIDReg[IR][15]}}, IFIDReg[IR][15:0]};
	assign immediateEX = {{16{IDEXReg[IR][15]}}, IDEXReg[IR][15:0]};
	assign immediateWB = {{16{MEMWBReg[IR][15]}}, MEMWBReg[IR][15:0]};
	assign target = IR[25:0];

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
	parameter IF 	= 0;
	parameter ID	= 1;
	parameter EX 	= 2;
	parameter MEM 	= 3;
	parameter WB 	= 4;


	integer i;
	initial begin 
		PC = 0;
		stateA = 0; stateB = 0; stateC = 0; stateD = 0; stateE = 0; 
		for ( i=0; i<32; i = i+1 ) begin
      		Regfile[i] = 0000_0000_0000_0000_0000_0000_0000_0000;
   		end
   		Memory[1021] = 'h00000001;
   		Memory[1022] = 'h00000002;
		$readmemb("..\\..\\MARS\\allinstructions.dat", Memory);
	end

	always @(posedge clk) begin

		case (stateA)
			IF: begin
				IFIDReg[IR] <= Memory[PC];
				PC <= PC + 1;
				IFIDReg[PC] <= PC + 1;
				stateA = ID;
			end
			
			ID: begin
				IDEXReg[A] <= Regfile[rs];
				IDEXReg[B] <= Regfile[rtID];
				if(opcode == OP_BNE) begin
					IDEXReg[ID_ALUResult] <= PC + immediateID;
				end
				else if (opcode == OP_J) begin
					PC <= {PC[31:28],IR[25],IR[25],IR[25:0]};
				end
				
				else if (opcode == OP_R_TYPE || opcode == OP_XORI || opcode == OP_LW || opcode == OP_SW) begin
					if (func == FUNC_SYSCALL) stateA = -1;
				end

				stateA = EX;

			end

			EX: begin
				if(opcode == OP_LW || opcode == OP_SW) begin
					EXMEMReg[EX_ALUResult] = IDEXReg[A] + immediateEX;
				end
				else if (opcode == OP_JAL) begin
					PC <= {PC[31:28],IR[25],IR[25],IR[25:0]};
				end
				else if (opcode == OP_BNE) begin
					if (IDEXReg[A] != IDEXReg[B]) PC <= EXMEMReg[ID_ALUResult];
				end
				else if (opcode == OP_XORI) begin
					EXMEMReg[EX_ALUResult] <= IDEXReg[A]^immediateEX;
				end
				else if (opcode == OP_R_TYPE) begin
					if (func == FUNC_JR) begin
						PC <= IDEXReg[A];
					end
					else if (func == FUNC_ADD) begin
						EXMEMReg[EX_ALUResult] <= IDEXReg[A] + IDEXReg[B];
					end
					else if (func == FUNC_SUB) begin
						EXMEMReg[EX_ALUResult] <= IDEXReg[A] - IDEXReg[B];
					end
					else if (func == FUNC_SLT) begin
						EXMEMReg[EX_ALUResult] <= (IDEXReg[A] < IDEXReg[B]) ? 1 : 0;
					end
				end
				
				stateA = MEM;

			end

			MEM: begin
				if(opcode == OP_LW) begin
					MEMWBReg[MDR] <= Memory[EXMEMReg[EX_ALUResult]];
				end
				else if(opcode == OP_SW) begin
					Memory[EXMEM[EX_ALUResult]] = EXMEMReg[B];
				end
			
				stateA = WB;
			
			end

			WB: begin
				if (opcode == OP_LW) Regfile[rtWB] <= MEMWBReg[MDR];
				
				else if(opcode == OP_XORI) Regfile[rtWB] <= EXMEMReg[EX_ALUResult];
				
				else if(opcode == OP_R_TYPE) Regfile[rd] <= EXMEMReg[EX_ALUResult];
				
				else if (opcode == OP_LI) begin
					Regfile[rtWB] <= immediateWB;
				end

				else if (opcode == OP_JAL) begin
					// Store PC in $ra
					Regfile[31]<= EXMEMReg[PC];
				end
				stateA = IF;
			end

		
	endcase
	end

	initial
	$monitor( "time:", $time, , " $v1:", Regfile[3], " $t1:", Regfile[9], " $t2:", Regfile[10], " $t3:", Regfile[11],  " $t4:", Regfile[12], " $t5:", Regfile[13], " $t6:", Regfile[14], " $t7:", Regfile[15], " $s0:", Regfile[16], " $s1:", Regfile[17], " $sp:", Regfile[29], " $ra:", Regfile[31] );

endmodule


module CPU_TESTBENCH();
  // Inputs
  reg clk;

  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end


  CPU MY_CPU( clk );

  
endmodule
