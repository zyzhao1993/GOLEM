namespace eval ::GOLEM::run:: {
    variable guiMode 
    
#defined from ::GOLEM::gui
    variable outDir
    variable namdBin
    variable namdOpt
    variable receptorPSF
    variable receptorPDB
    variable keepCrystalWater
    variable optimizeCrystalWaterOrientation 
    variable oriMap 
    variable bindingsiteStr
    variable parFileList
    variable waterMaxNum
    variable ligandCoupFactor
    variable waterCoupFactor
    variable fixedSidechain
    variable ligandPSF
    variable ligandPDB
    variable siteMinX
    variable siteMinY
    variable siteMinZ
    variable siteMaxX
    variable siteMaxY
    variable siteMaxZ

#calculated from ::GOLEM::gui
    variable bindingsiteCenter
    variable disMaxX
    variable disMaxY
    variable disMaxZ

    variable ligandPot
    variable receptorPot

#optional inputs
    variable cutoffDis
    variable ligandSimMaxRound
    variable ligandSimTerminateRound; #termnate after no new conformations in X rounds 
    variable ligandRMSDCutoff;
    variable imdPort
    variable socketPort

#internal:ligand
    variable systemPSF
    variable systemPDB
    variable ligandSimIMDMol
    variable ligandSimMol
    variable ligandSimSel1
    variable ligandSimSel2
    variable fragmentSimSelList1
    variable fragmentSimSelList2
    variable lastAddedFrame 
    variable namdSocket
    variable rotamers
#internal:GA
    variable popMax
    variable subPopNum
    variable subPopSize; #subPopNum*subOpoSize=popMax
    variable eliteMax
    variable nicheCapacity
    variable nicheExpand
    variable roundMax
    variable waterMapCali
    variable minStep
    variable sidechainCoupFactor
    variable crossoverRate
    variable mutateRate
    variable immigrantRate
    variable minorGeneMutateRate
    variable eliteRoughRMSDCutoff
    variable eliteFineRMSDCutoff
    variable continuousMin
    variable ligandSelStr
}

proc ::GOLEM::run::run {} {
    variable M_PI 3.1415626
    if {![info exists ::GOLEM::gui::readyToRun] || $::GOLEM::gui::readyToRun==0} {
#not ready to run, do nothing
	return 
    }
#save gui status
    catch {::GOLEM::gui::save_gui_script_core $::GOLEM::gui::outDir/run.tcl}
    foreach id [molinfo list] {mol off $id}
#initialize variables
    puts "::GOLEM::run::init"
    ::GOLEM::run::init
    variable guiMode
    if {$guiMode} {
	$::GOLEM::gui::w.console.output delete 0 end
    }
    puts "::GOLEM::run::init done"
#keep or remove water in bindingsite from the receptor pdb based on keepCrystalWater; make sure receptor psf/pdb has no GW chain
#generate psf/pdb of the system (ligand+receptor+water)
    ::GOLEM::run::generate_system
    puts "::GOLEM::run::generate_system done"
#generate mdff maps
    ::GOLEM::run::generate_maps
    variable rotamers
    variable ligandPSF
    variable ligandPDB
    variable parFileList
    variable ligandDCD
    variable ligandAtomNum 
    variable ligandNoHAtomNum
    set tmp [mol new $ligandPSF]
    set ligandAtomNum [[atomselect $tmp all] num]
    set ligandNoHAtomNum [[atomselect $tmp "all and noh"] num]
    mol delete $tmp
    set rotamers [::GOLEM::run::find_rotamer $ligandPSF $ligandPDB "all"]
#no more rotamers; use segments; split ligandPSF/PDB into list of segmentPSF/PDB
#processed before calling ::GOLEM::run::GA
    if {[info exists ::GOLEM::gui::ligandDCD]} {
	if {![file exists $::GOLEM::gui::ligandDCD] || ![file isfile $::GOLEM::gui::ligandDCD] || [file extension $::GOLEM::gui::ligandDCD]!=".dcd"} {
	    ::GOLEM::run::generate_ligand_dcd
	    #once ligandDCD is generated, start GA
	    trace add variable ligandDCD write ::GOLEM::run::wait_ligand_sim
	} else {
#using segments, no need to align ligand dcd; each segment will be aligned independently
	    ::GOLEM::run::align_ligand_dcd
	    ::GOLEM::run::segmentalize
	    ::GOLEM::run::GA
	}
    } else {
	::GOLEM::run::generate_ligand_dcd
	trace add variable ligandDCD write ::GOLEM::run::wait_ligand_sim
    }
}

proc ::GOLEM::run::wait_ligand_sim {varname args} {
    variable ligandDCD
    if {[file exists $ligandDCD] && [file isfile $ligandDCD]} {
	puts "starting GA"
	foreach t [trace info variable ligandDCD] {
	    trace remove variable ligandDCD [lindex $t 0] [lindex $t 1]
	}
	::GOLEM::run::align_ligand_dcd
	::GOLEM::run::segmentalize
	::GOLEM::run::GA
    }
}

proc ::GOLEM::run::init {} {
#clear all atomselection vars
    foreach v [info vars ::GOLEM::run::*Sel*] {
	if {[info exists $v]} {
	    unset $v
	}
    }
    variable guiMode 
    variable outDir
    variable namdBin
    variable namdOpt
    variable receptorPSF
    variable receptorPDB
    variable keepCrystalWater
    variable optimizeCrystalWaterOrientation 
    variable oriMap 
    variable bindingsiteStr
    variable parFileList
    variable waterMaxNum
    variable ligandCoupFactor
    variable waterCoupFactor
    variable fixedSidechain
    variable ligandPSF
    variable ligandPDB
    variable ligandDCD
    variable siteMinX
    variable siteMinY
    variable siteMinZ
    variable siteMaxX
    variable siteMaxY
    variable siteMaxZ

    variable bindingsiteCenter
    variable disMaxX
    variable disMaxY
    variable disMaxZ

    variable cutoffDis
    variable ligandSimMaxRound
    variable ligandSimTerminateRound; #termnate after no new conformations in X rounds 
    variable ligandRMSDCutoff
    variable imdPort
    variable socketPort

    global tk_version
    if { [info exists tk_version] } {
	set guiMode 1
    } else {
	set guiMode 0
    }
    puts [info exists tk_version]
    puts $guiMode

    set varListFromGui {outDir namdBin namdOpt receptorPSF receptorPDB keepCrystalWater optimizeCrystalWaterOrientation oriMap parFileList waterMaxNum ligandCoupFactor waterCoupFactor fixedSidechain ligandPSF ligandPDB siteMinX siteMinY siteMinZ siteMaxX siteMaxY siteMaxZ}
    foreach var $varListFromGui {
	set $var [subst $[subst ::GOLEM::gui::$var]]
    }
    if {![info exists ::GOLEM::gui::bindingsiteStr]} {
	set bindingsiteStr "sidechain and same residue as (x>$siteMinX and x<$siteMaxX and y>$siteMinY and y<$siteMaxY and z>$siteMinZ and z<$siteMaxZ)"
    }

    if {![file exists $outDir]} {file mkdir $outDir}
    cd $outDir
    if {![file exists $outDir/prepare]} {file mkdir $outDir/prepare}
    if {![file exists $outDir/prepare/segments]} {file mkdir $outDir/prepare/segments}
    if {![file exists $outDir/run]} {file mkdir $outDir/run}

    if {![info exists namdOpt]} {set namdOpt " "}

    set bindingsiteCenter [list [expr ($::GOLEM::gui::siteMinX+$::GOLEM::gui::siteMaxX)/2.0] [expr ($::GOLEM::gui::siteMinY+$::GOLEM::gui::siteMaxY)/2.0] [expr ($::GOLEM::gui::siteMinZ+$::GOLEM::gui::siteMaxZ)/2.0]]
    set disMaxX [expr ($::GOLEM::gui::siteMaxX-$::GOLEM::gui::siteMinX)/2.0]
    set disMaxY [expr ($::GOLEM::gui::siteMaxY-$::GOLEM::gui::siteMinY)/2.0]
    set disMaxZ [expr ($::GOLEM::gui::siteMaxZ-$::GOLEM::gui::siteMinZ)/2.0]
    if {[info exists ::GOLEM::gui::ligandDCD]} {
	set ligandDCD $::GOLEM::gui::ligandDCD
    } else {
	set ligandDCD ""
    }
    if {![info exists cutoffDis]} {set cutoffDis 12}
    if {![info exists ligandSimMaxRound]} {set ligandSimMaxRound 100}
    if {![info exists ligandSimTerminateRound]} {set ligandSimTerminateRound 10}
    if {![info exists ligandRMSDCutoff]} {set ligandRMSDCutoff 1.5}
    if {![info exists imdPort]} {
	set imdPort 3000
	while {[catch {set tmp [socket -server connect $imdPort]}]} {
	    incr imdPort
	    if {$imdPort>9999} {break}
	}
	close $tmp
    }
    if {![info exists socketPort]} {
	set socketPort [expr int(1+$imdPort)]
	while {[catch {set tmp [socket -server connect $socketPort]}]} {
	    incr socketPort
	    if {$socketPort>9999} {break}
	}
	close $tmp
    }

}

proc ::GOLEM::run::generate_system {} {
    variable outDir
    variable guiMode
    variable ligandPSF
    variable ligandPDB
    variable receptorPSF
    variable receptorPDB
    variable keepCrystalWater
    variable siteMinX
    variable siteMinY
    variable siteMinZ
    variable siteMaxX
    variable siteMaxY
    variable siteMaxZ
    variable cutoffDis
    variable waterMaxNum
    variable bindingsiteCenter
    variable systemPSF
    variable systemPDB

    if {$guiMode} {::GOLEM::gui::update_status_text "preparing system psf/pdb"}

    #check if there is a GW or LIG segment in receptor, if so, change it
    puts "checking GW or LIG segment"
    set tmpRecMol [mol load psf $receptorPSF pdb $receptorPDB]
    set tmpGWSel [atomselect $tmpRecMol "segname GW"]
    if {[$tmpGWSel num]>0} {
	set safeName -1
	for {set i 65} {$i<91} {incr i} {
	    for {set j 65} {$j<91} {incr j} {
		for {set k 65} {$k<91} {incr k} {
		    set name [format %c%c%c $k $j $i]
		    if {$name=="GW" || $name=="LIG"} {continue}
		    set tmpSel [atomselect $tmpRecMol "segname $name"]
		    if {[$tmpSel num]==0} {
			set safeNmae $name
			$tmpSel delete
			break
		    }
		    $tmpSel delete
		}
	    }
	}
	if {$safeName==-1} {
	    tk_messageBox -icon error -message "How can I can't find a novel segname?"
	} else {
	    $tmpGWSel set segname $safeName
	}
	set tmpAllSel [atomselect $tmpRecMol all]
	$tmpAllSel writepsf $outDir/prepare/receptor-GWrenamed.psf
	$tmpAllSel writepdb $outDir/prepare/receptor-GWrenamed.pdb
	set receptorPSF $outDir/prepare/receptor-GWrenamed.psf
	set receptorPDB $outDir/prepare/receptor-GWrenamed.pdb
    }
    $tmpGWSel delete
    puts "done GW"

    set tmpRecMol2 [mol load psf $receptorPSF pdb $receptorPDB]
    set tmpLIGSel [atomselect $tmpRecMol2 "segname LIG"]
    if {[$tmpLIGSel num]>0} {
	set safeName -1
	for {set i 65} {$i<91} {incr i} {
	    for {set j 65} {$j<91} {incr j} {
		for {set k 65} {$k<91} {incr k} {
		    set name [format %c%c%c $k $j $i]
		    if {$name=="GW" || $name=="LIG"} {continue}
		    set tmpSel [atomselect $tmpRecMol2 "segname $name"]
		    if {[$tmpSel num]==0} {
			set safeNmae $name
			$tmpSel delete
			break
		    }
		    $tmpSel delete
		}
	    }
	}
	if {$safeName==-1} {
	    tk_messageBox -icon error -message "How can I can't find a novel segname?"
	} else {
	    $tmpLIGSel set segname $safeName
	}
	set tmpAllSel [atomselect $tmpRecMol2 all]
	$tmpAllSel writepsf $outDir/prepare/receptor-LIGrenamed.psf
	$tmpAllSel writepdb $outDir/prepare/receptor-LIGrenamed.pdb
	set receptorPSF $outDir/prepare/receptor-LIGrenamed.psf
	set receptorPDB $outDir/prepare/receptor-LIGrenamed.pdb
    }
    puts "done LIG"
    $tmpLIGSel delete

    #remove water in the bindingsite if keepCrystalWater==0
    #always remove water outside the bindingsite
    set tmpRecMol3 [mol load psf $receptorPSF pdb $receptorPDB]
    #set keepSel [atomselect $tmpRecMol3 "all and not same residue as water and (x>$siteMinX and x<$siteMaxX and y>$siteMinY and y<$siteMaxY and z>$siteMinZ and z<$siteMaxZ)"]
    if {$keepCrystalWater==0} {
	set watDelSel [atomselect $tmpRecMol3 "name OH2 and same residue as water"]
    } else {
	set watDelSel [atomselect $tmpRecMol3 "name OH2 and same residue as water and not (x>$siteMinX and x<$siteMaxX and y>$siteMinY and y<$siteMaxY and z>$siteMinZ and z<$siteMaxZ)"]
    }
    puts "safe here"
    if {[$watDelSel num]>0} {
	psfcontext reset
	resetpsf 
	set golemcontext [psfcontext new]
	psfcontext eval $golemcontext {
	    readpsf $receptorPSF
	    coordpdb $receptorPDB
	    foreach segid [$watDelSel get segid] resid [$watDelSel get resid] {
		delatom $segid $resid
	    }
	    writepsf $outDir/prepare/receptor-waterdeleted.psf
	    writepdb $outDir/prepare/receptor-waterdeleted.pdb
	}
	psfcontext delete $golemcontext
	set receptorPSF $outDir/prepare/receptor-waterdeleted.psf
	set receptorPDB $outDir/prepare/receptor-waterdeleted.pdb
    }
    puts "safe here2"
    $watDelSel delete

    mol delete $tmpRecMol
    mol delete $tmpRecMol2
    mol delete $tmpRecMol3

    variable fullReceptorPSF $receptorPSF
    variable fullReceptorPDB $receptorPDB

    #cut out the bindingsite (extended by $cutoffDis/2)
    set minx [expr $siteMinX-$cutoffDis/2]
    set miny [expr $siteMinY-$cutoffDis/2]
    set minz [expr $siteMinZ-$cutoffDis/2]
    set maxx [expr $siteMaxX+$cutoffDis/2]
    set maxy [expr $siteMaxY+$cutoffDis/2]
    set maxz [expr $siteMaxZ+$cutoffDis/2]
    set tmpRecMol [mol new $receptorPSF]
    mol addfile $receptorPDB waitfor all $tmpRecMol
    set sel [atomselect $tmpRecMol "same residue as (x>$minx and x<$maxx and y>$miny and y<$maxy and z>$minz and z<$maxz)"]
    $sel writepsf $outDir/prepare/receptor-site.psf
    $sel writepdb $outDir/prepare/receptor-site.pdb
    set receptorPSF $outDir/prepare/receptor-site.psf
    set receptorPDB $outDir/prepare/receptor-site.pdb
    $sel delete 
    mol delete $tmpRecMol

    #build system
    global env
    psfcontext reset
    resetpsf
    set golemcontext [psfcontext new]
    psfcontext eval $golemcontext {
	topology $env(CHARMMTOPDIR)/toppar_water_ions_namd.str
	readpsf $ligandPSF
	coordpdb $ligandPDB
	readpsf $receptorPSF
	coordpdb $receptorPDB
	segment GW {
	    for {set i 0} {$i<$waterMaxNum} {incr i} {
		residue $i TIP3
	    }
	}
	for {set i 0} {$i<$waterMaxNum} {incr i} {
#water model psfgen used is different from TIP3P in charmm, so need to set its coordinates mannually
#OH bond 0.9572A, HOH angle 104.52
	   psfset coord GW $i OH2 $bindingsiteCenter
	   psfset coord GW $i H1 [vecadd $bindingsiteCenter {0 0 0.9572}]
	   psfset coord GW $i H2 [vecadd $bindingsiteCenter {0 0.9266272 -0.2399872}]
	}
	guesscoord 
	writepsf $outDir/prepare/system.psf
	writepdb $outDir/prepare/system.pdb
	set  systemPSF $outDir/prepare/system.psf
	set  systemPDB $outDir/prepare/system.pdb
    }
}

proc ::GOLEM::run::generate_maps {} {
    variable siteMinX
    variable siteMinY
    variable siteMinZ
    variable siteMaxX
    variable siteMaxY
    variable siteMaxZ
    variable receptorPSF
    variable receptorPDB
    variable cutoffDis
    variable oriMap
    variable outDir
    variable ligandPot
    variable receptorPot
    variable guiMode
    variable mapThreshold
    if {![info exists mapThreshold]} {set mapThreshold 0}

    if {$guiMode} {::GOLEM::gui::update_status_text "preparing map files"}
    set minx [expr $siteMinX-$cutoffDis]
    set miny [expr $siteMinY-$cutoffDis]
    set minz [expr $siteMinZ-$cutoffDis]
    set maxx [expr $siteMaxX+$cutoffDis]
    set maxy [expr $siteMaxY+$cutoffDis]
    set maxz [expr $siteMaxZ+$cutoffDis]
    volutil -crop $minx $miny $minz $maxx $maxy $maxz $oriMap -o $outDir/prepare/crop.dx
    mdff griddx -i $outDir/prepare/crop.dx -threshold $mapThreshold -o $outDir/prepare/mdff-for-receptor.dx
    set receptorPot $outDir/prepare/mdff-for-receptor.dx
    voltool smult -amt "-1" -i $outDir/prepare/mdff-for-receptor.dx -o $outDir/prepare/mdff-for-receptor-negative.dx
    mol delete top
    voltool sadd -amt "1" -i $outDir/prepare/mdff-for-receptor-negative.dx -o $outDir/prepare/mdff-for-receptor-reverse.dx
    mol delete top
    set tmpMapMol [mol new $outDir/prepare/crop.dx]
    set tmpRecMol [mol new $receptorPSF]
    mol addfile $receptorPDB waitfor all $tmpRecMol
    volmap mask [atomselect $tmpRecMol "all and noh"] -cutoff 1.5 -mol $tmpRecMol -o $outDir/prepare/mask.dx
    voltool smult -amt "-1" -i $outDir/prepare/mask.dx -o $outDir/prepare/mask-negative.dx
    mol delete top
    voltool sadd -amt "1" -i $outDir/prepare/mask-negative.dx -o $outDir/prepare/mask-reverse.dx
    mol delete top
    voltool mult -i1 $outDir/prepare/mask-reverse.dx -i2 $outDir/prepare/mdff-for-receptor-reverse.dx -o  $outDir/prepare/mdff-for-receptor-reverse-noreceptor.dx
    mol delete top
    mol delete top
    volutil -crop $siteMinX $siteMinY $siteMinZ $siteMaxX $siteMaxY $siteMaxZ $outDir/prepare/mdff-for-receptor-reverse-noreceptor.dx -o $outDir/prepare/site-noreceptor.dx
    mol delete top
    mdff griddx -i $outDir/prepare/site-noreceptor.dx -o $outDir/prepare/mdff-for-ligand.dx
    set ligandPot $outDir/prepare/mdff-for-ligand.dx
    mol delete $tmpMapMol
    mol delete $tmpRecMol
}

proc ::GOLEM::run::generate_ligand_dcd {} {
    variable outDir
    file mkdir $outDir/prepare/ligand
    file mkdir $outDir/prepare/ligand/output
    variable guiMode
    if {$guiMode} {::GOLEM::gui::update_status_text "sampling ligand conformation"}
    ::GOLEM::run::write_ligand_conf
    ::GOLEM::run::run_ligand_conf
}

proc ::GOLEM::run::write_ligand_conf {} {
    variable outDir
    variable ligandPSF
    variable ligandPDB
    variable parFileList
    variable ligandSimMaxRound
    variable ligandSimTerminateRound
    variable imdPort
    variable socketPort

    set out [open $outDir/prepare/ligand/ligand.conf w]
    puts $out "structure	$ligandPSF"
    puts $out "coordinates	$ligandPDB"
    puts $out "outputName	$outDir/prepare/ligand/output"
    puts $out "set temperature	300"
    puts $out "paraTypeCharmm	on"
    foreach parFile $parFileList {
	puts $out "parameters	$parFile"
    }
    puts $out "exclude		    scaled1-4"
    puts $out "switching	    on"
    puts $out "vdwForceSwitching    on"
    puts $out "GBIS		    on"
    puts $out "ionConcentration	    0.3"
    puts $out "alphaCutoff	    12"
    puts $out "switchdist	    10."
    puts $out "cutoff		    14"
    puts $out "pairlistdist	    15.5"
    puts $out "timestep		    1"
    puts $out "langevin		    on"
    puts $out "langevinDamping	    5"
    puts $out "langevinTemp	    \$temperature"
    puts $out "langevinHydrogen	    off"
    puts $out "restartFreq	    10500"
    puts $out "dcdFreq		    10500"
    puts $out "xstFreq		    10500"
    puts $out "outputEnergies	    10500"
    puts $out "outputPressure	    10500"
    puts $out "temperature	    \$temperature"
    puts $out "IMDon		    yes"
    puts $out "IMDport		    $imdPort"
    puts $out "IMDfreq		    500"
    puts $out "IMDwait		    yes"
    puts $out "IMDignore	    no"
    puts $out "set  ::realS -1"
    puts $out "proc accept {chan addr port} {"
    puts $out "	set ::realS \$chan"
    puts $out "}"
    puts $out "socket -server accept $socketPort"
    puts $out "vwait ::realS"
    puts $out "reassignFreq	    500"
    puts $out "reassignTemp	    300"
    puts $out "minimize		    500"
    puts $out "for {set x 0} {\$x<$ligandSimMaxRound} {incr x} {"
    puts $out "	file mkdir $outDir/prepare/ligand/output/\$x"
    puts $out "	for {set TEMP 300} {\$TEMP<=450} {incr TEMP 50} {"
    puts $out "	    run 500"
    puts $out "	    reassignTemp \$TEMP"
    puts $out "	    langevinTemp \$TEMP"
    puts $out "	}"
    puts $out "	run 2000"
    puts $out "	for {set TEMP 400} {\$TEMP>=300} {incr TEMP -50} {"
    puts $out "	    reassignTemp \$TEMP"
    puts $out "	    langevinTemp \$TEMP"
    puts $out "	    run 500"
    puts $out "	}"
    puts $out "	run 500"
    puts $out "	minimize 500"
    puts $out "	output $outDir/prepare/ligand/output/\$x/\$x"
    puts $out "	puts \$::realS \$x"
    puts $out "	flush \$::realS"
    puts $out "}"
    puts $out "puts \$::realS -1"
    puts $out "flush \$::realS"
    puts $out "close \$::realS"
    flush $out
    close $out
}

proc ::GOLEM::run::run_ligand_conf {} {
    variable namdBin
    variable namdOpt
    variable outDir
    variable ligandPSF
    variable ligandPDB
    variable imdPort
    variable socketPort
    variable ligandSimIMDMol
    variable namdSocket
    variable ligandDCD
    if {[file exists $outDir/prepare/ligand/ligand.out]} {file delete $outDir/prepare/ligand/ligand.out}
#namdOpt temperarally removed
    if {[catch {::ExecTool::exec $namdBin $outDir/prepare/ligand/ligand.conf > $outDir/prepare/ligand/ligand.out &}] } {
	puts "error running NAMD"
	variable guiMode
	if {!$guiMode} {exit}
	return 1
    }
    puts "NAMD initiated"
    set ligandSimIMDMol [mol new $ligandPSF]
    mol addfile $ligandPDB  waitfor all $ligandSimIMDMol
    puts "imd mol loaded"
#namd may take a while to start, so wait for it
    while {[catch {set namdSocket [socket localhost $socketPort]}]!=0} {
	puts "connecting to NAMD"
	after 500
    }
    puts "socket connected"
    fconfigure $namdSocket -blocking 0
    fileevent $namdSocket readable [list ::GOLEM::run::get_socket_chan_ligand_sim $namdSocket]
    while {[catch {imd connect localhost $imdPort}]!=0} {
	puts "connecting to NAMD at $imdPort"
	after 500
    }
    puts "IMD connected"

    #vwait ligandDCD; #when ligandSim is done, ligandDCD is assigned; wait untill ligandDCD is assigned

    return 0
}

proc ::GOLEM::run::get_socket_chan_ligand_sim {chan} {
    set l [gets $chan]
    if {$l==-1} {
	::GOLEM::run::stop_ligand_sim
	return
    } else {
	::GOLEM::run::ligand_sim_load_conf $l
    }
}

proc ::GOLEM::run::ligand_sim_load_conf {frame} {
    variable ligandSimMol
    variable ligandPSF
    variable outDir
    variable ligandSimSel1
    variable ligandSimSel2
    variable ligandRMSDCutoff
    variable lastAddedFrame
    variable ligandSimTerminateRound
    puts $frame
    if {![info exists ligandSimMol]} {
	puts "loading ligand psf"
	set ligandSimMol [mol new $ligandPSF waitfor all]
	mol off $ligandSimMol
    }
    if {![info exists ligandSimSel1]} {
	puts "set sel1"
	set ligandSimSel1 [atomselect $ligandSimMol all]
	$ligandSimSel1 global
    }
    if {![info exists ligandSimSel2]} {
	puts "set sel2"
	set ligandSimSel2 [atomselect $ligandSimMol all]
	$ligandSimSel2 global
    }
    mol addfile $outDir/prepare/ligand/output/$frame/$frame.coor waitfor all $ligandSimMol
    if {$frame==0} {
	set lastAddedFrame 0
	return
    } else {
	set keepFlag 1
	set totFrame [molinfo $ligandSimMol get numframes]
	$ligandSimSel1 frame [expr int($totFrame-1)]
	for {set f 0} {$f<[expr int($totFrame-1)]} {incr f} {
	    $ligandSimSel2 frame $f
	    $ligandSimSel1 move [measure fit $ligandSimSel1 $ligandSimSel2 ]
	    set rmsd [measure rmsd $ligandSimSel1 $ligandSimSel2 ]
	    if {$rmsd<$ligandRMSDCutoff} {
		set keepFlag 0
		break
	    }
	}
	if {$keepFlag} {
	    set lastAddedFrame $frame
	} else {
	    animate delete beg [expr int($totFrame-1)] $ligandSimMol
	}
    }
    if {[expr $frame-$lastAddedFrame]>=$ligandSimTerminateRound} {
	::GOLEM::run::stop_ligand_sim
	return
    }
    return
}

proc ::GOLEM::run::stop_ligand_sim {} {
    variable ligandSimMol
    variable ligandSimSel1
    variable ligandSimSel2
    variable namdSocket
    variable outDir
    variable ligandDCD
    catch {close $namdSocket}
    catch {imd kill}
    $ligandSimSel1 frame 0
    $ligandSimSel1 moveby [vecscale [measure center $ligandSimSel1 ] -1]
    for {set f 1} {$f<[molinfo $ligandSimMol get numframes]} {incr f} {
	$ligandSimSel2 frame $f
	$ligandSimSel2 move [measure fit $ligandSimSel2 $ligandSimSel1 ]
	$ligandSimSel2 moveby [vecscale [measure center $ligandSimSel2 ] -1]
    }
    animate write dcd  $outDir/prepare/ligand.dcd waitfor all $ligandSimMol
    set ligandDCD $outDir/prepare/ligand.dcd
    catch {$ligandSimSel1 delete}
    catch {$ligandSimSel2 delete}
    mol delete $ligandSimMol
}

proc ::GOLEM::run::align_ligand_dcd {} {
    variable ligandDCD
    variable outDir
    if {$ligandDCD=="$outDir/prepare/ligand.dcd"} {return}
    variable ligandPSF
    set tmpMol [mol new $ligandPSF]
    mol addfile $ligandDCD waitfor all $tmpMol
    set ligandSel1 [atomselect $tmpMol all]
    set ligandSel2 [atomselect $tmpMol all]
    $ligandSel1 frame 0
    $ligandSel1 moveby [vecscale [measure center $ligandSel1] -1]
    for {set f 1} {$f<[molinfo $tmpMol get numframes]} {incr f} {
	$ligandSel2 frame $f
	$ligandSel2 move [measure fit $ligandSel2 $ligandSel1 ]
	$ligandSel2 moveby [vecscale [measure center $ligandSel2 ] -1]
    }
    animate write dcd $outDir/prepare/ligand.dcd waitfor all $tmpMol
    set ligandDCD $outDir/prepare/ligand.dcd
    catch {$ligandSel1 delete}
    catch {$ligandSel2 delete}
    mol delete $tmpMol
}

proc ::GOLEM::run::segmentalize {} {
    variable ligandDCD
    variable outDir 
    variable ligandPSF
    variable ligandPDB
    variable segmentIndexList
    variable segmentPSFList
    variable segmentPDBList
    variable segmentDCDList
    set segmentPSFList [list]
    set segmentPDBList [list]
    set segmentDCDList [list]

    set segmentIndexList [::GOLEM::run::split_all_rotamer $ligandPSF $ligandPDB "all"]
    if {[llength $segmentIndexList]==1} {set segmentIndexList {}};#no need to use segmets when there is only one segment
#generate psf/pdb for each segment
    variable rotamers
    set portIndexAll [list]
    foreach rotamer $rotamers {
	lappend portIndexAll [lrange [lindex $rotamer 0] 1 2]
    }
    set portIndexAll [concat {*}$portIndexAll]
    set portIndexAll [lsort -unique $portIndexAll]
    puts $portIndexAll
    variable portIndexList [list]
    foreach segmentIndex $segmentIndexList {
	set tmp [list]
	foreach ID $segmentIndex {
	    if {[lsearch $portIndexAll $ID]!=-1} {
		lappend tmp $ID
	    }
	}
	set tmp [lsort -unique $tmp]
	lappend portIndexList $tmp
    }

    set tmpMol [mol new $ligandPSF]
    mol addfile $ligandPDB waitfor all $tmpMol

    variable portNameList [list]
    foreach portIndex $portIndexList {
	set sel [atomselect $tmpMol "index $portIndex"]
	lappend portNameList [$sel get name]
    }

    set ID 0
    foreach segmentIndex $segmentIndexList {
	set tmpSegMolSel [atomselect $tmpMol "index $segmentIndex"]
	$tmpSegMolSel writepsf $outDir/prepare/segments/segment$ID.psf
	$tmpSegMolSel writepdb $outDir/prepare/segments/segment$ID.pdb
	lappend segmentPSFList $outDir/prepare/segments/segment$ID.psf
	lappend segmentPDBList $outDir/prepare/segments/segment$ID.pdb
	catch {$tmpSegMolSel delete}
	set ID [expr $ID+1]
    }
#generate dcd for each segment, duplicated segment conformations are removed
    animate delete all $tmpMol
    mol addfile $ligandDCD waitfor all $tmpMol
    set ID 0
    foreach segmentIndex $segmentIndexList portName $portNameList segmentPSF $segmentPSFList segmentPDB $segmentPDBList {
	set tmpSegMol [mol new $segmentPSF]
	mol addfile $segmentPDB $tmpSegMol
#set and center first frame of  segment; 
	set tmpMolSegSel [atomselect $tmpMol "index $segmentIndex" frame 0]; #this sel go through tmpMol to get cor
	set cor [$tmpMolSegSel get {x y z}]; list
	set tmpSegMolRefSel [atomselect $tmpSegMol all frame 0]; #this sel doesn't move; for alignment only
	$tmpSegMolRefSel set {x y z} $cor
	$tmpSegMolRefSel moveby [vecscale [measure center $tmpSegMolRefSel] -1]
	set refCor [$tmpSegMolRefSel get {x y z}]; list

	set tmpSegMolPortRefSel [atomselect $tmpSegMol "name $portName" frame 0]
	set portRefCor [$tmpSegMolPortRefSel get {x y z}]; list

	set tmpSegMolSel [atomselect $tmpSegMol all]; #this sel goes to last frame of tmpSegMol to set cor
	set tmpSegMolCompareSel [atomselect $tmpSegMol all]; #this sel goes through tmpMol to compare RMSD with tmpSegMolSel(last frame, newly added)
	set tmpSegMolPortSel [atomselect $tmpSegMol "name $portName"]

	for {set ligandDCDFrame 0} {$ligandDCDFrame<[molinfo $tmpMol get numframes]} {incr ligandDCDFrame} {
	    $tmpMolSegSel frame $ligandDCDFrame
	    set cor [$tmpMolSegSel get {x y z}]; list
	    animate dup frame 0 $tmpSegMol
	    $tmpSegMolSel frame last
	    $tmpSegMolSel set {x y z} $cor

	    if {[llength $segmentIndex]==3} {
		set mat [::GOLEM::run::three_atoms_align $cor $refCor]
		#set mat [::GOLEM::run::three_atoms_align [$tmpSegMolSel get {x y z}] [$tmpSegMolRefSel get {x y z}]]
		#set mat [measure fit $tmpSegMolSel $tmpSegMolRefSel]
	    } else {
		set mat [measure fit $tmpSegMolSel $tmpSegMolRefSel]
	    }
	    $tmpSegMolSel move $mat

	    $tmpSegMolPortSel frame last
	    set portCor [$tmpSegMolPortSel get {x y z}];list
	    if {[$tmpSegMolPortSel num]==3} {
		set mat [::GOLEM::run::three_atoms_align $portCor $refCor]
	    } else {
		set mat [measure fit $tmpSegMolPortSel $tmpSegMolPortRefSel]
	    }
	    $tmpSegMolSel move $mat

	    set keep 1
	    for {set tmpSegMolFrame 0} {$tmpSegMolFrame<[expr [molinfo $tmpSegMol get numframes]-1]} {incr tmpSegMolFrame} {
		$tmpSegMolCompareSel frame $tmpSegMolFrame
		set RMSD [measure rmsd $tmpSegMolCompareSel $tmpSegMolSel]
		if {$RMSD<0.5} {
		    set keep 0
		    break
		}
	    }
	    if {$keep==0} {
		animate delete beg [expr [molinfo $tmpSegMol get numframes]-1] $tmpSegMol
	    }
	}
	animate write dcd $outDir/prepare/segments/segment$ID.dcd  waitfor all $tmpSegMol
	lappend segmentDCDList $outDir/prepare/segments/segment$ID.dcd
	set ID [expr $ID+1]
    }
}
