##################################
# A very simple modelsim do file #
##################################

# 1) Create a library for working in
vlib work

# 2) Compile the half adder
vlog pipelinedCPU.v

# 3) Load the module you want to simulate 
vsim PIPELINED_CPU_TESTBENCH 

# 4) Open some selected windows for viewing view structure # Opens those pesky windows 
view signals 
view wave

# 5) Show some of the signals in the wave window 
add wave -noupdate {/MY_CPU/clk}
add wave -noupdate {/MY_CPU/Regfile[9]}
add wave -noupdate {/MY_CPU/Regfile[10]}
add wave -noupdate {/MY_CPU/Regfile[11]}
add wave -noupdate {/MY_CPU/Regfile[12]}
add wave -noupdate {/MY_CPU/Regfile[13]}
add wave -noupdate {/MY_CPU/Regfile[14]}
add wave -noupdate {/MY_CPU/Regfile[15]}
add wave -noupdate {/MY_CPU/Regfile[24]}
add wave -noupdate {/MY_CPU/Regfile[25]}
add wave -noupdate {/MY_CPU/Regfile[16]}
add wave -noupdate {/MY_CPU/Regfile[17]}
add wave -noupdate {/MY_CPU/IFIDReg[JUMP_BRANCH_1]}
add wave -noupdate {/MY_CPU/IDEXReg[JUMP_BRANCH_1]}
add wave -noupdate {/MY_CPU/EXMEMReg[JUMP_BRANCH_1]}
add wave -noupdate {/MY_CPU/MEMWBReg[JUMP_BRANCH_1]}
add wave -noupdate {/MY_CPU/IFIDReg[JUMP_BRANCH_2]}
add wave -noupdate {/MY_CPU/IDEXReg[JUMP_BRANCH_2]}
add wave -noupdate {/MY_CPU/EXMEMReg[JUMP_BRANCH_2]}
add wave -noupdate {/MY_CPU/MEMWBReg[JUMP_BRANCH_2]}
add wave -noupdate {/MY_CPU/PCReg}


# 6) Run for x ns
run 500

