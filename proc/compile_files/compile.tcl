vlib work

vmap work ./work

vlog -timescale "1ns / 100ps" -hazards -sv  ../export/control_unit/control_unit.sv 

vlog -timescale "1ns / 100ps" -hazards -sv "../src/*.sv"

vsim  -novopt   control_unit

add wave -recursive *

# do wave.do

run -all

