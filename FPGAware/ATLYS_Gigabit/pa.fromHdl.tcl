
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name ATLYS_Gigabit -dir "E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/planAhead_run_1" -part xc6slx45csg324-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/src/pinlock.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {ipcore_dir/asyncfifo_16d_8w.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/dsm_clk_in_100.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/dsm_clk_in_100/example_design/dsm_clk_in_100_exdes.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/bram_tdp_2000d_16wr_8rd_synth.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir/bram_tdp_2000d_16wr_8rd.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/constants.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/uart_tx.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/uart_rx.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/uart_baud_gen.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/uart_cntrl.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/gmii_if.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/debounce.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/sync_reset.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/mdio_if.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/led_blink.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/gpio.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/gigabit_mac.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/bazlink.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {src/Top.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top top $srcset
add_files [list {E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/src/constraints.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/src/pinlock.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/asyncfifo_16d_8w.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/bram_tdp_2000d_16wr_8rd.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/rom_256d_8w.ncf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx45csg324-2
