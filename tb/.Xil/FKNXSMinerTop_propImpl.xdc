set_property SRC_FILE_INFO {cfile:/home/wolf/FPGA/NXSMiner-FK33/NXSMiner-FK33.srcs/sources_1/ip/MMCM600/MMCM600.xdc rfile:../../../NXSMiner-FK33/NXSMiner-FK33.srcs/sources_1/ip/MMCM600/MMCM600.xdc id:1 order:EARLY scoped_inst:MainMMCM/inst} [current_design]
set_property SRC_FILE_INFO {cfile:/home/wolf/FPGA/NXSMiner-FK33/NXSMiner-FK33.srcs/constrs_1/new/pblocks.xdc rfile:../../../NXSMiner-FK33/NXSMiner-FK33.srcs/constrs_1/new/pblocks.xdc id:2} [current_design]
current_instance MainMMCM/inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports clk_in1_p]] 0.005
current_instance
set_property src_info {type:XDC file:2 line:1 export:INPUT save:INPUT read:READ} [current_design]
create_pblock Block1ProcessTest
add_cells_to_pblock [get_pblocks Block1ProcessTest] [get_cells -quiet [list NexusMinerCore/Block1ProcessTest]]
set_property src_info {type:XDC file:2 line:3 export:INPUT save:INPUT read:READ} [current_design]
create_pblock Block2ProcessTest
add_cells_to_pblock [get_pblocks Block2ProcessTest] [get_cells -quiet [list NexusMinerCore/Block2ProcessTest]]
set_property src_info {type:XDC file:2 line:5 export:INPUT save:INPUT read:READ} [current_design]
create_pblock KeccakProcessTest
add_cells_to_pblock [get_pblocks KeccakProcessTest] [get_cells -quiet [list NexusMinerCore/KeccakProcessTest]]
