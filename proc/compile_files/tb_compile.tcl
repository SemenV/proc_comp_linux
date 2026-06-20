vlib work

vmap work ./work

vlog -timescale "1ns / 100ps" -hazards -sv ../src/*.sv

vlog -timescale "1ns / 100ps" -hazards -sv  ../tests/proc_full/*.sv


vsim -novopt work.tb_RISC_V_TOP

add wave -recursive *




run -all
