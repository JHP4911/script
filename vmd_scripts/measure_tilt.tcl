
#########################################################
#                                                       #
#       Measure the overall tilt of the protein 	#
#       relative to the z-axis                          #
#							#
#       Sophie Rennison                                 #
#       & Maria Musgaard                                #
#       SBCB, Oxford                                    #
#       Oct 2016                                        #
#                                                       #
#########################################################

# run with vmd -dispdev text -e /biggin/b119/trin2600/Documents/scripts/measure_STZ_overall_tilt.tcl -args npt_2.gro md_concat_stride_noPBC.xtc 2 10000 Zhao4_loop_MUT_STZ_overall_tilt

set numargs [llength $argv]
if { $numargs == 5 } {
        # Things should be fine
} else {
        puts "*******************************************************************"
        puts "Some arguments seem to be missing"
        puts "run as: vmd -dispdev text -e measure_STZ_overall_tilt.tcl -args groname xtcfile timestep frfreq outname"
        puts "*******************************************************************"
        exit
}

set ingro [lindex $argv 0]

set xtcfile [lindex $argv 1]

# To get the right time
set tstep [lindex $argv 2]
set frfreq [lindex $argv 3]
set outname [lindex $argv 4]

set out [open ${outname}.dat w]

puts $out "# Overall protein tilt relative to z-axis in STZ simulations"
puts $out "# The file is generated by measure_STZ_overall_tilt.tcl"
puts $out "# [clock format [clock seconds]]"
puts $out "# grofile: $ingro, xtcfile: $xtcfile, tstep: $tstep, frfreq: $frfreq "
#####  Print header  #####
puts -nonewline $out "# Time \t Tilt"
puts $out ""; flush $out


# Use bigdcd during analysis 
source /sansom/s91/bioc1127/gp130/SCRIPTS/TCL/bigdcd.tcl

# Load system
mol new $ingro


# Vector along membrane normal
# We assume that the principal axis remains along the z-axis
set memnorm {0 0 -1}

set pi [expr 4.0*atan(1.0)]
#Output angles are converted to degrees
set todeg [expr 180/$pi]

proc tilt { frame }  {

        #Global parameters
        global memnorm pi todeg
        global tstep frfreq out 

	#Follow progress in terminal
	puts "frame $frame"
        #calculates the time in ns
        set time [expr $frame*$tstep*$frfreq*1E-6]
        puts -nonewline $out "$time \t"

	# Find overall tilt
	# Define the cytoplasmic end and the extracellular end of the protein
	set cytEnd [atomselect top "name C and resid 25 to 28"]
	set extEnd [atomselect top "name C and resid 10 to 13"]
        set min [measure center $extEnd weight mass]
        set max [measure center $cytEnd weight mass]
        set axis [vecsub $max $min]
        #calculate the tilt angle
        set ang [expr acos([vecdot $axis $memnorm]/[veclength $axis])*$todeg]   
        if { $ang > 90 } {
		set ang_coor [expr 180 - $ang ]
                puts -nonewline $out "$ang_coor \t"
     	} else {
        	puts -nonewline $out "$ang \t"
       	}
        $extEnd delete
        $cytEnd delete
	puts $out ""; flush $out
}


bigdcd tilt xtc $xtcfile 
bigdcd_wait

close $out

return
exit

