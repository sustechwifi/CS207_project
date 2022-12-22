set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
set_property PACKAGE_PIN P17 [get_ports sys_clk]

#input for barrier 
#set_property PACKAGE_PIN R17 [get_ports power_off]
#set_property PACKAGE_PIN U4 [get_ports power_on]
#set_property IOSTANDARD LVCMOS33 [get_ports power_off]
#set_property IOSTANDARD LVCMOS33 [get_ports power_on]

#input for power
set_property PACKAGE_PIN R17 [get_ports power_off]
set_property PACKAGE_PIN U4 [get_ports power_on]
set_property IOSTANDARD LVCMOS33 [get_ports power_off]
set_property IOSTANDARD LVCMOS33 [get_ports power_on]


#input for mode
set_property PACKAGE_PIN P4 [get_ports {mode[2]}]
set_property PACKAGE_PIN P3 [get_ports {mode[1]}]
set_property PACKAGE_PIN P2 [get_ports {mode[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {mode[0]}]


#output for test state
set_property PACKAGE_PIN F6 [get_ports {test[3]}]
set_property PACKAGE_PIN G4 [get_ports {test[2]}]
set_property PACKAGE_PIN G3 [get_ports {test[1]}]
set_property PACKAGE_PIN J4 [get_ports {test[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {test[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {test[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {test[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {test[0]}]

#input for turn left and right
set_property PACKAGE_PIN V1 [get_ports turn_left]
set_property PACKAGE_PIN R11 [get_ports turn_right]
set_property IOSTANDARD LVCMOS33 [get_ports turn_left]
set_property IOSTANDARD LVCMOS33 [get_ports turn_right]
set_property PACKAGE_PIN R15 [get_ports go_strait]
set_property IOSTANDARD LVCMOS33 [get_ports go_strait]

#input for control
set_property PACKAGE_PIN R1 [get_ports reverse_gear_shift]
set_property PACKAGE_PIN N4 [get_ports clutch]
set_property PACKAGE_PIN M4 [get_ports brake]
set_property PACKAGE_PIN R2 [get_ports throttle]
set_property IOSTANDARD LVCMOS33 [get_ports reverse_gear_shift]
set_property IOSTANDARD LVCMOS33 [get_ports clutch]
set_property IOSTANDARD LVCMOS33 [get_ports brake]
set_property IOSTANDARD LVCMOS33 [get_ports throttle]

#ouput for test direction
set_property PACKAGE_PIN K1 [get_ports direction_left_light]
set_property PACKAGE_PIN K3 [get_ports direction_right_light]
set_property IOSTANDARD LVCMOS33 [get_ports direction_left_light]
set_property IOSTANDARD LVCMOS33 [get_ports direction_right_light]