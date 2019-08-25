source args.tcl

set SYNTH_ARGS {}
lappend SYNTH_ARGS -flatten_hierarchy rebuilt
lappend SYNTH_ARGS -gated_clock_conversion off
lappend SYNTH_ARGS -bufg { 12 }
lappend SYNTH_ARGS -fanout_limit { 10000 }
lappend SYNTH_ARGS -fsm_extraction auto
lappend SYNTH_ARGS -resource_sharing auto
lappend SYNTH_ARGS -control_set_opt_threshold auto
lappend SYNTH_ARGS -shreg_min_size { 5 }
lappend SYNTH_ARGS -max_bram { -1 }
lappend SYNTH_ARGS -max_dsp { -1 }
lappend SYNTH_ARGS -cascade_dsp auto
lappend SYNTH_ARGS -directive ${SYNTH_DIRECTIVE}
lappend SYNTH_ARGS -top ${TOPLEVEL}
lappend SYNTH_ARGS -part ${PARTNUMBER}

# set SYNTH_ARGS [join ${SYNTH_ARGS} " "]

foreach src ${SOURCES} {
    read_verilog $src
}

foreach constr ${CONSTRAINTS} {
    read_xdc $constr
}

if {${SYNTH_CHECKPOINT} == false && ${PNR_CHECKPOINT} == false} {
    synth_design {*}${QUIET} {*}${SYNTH_ARGS}
    opt_design {*}${QUIET} -directive ${OPT_DIRECTIVE}
    write_checkpoint -force ${PROJECT_NAME}_synth.dcp
} elseif {${SYNTH_CHECKPOINT} != false} {
    open_checkpoint ${SYNTH_CHECKPOINT}
}

if {${PNR_CHECKPOINT} == false} {
    place_design {*}${QUIET} -directive ${PLACE_DIRECTIVE}
    phys_opt_design {*}${QUIET} -directive ${PHYS_DIRECTIVE}
    route_design {*}${QUIET} -directive ${ROUTE_DIRECTIVE}
    write_checkpoint -force ${PROJECT_NAME}_pnr.dcp
} else {
    open_checkpoint ${PNR_CHECKPOINT}
}

report_timing_summary -file ${PROJECT_NAME}.time
write_bitstream -force ${PROJECT_NAME}.bit

# Get the Slack
set WNS [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "Post Route WNS = $WNS"