connect_hw_server
open_hw_target 
set fpga [lindex [get_hw_devices] 1]
set file ./mkTop.bit
set_property PROGRAM.FILE $file $fpga
puts "fpga is $fpga, bit file size is [exec ls -sh $file]"
program_hw_devices $fpga
