
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name ATLYS_Gigabit -dir "E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/planAhead_run_1" -part xc6slx45csg324-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit/gigabit_mac.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {E:/Projects/FPGAware/Osaka3/ATLYS_Gigabit} {ipcore_dir} }
add_files [list {ipcore_dir/asyncfifo_16d_8w.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/rom_256d_8w.ncf}] -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_property target_constrs_file "gigabit_mac.ucf" [current_fileset -constrset]
add_files [list {gigabit_mac.ucf}] -fileset [get_property constrset [current_run]]
link_design
