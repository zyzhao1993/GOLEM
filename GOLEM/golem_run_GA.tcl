proc ::GOLEM::run::GA {} {
    variable round 
    variable guiMode
    set statusText "preparing genetic algorithm paramters"
    if {$guiMode} {
	::GOLEM::gui::update_status_text $statusText
    } else { 
	puts $statusText
    }
    ::GOLEM::run::GA_prepare
    variable finalPhase 0
    variable debug
    variable time [clock clicks -millisecond]
    set statusText "preparing NAMD parameters"
    if {$guiMode} {
	::GOLEM::gui::update_status_text $statusText
    } else {
	puts $statusText
    }
    ::GOLEM::run::prepare_namd_conf
    set statusText "preparing NAMD parameters"
    if {$guiMode} {
	::GOLEM::gui::update_status_text $statusText
    } else {
	puts $statusText
    }
    if {[::GOLEM::run::init_NAMD]!=0} {
	set statusText "Failed to run NAMD"
    	if {$guiMode} {
    	    ::GOLEM::gui::update_status_text $statusText
    	} else { 
    	    puts $statusText
    	}
	return
    }
    variable GAOutDir
    variable MDFFOut
    variable totalEnergyOut
    #variable waterCaliOut
    variable scoreOriOut
    variable sortOut
    variable bestOut
    variable bestDistinctScoreAll [list]
    variable bestDistinctScoreAllMDFF [list]
    variable bestDistinctScoreAllEnergy [list]
    variable bestDistinctScoreAllWaterCali [list]
    set MDFFOut [open $GAOutDir/mdff.log w]
    set totalEnergyOut [open $GAOutDir/totalEnergy.log w]
    #set waterCaliOut [open $GAOutDir/waterCali.log w]
    set scoreOriOut [open $GAOutDir/scoreOri.log w]
    set sortOut [open $GAOutDir/totalEnergySorted.log w]
    set bestOut [open $GAOutDir/best.log w]

    variable subPopNum
    variable subPopSize
    variable subPopDict 
    set subPopDict [dict create]
    set statusText "generating initial population"
    if {$guiMode} {
	::GOLEM::gui::update_status_text $statusText
    } else { 
	puts $statusText
    }
    for {set i 0} {$i<$subPopNum} {incr i} {
	dict set subPopDict subPop$i [init_pop $subPopSize]
    }
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    set round 0
    set statusText "running iteration 0"
    if {$guiMode} {
	::GOLEM::gui::update_status_text $statusText
    } else { 
	puts $statusText
    }
    puts "writing system dcd"
    pop_to_dcd $subPopDict
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    puts "minimizing"
    variable namdSocket
    puts $namdSocket $round 
    flush $namdSocket
}

proc ::GOLEM::run::run_GA_one_round {chan} {
    variable debug
    variable time
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime }
    variable round 
    set fromChan [gets $chan]
    puts $fromChan
    if {$fromChan==""} {return}
    if {$round!=$fromChan} {
	puts "something wrong, round in GA is not round in NAMD"
    }
    variable subPopDict
    variable scoreListList
    variable eliteListList
    variable scoreOriOut
    variable sortOut
    variable bestOut
    variable topThreeScore
    variable round
    variable roundMax
    variable bestSameRound
    variable namdSocket
    variable guiMode
    variable bestDistinctScoreAll
    variable bestDistinctScoreAllMDFF
    variable bestDistinctScoreAllEnergy
    variable bestDistinctScoreAllWaterCali
    variable waterMaxNum
    variable nicheCapacity
    variable MDFFList
    variable energyList
    variable subPopSize
    if {0} {
    if {$round!=0 && $round<=150 && [expr $round%25]==0} {
	#set nicheCapacity [expr int(ceil(0.1*$subPopSize))]
	set nicheCapacity [expr int(2.0*$nicheCapacity)]
	#set nicheCapacity [expr int(2.0*$nicheCapacity)]
    }
    }
    if {0} {
    if {$round==150} {
	set nicheCapacity [expr int(ceil(0.1*$subPopSize))]
    }
    }
    if {0} {
    if {$round!=0 && $round<=250 && [expr $round%50]==0} {
	#set nicheCapacity [expr int(ceil(0.1*$subPopSize))]
	set nicheCapacity [expr int(2.0*$nicheCapacity)]
	#set nicheCapacity [expr int(2.0*$nicheCapacity)]
    }
    }
    if {$debug==1} {puts "updating population"}
    set updatedSubPopDict [dcd_to_pop $subPopDict]; list
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    #set updatedScoreListList [calc_fitness $updatedSubPopDict]
    if {$debug==1} {puts "calculating fitness"}
    lassign [calc_fitness $updatedSubPopDict] updatedScoreListList updatedMDFFList updatedEnergyList
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    if {$debug==1} {puts "rewinding"}
    if {$round>0} {
	rewind $scoreListList  updatedScoreListList $subPopDict updatedSubPopDict $eliteListList $MDFFList updatedMDFFList $energyList updatedEnergyList
    }
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    if {$debug==1} {puts "picking best distinct results"}
    set scoreListList $updatedScoreListList; list
    set subPopDict $updatedSubPopDict; list
    set MDFFList $updatedMDFFList; list
    set energyList $updatedEnergyList; list
    set oneScoreList [concat {*}$scoreListList]; list
    puts $scoreOriOut $oneScoreList
    flush $scoreOriOut
    set sortedOneScoreList [lsort -real -decreasing $oneScoreList];list 
    puts $sortOut $sortedOneScoreList
    flush $sortOut
    lassign [best_distinct $subPopDict $scoreListList 10] bestDistinctScore bestDistinctScoreMDFF bestDistinctScoreEnergy bestDistinctScoreWaterCali
    for {set i 0} {$i<[llength $bestDistinctScore]} {incr i} {
	lset bestDistinctScore $i [format "%.1f" [lindex $bestDistinctScore $i]]
    }
    lappend bestDistinctScoreAll $bestDistinctScore
    lappend bestDistinctScoreAllMDFF $bestDistinctScoreMDFF
    lappend bestDistinctScoreAllEnergy $bestDistinctScoreEnergy
    lappend bestDistinctScoreAllWaterCali $bestDistinctScoreWaterCali
    if {$guiMode} {
	$::GOLEM::gui::w.console.output insert end [list $round {*}$bestDistinctScore]
	update
    }
    puts $bestOut $bestDistinctScore
    flush $bestOut
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    if {$debug==1} {puts "sort score"}
    sort_fit subPopDict scoreListList 
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    if {$debug==1} {puts "group, niching, elites"}
    set eliteListList [group scoreListList]; list
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    puts "round $round, elite: $eliteListList"
    if {$round==0} {
	set topThreeScore [lrange $bestDistinctScore 0 2]
	set bestSameRound 0
    } else {
	if {$topThreeScore==[lrange $bestDistinctScore 0 2]} {
	    incr bestSameRound
	} else {
	    set topThreeScore [lrange $bestDistinctScore 0 2]
	    set bestSameRound 0
	}
    }
    variable debug
    variable GAOutDir
    if {!$debug} {
	catch {file delete $GAOutDir/[expr $round-1].system.dcd}
	catch {file delete $GAOutDir/[expr $round-1].min.system.dcd}
	catch {file delete $GAOutDir/[expr $round-1].min.dcd}
	catch {file delete $GAOutDir/[expr $round-1].sorted.system.dcd}
    }
    incr round
    variable debug

    if {0} {
    variable finalPhase

    if {$bestSameRound>100} {
	if {$finalPhase==0} {
	    set statusText "Best pose not updated in 100 iterations. Increasing niche capacity to allow more water sampling."
	    set bestSameRound 0
	    variable nicheCapacity
	    variable subPopSize
	    set nicheCapacity [expr ceil(0.1*$subPopSize)]
	    set finalPhase 1
	} else {
	    set statusText "Best pose not updated in 100 iterations. Docking finished."
    	    if {$guiMode} {
    	        ::GOLEM::gui::update_status_text $statusText
    	    } else { 
    	        puts $statusText
    	    }
            terminate;return
	}
    }
    }
    variable quitVMD
    if {$bestSameRound>100 && $round>500} {
        set statusText "Best pose not updated in 100 iterations. Docking finished."
    	if {$guiMode} {
    	    ::GOLEM::gui::update_status_text $statusText
    	} else { 
    	    puts $statusText
    	}
        terminate;
	if $quitVMD {
	    exit
	} else {
	    return
        }
    }

    if {$round>=$roundMax} {
	set statusText "Reached maximum number of iteration. Docking finished."
	terminate;
	if $quitVMD {
	    exit
	} else {
	    return
        }
    }
    if {$debug==1} {puts "evolving, generating new generation"}
    set subPopDict [evolve $subPopDict $scoreListList $eliteListList]; list
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    set statusText "running iteration $round"
    if {$guiMode} {
	::GOLEM::gui::update_status_text $statusText
    } else { 
	puts $statusText
    }
    if {$debug==1} {puts "saving system dcd"}
    pop_to_dcd $subPopDict $eliteListList
    if {$debug==1} {
	set curTime [clock clicks -millisecond]
    	puts "********************Takes [expr ($curTime-$time)/1000.] seconds************************"
    	set time $curTime
    }
    puts $namdSocket $round
    flush $namdSocket
}

proc ::GOLEM::run::GA_prepare {} {
#define papameters that require inputs
    variable outDir
    variable NAMDOutDir $outDir/run/NAMDlog
    variable GAOutDir $outDir/run/GAlog
#create output dir
    if {![file exists $NAMDOutDir]} {file mkdir $NAMDOutDir} else {file delete -force -- $NAMDOutDir; file mkdir $NAMDOutDir}
    if {![file exists $GAOutDir]} {file mkdir $GAOutDir} else {file delete -force -- $GAOutDir; file mkdir $GAOutDir}

    variable popMax
    variable subPopNum     
    variable subPopSize
    variable eliteMaxNum
    variable nicheCapacity
    variable roundMax
    variable waterMapCali
    variable minStep
    variable ligandCoupFactor
    variable waterCoupFactor
    variable sidechainCoupFactor
    variable crossoverRate
    variable mutateRate
    variable immigrantRate
    variable minorGeneMutateRate
    variable ligandSimDisCutoff
    variable ligandSimAngleCutoff
    #variable eliteRoughRMSDCutoff
    #variable eliteFineRMSDCutoff
    variable ligandSimRMSDCutoff
    variable ligandSimRMSDRoughCutoff
    variable fitSimCutoff
    variable ligandSelStr
    variable fixedSidechain
    variable continuousMin
    variable debug
    
    if {![info exists popMax]} {set popMax 500}
    if {![info exists subPopNum]} {set subPopNum 5}
    set subPopSize [expr int($popMax/$subPopNum)]
    set popMax [expr $subPopSize*$subPopNum]
    #if {![info exists eliteMaxNum]} {set eliteMaxNum [expr int(0.02*$subPopSize)]}
    if {![info exists eliteMaxNum]} {set eliteMaxNum [expr int((0.05*$subPopSize))]}
    if {![info exists nicheCapacity]} {
	set nicheCapacity [expr int(ceil(0.10*$subPopSize))]
	#set nicheCapacity 1
	if {0} {
	variable waterMaxNum
	if {$waterMaxNum>0} {
	    set nicheCapacity 1
	} else {
	    set nicheCapacity 1
	}
	}
    }
    if {![info exists roundMax]} {set roundMax 1000}
    if {![info exists waterMapCali]} {
	set waterMapCali 0.8; #larger, more likely to put water
	#variable ligandPot
	#set waterMapCali [voltool info mean -i $ligandPot]
    }
    if {![info exists minStep]} {set minStep 100}
    #if {![info exists ligandCoupFactor]} {set ligandCoupFactor 6}
    #if {![info exists waterCoupFactor]} {set waterCoupFactor 4}
    #if {![info exists waterCoupFactor]} {set waterCoupFactor [expr $ligandCoupFactor*0.8]}
    if {![info exists sidechainCoupFactor]} {set sidechainCoupFactor $ligandCoupFactor}
    if {![info exists crossoverRate] || ![info exists mutateRate] || ![info exists immigrantRate]} {
	if {$subPopNum==1} {
	    #set crossoverRate 1.00
	    #set mutateRate 0.00
	    #set immigrantRate 0.00
	    set crossoverRate 0.80
	    set mutateRate 0.20
	    set immigrantRate 0.00
	} else {
	    #set crossoverRate 0.95
	    #set mutateRate 0.00
	    #set immigrantRate 0.05
	    set crossoverRate 0.75
	    set mutateRate 0.20
	    set immigrantRate 0.05

	}
    }
    #if {![info exists minorGeneMutateRate]} {set minorGeneMutateRate 0.02}
    if {![info exists minorGeneMutateRate]} {set minorGeneMutateRate 0.10}
    #if {![info exists eliteRoughRMSDCutoff]} {set eliteRoughRMSDCutoff 1.5}
    #if {![info exists eliteFineRMSDCutoff]} {set eliteFineRMSDCutoff 1.5}
    variable ligandAtomNum
    variable ligandNoHAtomNum
    #if {![info exists ligandSimRMSDCutoff]} {set ligandSimRMSDCutoff 2.0}
    #if {![info exists ligandSimRMSDCutoff]} {set ligandSimRMSDCutoff [expr sqrt($ligandAtomNum)/3.0]}
    #if {![info exists ligandSimRMSDRoughCutoff]} {set ligandSimRMSDRoughCutoff [expr sqrt($ligandNoHAtomNum)/3.0]}
    if {![info exists ligandSimRMSDCutoff]} {set ligandSimRMSDCutoff 2.0}
    if {![info exists ligandSimRMSDRoughCutoff]} {set ligandSimRMSDRoughCutoff 2.0}
    if {![info exists ligandSimDisCutoff]} {set ligandSimDisCutoff 1.0}
    if {![info exists ligandSimAngleCutoff]} {set ligandSimAngleCutoff 30.0}
    if {![info exists fitSimCutoff]} {set fitSimCutoff 5}
    if {![info exists continuousMin]} {
	if {$fixedSidechain} {
	    set continuousMin 0
	} else {
	    set continuousMin 0
	}
    }
    if {![info exists debug]} {set debug 0}
    if {![info exists quitVMD]} {set quitVMD 0}
    if {![info exists ligandSelStr]} {
	if {0} {
	if {$::GOLEM::gui::isPeptide==0} {
	    set ligandSelStr "resname $::GOLEM::gui::ligandResnameStr"
	} else {
	    set ligandSelStr "segname LIG"
	}
	}
	set ligandSelStr "segname LIG"
    }

    variable operatorAccuProbList [list [expr 1.0*($crossoverRate)/($crossoverRate+$mutateRate+$immigrantRate)] [expr 1.0*($crossoverRate+$mutateRate)/($crossoverRate+$mutateRate+$immigrantRate)] 1]
    variable M_PI	    3.1415926;
    variable pList [list]
    if {$subPopNum==1} {
	lappend pList 0.85
    } else { 
	for {set i 0} {$i<$subPopNum} {incr i} {
    	    lappend pList [expr 0.95-(0.95-0.75)/($subPopNum-1)*$i]
    	}
    }

#load mols, do atomselection
#ligand
    variable ligandPSF
    variable ligandPDB
    variable ligandDCD
    variable ligandLibMol [mol new $ligandPSF]; #this ligandLibMol load ligandLib, and save future 
    mol rename $ligandLibMol ligandLib
    mol addfile $ligandDCD waitfor all $ligandLibMol
    variable ligandLibSize [molinfo $ligandLibMol get numframes]
    variable ligandLibOriSize [molinfo $ligandLibMol get numframes]
    variable ligandLibSel [atomselect $ligandLibMol all]; #pop_to_dcd:get ligand xyz from lib; dcd_to_pop: center and align newly added cormations to libRefSel
    $ligandLibSel global
    variable ligandLibRefSel [atomselect $ligandLibMol all frame 0]
    $ligandLibRefSel global

#system
    variable systemPSF
    variable systemPDB
#this systemMol is used only to generate dcd of the new pop
#TODO segment selection list in systemMol to generate ligand coordinates
    variable systemMol [mol new $systemPSF]
    mol rename $systemMol systemMol
    mol addfile $systemPDB waitfor all $systemMol 
    variable systemSel [atomselect $systemMol all]
    $systemSel global
    variable oriXYZ [$systemSel get {x y z}]; list
    for {set i 0} {$i<[expr {$popMax-1}]} {incr i} {animate dup frame 0 $systemMol}
    variable systemLigandSel [atomselect $systemMol $ligandSelStr]
    variable systemLigandNoHSel [atomselect $systemMol "noh and $ligandSelStr"]
    $systemLigandSel global
    $systemLigandNoHSel global
    #variable ligandIndexFile $outDir/run/ligand.index
    #if {[file exists $ligandIndexFile] && [file isfile $ligandIndexFile]} {file delete $ligandIndexFile}
    #set ligandout [open $ligandIndexFile w]
    #puts $ligandout [[atomselect $systemMol $ligandSelStr] get index]
    #close $ligandout
#this systemMinimizedMol is used to update gene after minimization and sort 
#TODO segment selection list in systemMinimizedMol to read minmized ligand coordinates
    variable systemMinimizedMol [mol new $systemPSF]
    variable systemMinimizedSel [atomselect $systemMinimizedMol all]
    $systemMinimizedSel global
    variable systemMinimizedLigandSel1 [atomselect $systemMinimizedMol $ligandSelStr]; #used for ligandRMSD calculation (check_ligand_similarity)
    variable systemMinimizedLigandSel2 [atomselect $systemMinimizedMol $ligandSelStr]
    $systemMinimizedLigandSel1 global
    $systemMinimizedLigandSel2 global
    variable systemMinimizedLigandNoHSel1 [atomselect $systemMinimizedMol "$ligandSelStr and noh"]; #used for ligandRMSD calculation (check_ligand_similarity)
    variable systemMinimizedLigandNoHSel2 [atomselect $systemMinimizedMol "$ligandSelStr and noh"]
    $systemMinimizedLigandNoHSel1 global
    $systemMinimizedLigandNoHSel2 global

    variable siteMinX
    variable siteMinY
    variable siteMinZ
    variable siteMaxX
    variable siteMaxY
    variable siteMaxZ
    variable systemSidechain [atomselect $systemMol "sidechain and not $ligandSelStr and not segname GW and same residue as (x<$siteMaxX and x>$siteMinX and y<$siteMaxY and y>$siteMinY and z<$siteMaxZ and z>$siteMinZ)"]
    variable systemSidechainNoH [atomselect $systemMol "noh and sidechain and not $ligandSelStr and not segname GW and same residue as (x<$siteMaxX and x>$siteMinX and y<$siteMaxY and y>$siteMinY and z<$siteMaxZ and z>$siteMinZ)"]
    $systemSidechain global
    $systemSidechainNoH global

    variable waterMaxNum
#water added by GOLEM
    variable systemWaterSelList [list]
    variable systemWaterOSelList [list]
    variable waterCorRef
    if {$waterMaxNum>0} {
	set waterSel [atomselect $systemMol "water and segname GW"]
	set waterCorRef [lrange [$waterSel get {x y z}] 0 2]; #reference coordinates for all GOLEM water
	#atomselect to do popToDcd
	#atomselect for namd conf preparation; only O is coupled to grid force
	set waterResidueList [$waterSel get residue]
	$waterSel delete
	for {set i 0} {$i<$waterMaxNum} {incr i} {
    	    set waterSel [atomselect $systemMol "residue [lindex $waterResidueList [expr $i*3]]"]
    	    set waterOSel [atomselect $systemMol "noh and residue [lindex $waterResidueList [expr $i*3]]"]
    	    $waterSel global
    	    $waterOSel global
    	    lappend systemWaterSelList $waterSel
    	    lappend systemWaterOSelList $waterOSel
    	}
	variable systemMinimizedWaterSelList [list]
	for {set i 0} {$i<$waterMaxNum} {incr i} {
    	    set waterSel [atomselect $systemMinimizedMol "residue [lindex $waterResidueList [expr $i*3]]"]
    	    $waterSel global
    	    lappend systemMinimizedWaterSelList $waterSel
    	}
    }
#water in pdb
    variable optimizeCrystalWaterOrientation
    variable crystalWaterNum
    variable crystalWaterHSel
    if {$optimizeCrystalWaterOrientation} {
	#for namd conf preparation
	set crystalWaterHSel [atomselect $systemMol "(name H1 H2) and water and not segname GW and same residue as (x>$siteMinX and x<$siteMaxX and y>$siteMinY and y<$siteMaxY and z>$siteMinZ and z<$siteMaxZ)"]
	$crystalWaterHSel global
	set crystalWaterSel [atomselect $systemMol "water and not segname GW and same residue as (x>$siteMinX and x<$siteMaxX and y>$siteMinY and y<$siteMaxY and z>$siteMinZ and z<$siteMaxZ)"]
	set crystalWaterResidueList [$crystalWaterSel get residue]
	set crystalWaterNum [expr int([$crystalWaterSel num]/3)]
	set tmp [$crystalWaterSel get {x y z}]
    } else {
	set crystalWaterHSel [atomselect $systemMol "none"]
	$crystalWaterHSel global
	set crystalWaterNum 0
    }
    variable crystalWaterCorRef [list]
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
	lappend crystalWaterCorRef [lrange $tmp [expr $i*3] [expr $i*3+2]]
    }
    #popToDcd
    variable systemCrystalWaterSelList [list]
    #center of rotation
    variable crystalWaterOxygenCorList [list]
    if {$optimizeCrystalWaterOrientation} {$crystalWaterSel delete}
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
	set waterSel [atomselect $systemMol "residue [lindex $crystalWaterResidueList [expr $i*3]]"]
	$waterSel global
	lappend systemCrystalWaterSelList $waterSel
	lappend crystalWaterOxygenCorList [lindex [$waterSel get {x y z}] 0]
    }

    variable systemMinimizedCrystalWaterSelList 
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
	set crystalWaterSel [atomselect $systemMinimizedMol "residue [lindex $crystalWaterResidueList [expr $i*3]]"]
	$crystalWaterSel global
	lappend systemMinimizedCrystalWaterSelList $crystalWaterSel
    }

    variable crystalWaterCorRefList [list]
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
	set crystalWaterSel [atomselect $systemMol "residue [lindex $crystalWaterResidueList [expr $i*3]]"]
	$crystalWaterSel global
	lappend crystalWaterCorRefList [$crystalWaterSel get {x y z}]
    }

    variable rotamers
    variable dihedNum [llength $rotamers]
    #two sets of dihedral related atom selection: systemMol (generating dcd) and systemMinimizedMol (updating gene) 
    variable dihedList [list]
    variable systemMolRotateGroupSelList [list]
    variable systemMolBondSelList [list]

    foreach line $rotamers {
	lassign $line dihedral atomGroup
	lassign $dihedral id1 id2 id3 id4
	lappend dihedList [list $id1 $id2 $id3 $id4]
	set sel [atomselect $systemMol "index $atomGroup"]
	$sel global
	lappend systemMolRotateGroupSelList $sel
	set bondSel1 [atomselect $systemMol "index $id2"]
	set bondSel2 [atomselect $systemMol "index $id3"]
	$bondSel1 global
	$bondSel2 global
	lappend systemMolBondSelList [list $bondSel1 $bondSel2]
    }

#TODO
    variable segmentPSFList
    variable segmentDCDList
    variable segmentIndexList
    variable segmentAtomNumList
    variable segmentNum [llength $segmentIndexList]; #number of segments
    variable segmentLibMolList; #list of segmentLibMol to load segment$ID.dcd, and future new conformations
    variable segmentLibUniqIDListList [list]; #frame ID of unique conformations ; mutation resevior
    variable segmentLibMolRefSelList [list]; #frame 0 selection, for alignment only, shouldn't move to other frames
    variable segmentLibMolSel1List [list]; #pop_to_dcd:get conformatio (xyz) of each segment; add and align new conformation to each segmentLibMol
    variable segmentLibMolSel2List [list]; #used for RMSD comparison

#segmentLibMols
    for {set i 0} {$i<$segmentNum} {incr i} {
	set tmp [mol new [lindex $segmentPSFList $i]]
	mol rename $tmp segmentLib$i
	mol addfile [lindex $segmentDCDList $i] waitfor all $tmp
	lappend segmentLibMolList $tmp
	set uniqIDList [list]
	for {set j 0} {$j<[molinfo $tmp get numframes]} {incr j} {
	    lappend uniqIDList $j
	}
	lappend segmentLibUniqIDListList $uniqIDList
	set sel1 [atomselect $tmp all frame 0]
	set sel2 [atomselect $tmp all frame 0]
	set sel3 [atomselect $tmp all frame 0]
	$sel1 global
	$sel2 global
	$sel3 global
	lappend segmentLibMolRefSelList $sel1
	lappend segmentLibMolSel1List $sel2
	lappend segmentLibMolSel2List $sel3
    }
#systemMol and systemMinimizedMol
    variable systemSegmentSelList [list]
    variable systemMinimizedSegmentSelList [list]
    for {set i 0} {$i<$segmentNum} {incr i} {
	set tmp1 [atomselect $systemMol "index [lindex $segmentIndexList $i]"]
	set tmp2 [atomselect $systemMinimizedMol "index [lindex $segmentIndexList $i]"]
	$tmp1 global
	$tmp2 global
	lappend systemSegmentSelList $tmp1
	lappend systemMinimizedSegmentSelList $tmp2
    }

    variable portIndexList
    variable portNameList
    variable segmentLibMolPortSel1List [list]
    variable segmentLibMolPortSel2List [list]
    variable segmentLibMolPortRefSelList [list]

    for {set i 0} {$i<$segmentNum} {incr i} {
	set tmp1 [atomselect [lindex $segmentLibMolList $i] "name [lindex $portNameList $i]" frame 0]
	set tmp2 [atomselect [lindex $segmentLibMolList $i] "name [lindex $portNameList $i]" frame 0]
	set tmp3 [atomselect [lindex $segmentLibMolList $i] "name [lindex $portNameList $i]" frame 0]
	$tmp1 global
	$tmp2 global
	$tmp3 global
	lappend segmentLibMolPortSel1List $tmp1
	lappend segmentLibMolPortSel2List $tmp2
	lappend segmentLibMolPortRefSelList $tmp3
    }

    variable systemPortSelList [list]
    variable systemMinimizedPortSelList [list]
    for {set i 0} {$i<$segmentNum} {incr i} {
	set tmp1 [atomselect $systemMol "index [lindex $portIndexList $i]"]
	set tmp2 [atomselect $systemMinimizedMol "index [lindex $portIndexList $i]"]
	$tmp1 global
	$tmp2 global
	lappend systemPortSelList $tmp1
	lappend systemMinimizedPortSelList $tmp2
    }

    #variable ligandStrLength [expr int(8+$dihedNum)]
    #variable ligandStrLength [expr int(8*$segmentNum)]
    variable ligandStrLength [expr int(8+$segmentNum+$dihedNum)]
    variable mutateKeywordCandidateList [list ligID ligDisArray ligRotate]
    for {set i 0} {$i<$segmentNum} {incr i} {
	lappend mutateKeywordCandidateList segID$i
    }
    for {set i 0} {$i<$dihedNum} {incr i} {
	lappend mutateKeywordCandidateList ligDihedAngle$i
    }
}

proc ::GOLEM::run::get_water_num {gene} {
    variable dihedNum
    variable crystalWaterNum
#TODO
    variable segmentNum
    #set waterNum [expr int(([llength [dict keys $gene]]-4-$dihedNum-$crystalWaterNum*2)/3.0)]
    #set waterNum [expr int(([llength [dict keys $gene]]-4*$segmentNum-$crystalWaterNum*2)/3.0)]
    set waterNum [expr int(([llength [dict keys $gene]]-4-$segmentNum-$dihedNum-$crystalWaterNum*2)/3.0)]
    return $waterNum
}

proc ::GOLEM::run::get_atomic_number {sel} {
    set massList [$sel get mass]
    set atomicList [list]
    foreach mass $massList {
        lappend atomicList [expr int($mass/2.0+0.5)]
    }
    return $atomicList
}

proc ::GOLEM::run::prepare_namd_conf {} {
    variable systemPDB
    variable systemPSF
    variable ligandPot
    variable receptorPot
    variable NAMDOutDir
    variable GAOutDir
    variable popMax
    variable minStep
    variable systemSel
    variable systemWaterSelList
#TODO
    variable systemLigandSel
    variable systemSegmentSelList
    variable systemLigandNoHSel
    variable crystalWaterHSel
    variable systemSidechain
    variable systemSidechainNoH
    variable systemWaterOSelList
    variable ligandCoupFactor
    variable waterCoupFactor
    variable sidechainCoupFactor
    variable fixedSidechain
    variable bindingsiteCenter
    variable disMaxX
    variable disMaxY
    variable disMaxZ
    variable NAMDconf
    variable socketPort
    variable GADCDFile 
    variable parFileList

    $systemSel set beta 1
    $systemSel set occupancy 0
    $systemLigandSel set beta 0
    $crystalWaterHSel set beta 0
    foreach waterSel $systemWaterSelList {
        $waterSel set beta {0 0 0}
    }
    if {!$fixedSidechain} {
	$systemSidechain set beta 0
    }
    $systemSel writepdb "$NAMDOutDir/fix.pdb"
    
    $systemSel set beta 0
    $systemSel set occupancy 0
    $systemLigandNoHSel set beta [get_atomic_number $systemLigandNoHSel]
    $systemLigandNoHSel set occupancy 1
    $systemSel writepdb "$NAMDOutDir/MDFF_ligand.pdb"

    $systemSel set beta 0
    $systemSel set occupancy 0
#only water O coupled to density
    foreach water $systemWaterSelList {
	$water set beta [get_atomic_number $water]
	$water set occupancy {1 0 0}
    }
    $systemSel writepdb "$NAMDOutDir/MDFF_water.pdb"

    if {!$fixedSidechain} {
	$systemSel set beta 0
	$systemSel set occupancy 0
	$systemSidechainNoH set beta [get_atomic_number $systemSidechainNoH]
	$systemSidechainNoH set occupancy 1
	$systemSel writepdb "$NAMDOutDir/MDFF_sidechain.pdb"
    }

    $systemSel set beta 0
    $systemSel set occupancy 0
    $systemLigandNoHSel set beta [get_atomic_number $systemLigandNoHSel]
    $systemLigandNoHSel set occupancy 1
    foreach water $systemWaterOSelList {
	$water set beta [get_atomic_number $water]
	$water set occupancy 1
    }
    $systemSel writepdb "$NAMDOutDir/box.pdb"
    
    set dxFile [open "$NAMDOutDir/box.dx" w]
    generate_box_grid_force $bindingsiteCenter $disMaxX $disMaxY $disMaxZ $dxFile 
    close $dxFile

    set NAMDconf $NAMDOutDir/GANAMD.conf
    set out [open $NAMDconf w]
    puts $out "structure    $systemPSF"
    puts $out "coordinates  $systemPDB"
    puts $out "outputName   $NAMDOutDir/GANAMD"
    puts $out "temperature  0"
    puts $out "paraTypeCharmm	on"
    foreach parFile $parFileList {
	puts $out "parameters	$parFile"
    }
    puts $out "exclude	scaled1-4"
    puts $out "switching    on"
    puts $out "vdwForceSwitching    on"
    #puts $out "switchdist   10."
    puts $out "switchdist   7."
    #puts $out "cutoff	12"
    puts $out "cutoff	9"
    #puts $out "pairlistdist 13.5"
    puts $out "pairlistdist 11"
    puts $out "rigidBonds   all"
    puts $out "stepspercycle $minStep"
    puts $out "timestep	1"
    puts $out "dcdfreq	$minStep"
    puts $out "fixedAtoms   on"
    puts $out "fixedAtomsFile	fix.pdb"
    puts $out "fixedAtomsCol B"
    puts $out "mgridforce   on"
    puts $out "mgridforcefile	ligand $NAMDOutDir/MDFF_ligand.pdb"
    puts $out "mgridforcecol	ligand	O"
    puts $out "mgridforcechargecol  ligand  B"
    puts $out "mgridforcepotfile    ligand  $ligandPot"
    puts $out "mgridforcescale	ligand	$ligandCoupFactor $ligandCoupFactor $ligandCoupFactor"
    puts $out "mgridforcefile	water	$NAMDOutDir/MDFF_water.pdb"
    puts $out "mgridforcecol	water	O"
    puts $out "mgridforcechargecol	water	B"
    puts $out "mgridforcepotfile    water  $ligandPot"
    puts $out "mgridforcescale	water	$waterCoupFactor $waterCoupFactor $waterCoupFactor"
    if {!$fixedSidechain} {
	puts $out "mgridforcefile   sidechain	$NAMDOutDir/MDFF_sidechain.pdb"
	puts $out "mgridforcecol	sidechain	O"
    	puts $out "mgridforcechargecol  sidechain  B"
    	puts $out "mgridforcepotfile    sidechain  $receptorPot"
    	puts $out "mgridforcescale	sidechain	$sidechainCoupFactor $sidechainCoupFactor $sidechainCoupFactor"
    }
    puts $out "mgridforcefile	box box.pdb"
    puts $out "mgridforcecol	box O"
    puts $out "mgridforcechargecol  box B"
    puts $out "mgridforcepotfile    box	box.dx"
    puts $out "mgridforcescale	box 1	1   1"
    puts $out "mgridforcecont1	box yes"
    puts $out "mgridforcecont2	box yes"
    puts $out "mgridforcecont3	box yes"
    puts $out "mgridforcelite	box yes"
    puts $out "set ::realS -1"
    puts $out "proc ::accept {chan addr port} {"
    puts $out "	set ::realS \$chan"
    puts $out "}"
    puts $out "proc ::run_one_round {chan} {"
    puts $out "	set round \[gets \$chan\]"
    puts $out " dcdfile $GAOutDir/\$round.min.system.dcd"
    puts $out " if {\$round==\"end\"} {close \$::realS;exit}"
    puts $out "	set dcdFile $GAOutDir/\$round.system.dcd"
    puts $out "	coorfile open dcd \$dcdFile"
    puts $out "	for {set index 0} {\$index<$popMax} {incr index} {"
    puts $out "	    if {!\[coorfile read\]} {"
    puts $out "		firstTimeStep 0"	
    puts $out "		minimize $minStep"	
    puts $out "	    }"
    puts $out "	}"
    puts $out " coorfile close"
    puts $out "	puts \$chan \$round" 
    puts $out "	flush \$chan" 
    puts $out "}"
    puts $out "socket -server ::accept $socketPort"
    puts $out "vwait ::realS"
    puts $out "fileevent \$::realS readable \[list ::run_one_round \$::realS\]"
    puts $out "vwait forever"
    flush $out
    close $out
    #set GADCDFile $NAMDOutDir/GANAMD.dcd
}

proc ::GOLEM::run::generate_box_grid_force {center maxDisX maxDisY maxDisZ dxFile} {
    set freeDisX [expr 1.0*$maxDisX]
    set forceEndDisX [expr 2.0*$maxDisX]
    set boundDisX [expr 3.0*$maxDisX]
    set deltaX [expr 0.25*$freeDisX]

    set freeDisY [expr 1.0*$maxDisY]
    set forceEndDisY [expr 2.0*$maxDisY]
    set boundDisY [expr 3.0*$maxDisY]
    set deltaY [expr 0.25*$freeDisY]

    set freeDisZ [expr 1.0*$maxDisZ]
    set forceEndDisZ [expr 2.0*$maxDisZ]
    set boundDisZ [expr 3.0*$maxDisZ]
    set deltaZ [expr 0.25*$freeDisZ]

    set count [expr int(ceil($boundDisX*2/$deltaX))]
    set count2 [expr int($count*$count)]
    set count3 [expr int($count*$count*$count)]

    set origin [vecadd $center [vecscale [list $boundDisX $boundDisY $boundDisZ] -1]]
    puts $dxFile "object 1 class gridpositions counts $count $count $count"
    puts $dxFile "origin $origin"
    puts $dxFile "delta $deltaX 0 0"
    puts $dxFile "delta 0 $deltaY 0"
    puts $dxFile "delta 0 0 $deltaZ"
    puts $dxFile "object 2 class gridconnections counts $count $count $count"
    puts $dxFile "object 3 class array type double rank 0 items $count3 data follows"
    set xList [list]
    set yList [list]
    set zList [list]
    for {set i 0} {$i<$count} {incr i} {
        lappend xList [expr [lindex $origin 0]+$i*$deltaX]
        lappend yList [expr [lindex $origin 1]+$i*$deltaY]
        lappend zList [expr [lindex $origin 2]+$i*$deltaZ]
    }
    set oneLine [list]
    set maxValue 99999.0
    for {set i 0} {$i<$count3} {incr i} {
        set zID [expr $i%$count]
        set yID [expr int(floor(($i%$count2)/$count))]
        set xID [expr int(floor($i/$count2))]
        set xCor [lindex $xList $xID]
        set yCor [lindex $yList $yID]
        set zCor [lindex $zList $zID]

        set XYZdis []
        lappend XYZdis [expr abs($xCor-[lindex $center 0])]
        lappend XYZdis [expr abs($yCor-[lindex $center 1])/$deltaY*$deltaX]
        lappend XYZdis [expr abs($zCor-[lindex $center 2])/$deltaZ*$deltaX]
        set maxXYZdis [::tcl::mathfunc::max {*}$XYZdis]
        if {$maxXYZdis<$freeDisX} {
    	set value 0
        } 
        if {$maxXYZdis>=$freeDisX && $maxXYZdis<$forceEndDisX} {
    	set value [expr ($maxXYZdis-$freeDisX)/($forceEndDisX-$freeDisX)*$maxValue]
        }
        if {$maxXYZdis>=$forceEndDisX} {set value $maxValue}
        #puts "$zID, $yID, $xID, $XYZdis, $maxXYZdis, $value"
        lappend oneLine $value
        if {[llength $oneLine]==3} {
    	puts $dxFile $oneLine
    	set oneLine [list]
        }
    }
    if {[llength $oneLine]==1 || [llength $oneLine]==2} {
        puts $dxFile $oneLine
    }
    puts $dxFile "object 4 class field"
    puts $dxFile "component \"positions\" value 1"
    puts $dxFile "component \"connections\" value 2"
    puts $dxFile "component \"data\" value 3"
}


proc ::GOLEM::run::init_NAMD {} {
    variable NAMDOutDir
    variable socketPort
    variable namdSocket
    variable NAMDlog
    variable namdBin
    variable namdOpt
    variable NAMDconf

    if {[catch {::ExecTool::exec $namdBin $namdOpt $NAMDconf > $NAMDOutDir/GANAMD.log &}]} {
	puts "error running NAMD"
	return 1
    }
    while {[catch {set namdSocket [socket localhost $socketPort]}]!=0} {
	after 500
    }
    set NAMDlog [open $NAMDOutDir/GANAMD.log r]
    fileevent $namdSocket readable [list ::GOLEM::run::run_GA_one_round $namdSocket]
    return 0
}

proc ::GOLEM::run::terminate {} {
    variable GAterminated
    set GAterminated 1
    variable namdSocket
    puts $namdSocket "end"
    flush $namdSocket
    close $namdSocket
    variable MINlog; catch {close $MINlog}
    variable scoreOriOut; catch {close $scoreOriOut}
    variable sortOut; catch {close $sortOut}
    #variable waterCaliOut; catch {close $waterCaliOut}
    variable densityCaliOut; catch {close $densityCaliOut}
    save_output
    variable debug
    variable NAMDOutDir
    if {!$debug} {
	#catch {file delete $NAMDOutDir/GANAMD.dcd}
	catch {file delete $NAMDOutDir/GANAMD.log}
    }
}

proc ::GOLEM::run::save_docking_result {round rank} {
    variable outDir
    variable ligandSelStr
    variable GAOutDir
    variable systemPSF
    variable siteMinX
    variable siteMinY
    variable siteMinZ
    variable siteMaxX
    variable siteMaxY
    variable siteMaxZ
    variable cutoffDis
    variable receptorPSF
    variable receptorPDB
    variable fullReceptorPSF
    variable fullReceptorPDB
    variable ligandPSF
    set minx [expr $siteMinX-$cutoffDis/2]
    set miny [expr $siteMinY-$cutoffDis/2]
    set minz [expr $siteMinZ-$cutoffDis/2]
    set maxx [expr $siteMaxX+$cutoffDis/2]
    set maxy [expr $siteMaxY+$cutoffDis/2]
    set maxz [expr $siteMaxZ+$cutoffDis/2]
    if {![file exists $outDir/result]} {file mkdir $outDir/result}
    set tmpMol [mol new $systemPSF]
    mol addfile $GAOutDir/$round.best_distinct.dcd first $rank last $rank $tmpMol
    set ligSel [atomselect $tmpMol $ligandSelStr]
    $ligSel writepdb $outDir/result/ligand.pdb
    set watSel [atomselect $tmpMol "water and segname GW and same residue as (x>$siteMinX and x<$siteMaxX and y>$siteMinY and y<$siteMaxY and z>$siteMinZ and z<$siteMaxZ)"]
    if {[$watSel num]>0} {
	$watSel writepsf $outDir/result/water.psf
	$watSel writepdb $outDir/result/water.pdb
    }
    #set tmpRecMol [mol new $receptorPSF]
    #mol addfile $receptorPDB $tmpRecMol
    set tmpRecMol [mol new $fullReceptorPSF]
    mol addfile $fullReceptorPDB $tmpRecMol
    [atomselect $tmpRecMol "same residue as (x>$minx and x<$maxx and y>$miny and y<$maxy and z>$minz and z<$maxz)"] set {x y z} [[atomselect $tmpMol "all and not segname GW and not $ligandSelStr"] get {x y z}]
    set recSel [atomselect  $tmpRecMol all]
    $recSel writepsf $outDir/result/receptor.psf
    $recSel writepdb $outDir/result/receptor.pdb

    psfcontext reset
    resetpsf
    set golemcontext [psfcontext new]
    psfcontext eval $golemcontext {
	readpsf $ligandPSF
	coordpdb $outDir/result/ligand.pdb
	readpsf $outDir/result/receptor.psf
	coordpdb $outDir/result/receptor.pdb
	if {[$watSel num]>0} {
	    readpsf $outDir/result/water.psf
	    coordpdb $outDir/result/water.pdb
	}
	writepsf $outDir/result/docked_iteration$round\_rank$rank.psf
	writepdb $outDir/result/docked_iteration$round\_rank$rank.pdb
    }
}

proc ::GOLEM::run::random_element {l} {
    return [lindex $l [expr int(floor(rand()*[llength $l]))]]
}

proc ::GOLEM::run::generate_one_init_gene {} {
#TODO
    variable ligandLibOriSize
    variable segmentLibUniqIDListList
    variable segmentNum
    variable disMaxX
    variable disMaxY
    variable disMaxZ
    variable M_PI
    variable dihedNum
    variable waterMaxNum
    variable crystalWaterNum
    
    #randomly select a ligand conformation
    set ligandConfID [expr int(floor(rand()*$ligandLibOriSize))]
    set dx [expr (rand()-0.5)*2*$disMaxX]
    set dy [expr (rand()-0.5)*2*$disMaxY]
    set dz [expr (rand()-0.5)*2*$disMaxZ]
    set displacementArray [list $dx $dy $dz]
    set randomAxis [list [expr rand()] [expr rand()] [expr rand()]]
    set randomAngle [expr rand()*360]
    set rotationMatrix [transabout $randomAxis $randomAngle]

    dict set tmp ligID $ligandConfID
    dict set tmp ligDisArray $displacementArray
    dict set tmp ligRdAxis $randomAxis
    dict set tmp ligRdAngle $randomAngle
    
    #randomly select segment conformation
    for {set i 0} {$i<$segmentNum} {incr i} {
        set segConfID [random_element [lindex $segmentLibUniqIDListList $i]]
        dict set tmp segID$i $segConfID
    }
    for {set i 0} {$i<$dihedNum} {incr i} {
    #-180 to 180
        dict set tmp ligDihedAngle$i [expr (rand()-0.5)*360]
    }
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
        set randomAxis [list [expr rand()] [expr rand()] [expr rand()]]
        set randomAngle [expr rand()*360]
        dict set tmp cWatRdAxis$i $randomAxis
        dict set tmp cWatRdAngle$i $randomAngle
    }
    #set waterNum [expr int(floor(rand()*$waterMaxNum))]
    set waterNum $waterMaxNum
    for {set i 0} {$i<$waterNum} {incr i} {
        set dx [expr (rand()-0.5)*2*$disMaxX]
        set dy [expr (rand()-0.5)*2*$disMaxY]
        set dz [expr (rand()-0.5)*2*$disMaxZ]
    	set displacementArray [list $dx $dy $dz]
    	#set displacementArray [roll_water_location]
        set randomAxis [list [expr rand()] [expr rand()] [expr rand()]]
        set randomAngle [expr rand()*360]
        dict set tmp watDisArray$i $displacementArray
        dict set tmp watRdAxis$i $randomAxis
        dict set tmp watRdAngle$i $randomAngle
    }
    return $tmp
} 

proc ::GOLEM::run::init_pop {size} {
    set pop [dict create]

    for {set i 0} {$i<$size} {incr i} {
	dict append pop $i [generate_one_init_gene]
    }
    return $pop
}

proc ::GOLEM::run::dcd_to_pop {subPopDict} {
#this function should be called when namd finishes one round
    variable round
    variable popMax
    #variable ligandIndexFile
    variable GAOutDir
    variable GADCDFile

    #exec catdcd -o $GAOutDir/$round.min.system.dcd -first [expr $round*$popMax+1] -last [expr ($round+1)*$popMax] $GADCDFile
    #exec catdcd -o $GAOutDir/$round.min.dcd -i $ligandIndexFile $GAOutDir/$round.min.system.dcd 
#read min dcd and update pop genes
    #return [::GOLEM::run::dcd_to_pop_core $subPopDict $GAOutDir/$round.min.system.dcd $GAOutDir/$round.min.dcd]
    return [::GOLEM::run::dcd_to_pop_core $subPopDict $GAOutDir/$round.min.system.dcd]
}

#no need for ligandDcdFile
proc ::GOLEM::run::dcd_to_pop_core {subPopDict complexDcdFile {ligandDcdFile {}}} {
    variable systemMinimizedMol 
    variable ligandLibMol
    variable segmentLibMolList
    variable ligandLibSize
    variable segmentLibUniqIDListList
    variable popMax
    variable systemMinimizedLigandSel1
    variable systemMinimizedSegmentSelList
    variable ligandLibSel
    variable segmentLibMolSel1List
    variable segmentLibMolSel2List
    variable ligandLibRefSel
    variable segmentLibMolRefSelList
    variable dihedList
    variable dihedNum
    variable waterMaxNum
    variable disMaxX
    variable disMaxY
    variable disMaxZ
    variable subPopNum
    variable subPopSize
    variable bindingsiteCenter
    variable systemMinimizedWaterSelList
    variable waterCorRef
    variable round
    variable crystalWaterNum
    variable systemMinimizedCrystalWaterSelList 
    variable crystalWaterCorRefList

    variable segmentIndexList
    variable segmentLibMolList
    variable segmentNum
    variable popMax

    variable dihedNum
    variable dihedList

    variable segmentLibMolPortRefSelList
    variable segmentLibMolPortSel1List
    variable systemMinimizedPortSelList

    set subPopList [dict create]
#system dcd
    mol addfile $complexDcdFile waitfor all $systemMinimizedMol
    if {[molinfo $systemMinimizedMol get numframes]>$popMax} {
	animate delete beg 0 end [expr [molinfo $systemMinimizedMol get numframes]-$popMax-1] $systemMinimizedMol
    }

#no need to read a ligandDcdFile; get ligand coor from systemMinimizedMol directly
    for {set frame 0} {$frame<$popMax} {incr frame} {
	$systemMinimizedLigandSel1 frame $frame
	set cor [$systemMinimizedLigandSel1 get {x y z}]; list
	animate dup frame 0 $ligandLibMol
	$ligandLibSel frame last
	$ligandLibSel set {x y z} $cor
	set mat [measure fit $ligandLibSel $ligandLibRefSel]
	$ligandLibSel move $mat
    }
    #mol addfile $ligandDcdFile waitfor all $ligandLibMol
    set ligandLibSize [expr $ligandLibSize+$popMax]
    if {$ligandLibSize!=[molinfo $ligandLibMol get numframes]} {puts "something wrong"}
#save ligand conformation in also the ligand lib
#
#update gene, and center align new ligand conformations 
#add all segment conformations to segmentLibMols, after alignment
#add new segment ID to segmentLibUniqIDListList 
    for {set seg 0} {$seg<$segmentNum} {incr seg} {
	set indexList [lindex $segmentIndexList $seg]
	set libMol [lindex $segmentLibMolList $seg]
	set refSel [lindex $segmentLibMolRefSelList $seg]
	set refCor [$refSel get {x y z}]; list
	set libSel [lindex $segmentLibMolSel1List $seg]
	set libRMSDSel [lindex $segmentLibMolSel2List $seg]
	set minSel [lindex $systemMinimizedSegmentSelList $seg]
	set uniqIDList [lindex $segmentLibUniqIDListList $seg]

	set portRefSel [lindex $segmentLibMolPortRefSelList $seg]
	set portRefCor [$portRefSel get {x y z}]; list
	set portLibSel [lindex $segmentLibMolPortSel1List $seg]
	set minPortSel [lindex $systemMinimizedPortSelList $seg]
	for {set frame 0} {$frame<$popMax} {incr frame} {
	    $minSel frame $frame
	    set cor [$minSel get {x y z}];list
	    animate dup frame 0 $libMol
	    set curFrame [expr [molinfo $libMol get numframes]-1]
	    $libSel frame last
	    $libSel set {x y z} $cor
	    $portLibSel frame last

	    if {[llength $indexList]==3} {
		set mat [::GOLEM::run::three_atoms_align $cor $refCor]
	    } else {
		set mat [measure fit $libSel $refSel]
	    }

	    $libSel move $mat

	    set portCor [$portLibSel get {x y z}]; list
	    if {[$portLibSel num]==3} {
		set mat [::GOLEM::run::three_atoms_align $portCor $portRefCor]
	    } else {
		set mat [measure fit $portLibSel $portRefSel]
	    }

	    $libSel move $mat

	    #idealy, good new ligand conformation should be added to uniqIDList, however, it's not easy now to measure ligand energy, so currently it's not allowed
	    if {0} {
	    set new 1
	    foreach uniqID $uniqIDList {
		$libRMSDSel frame $uniqID
		set RMSD [measure rmsd $libRMSDSel $libSel]
		if {$RMSD<0.5} {
		    set new 0
		    break
		}
	    }
	    if {$new==1} {
		lappend uniqIDList $curFrame
	    }
	    }

	}
	lset segmentLibUniqIDListList $seg $uniqIDList
    }

#update pop
    for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
	set pop [dict create]
	for {set i 0} {$i<$subPopSize} {incr i} {
	    set frame [expr $subPopSize*$subPopID+$i]
	    set newLigID [expr $ligandLibSize-$popMax+$frame]
	    $ligandLibSel frame $newLigID; 
	    $systemMinimizedLigandSel1 frame $frame; 
	    set minCenter [measure center $systemMinimizedLigandSel1]; 
	    set newDis [vecsub $minCenter $bindingsiteCenter];
	    set mat [measure fit $ligandLibSel $systemMinimizedLigandSel1];
	    lassign [matrix_to_axis_angle $mat] newAxis newAngle;
	    dict set pop $i ligID $newLigID;
	    dict set pop $i ligDisArray $newDis;
	    dict set pop $i ligRdAxis $newAxis;
	    dict set pop $i ligRdAngle $newAngle;
	    for {set seg 0} {$seg<$segmentNum} {incr seg} {
		set libMol [lindex $segmentLibMolList $seg]
		set libMolFrame [expr [molinfo $libMol get numframes]-$popMax+$frame]
		set newSegID $libMolFrame
		dict set pop $i segID$seg $newSegID
	    }
	    for {set j 0} {$j<$dihedNum} {incr j} {
	        set dihed [measure dihed [lindex $dihedList $j] molid $systemMinimizedMol frame $frame]
	        dict set pop $i ligDihedAngle$j $dihed
	    }
	    for {set j 0} {$j<$crystalWaterNum} {incr j} {
	        set waterSel [lindex $systemMinimizedCrystalWaterSelList $j]
		$waterSel frame $frame;list
	        set newRot [three_atoms_align [lindex $crystalWaterCorRefList $j] [$waterSel get {x y z}]]
	        lassign [matrix_to_axis_angle $newRot] newAxis newAngle;
	        dict set pop $i cWatRdAxis$j $newAxis
	        dict set pop $i cWatRdAngle$j $newAngle
	    }
	    set waterNum [get_water_num [dict get $subPopDict subPop$subPopID $i]]
	    for {set j 0} {$j<$waterNum} {incr j} {
		set waterSel [lindex $systemMinimizedWaterSelList $j];
		$waterSel frame $frame;list
		set tmpcenter [lindex [$waterSel get {x y z}] 0];
		set newDis [vecsub $tmpcenter $bindingsiteCenter];
		set newRot [three_atoms_align $waterCorRef [$waterSel get {x y z}]]
		lassign [matrix_to_axis_angle $newRot] newAxis newAngle;
		lassign $newDis x y z
		if {[expr abs($x)]>[expr 1.5*$disMaxX] || [expr abs($y)]>[expr 1.5*$disMaxY] || [expr abs($z)]>[expr 1.5*$disMaxZ]} {
		    puts "something wrong: distant water $x, $y $z, subPopID$subPopID, index $i, water $j found in dcdToPop"
		}
		dict set pop $i watDisArray$j $newDis;
		dict set pop $i watRdAxis$j $newAxis;
		dict set pop $i watRdAngle$j $newAngle;
	    }

	}
	dict set subPopList subPop$subPopID $pop
    }
    return $subPopList
}

proc ::GOLEM::run::three_atoms_align {cor1 cor2} {
    variable M_PI
    #set cor1center [vecscale [vecadd [lindex $cor1 0] [lindex $cor1 1] [lindex $cor1 2]] [expr 1.0/3]]
    #set cor2center [vecscale [vecadd [lindex $cor2 0] [lindex $cor2 1] [lindex $cor2 2]] [expr 1.0/3]]
    set cor1mid [vecscale [vecadd [lindex $cor1 1] [lindex $cor1 2]] 0.5]
    set cor2mid [vecscale [vecadd [lindex $cor2 1] [lindex $cor2 2]] 0.5]
    set u1 [vecsub [lindex $cor1 1] [lindex $cor1 2]]
    set u1 [vecnorm $u1]
    set u2 [vecsub [lindex $cor2 1] [lindex $cor2 2]]
    set u2 [vecnorm $u2]
    set h [veccross $u1 $u2]
    set cos [vecdot $u1 $u2]
    if {$cos>1} {set cos 1}; #sometimes it is outside the [-1,1] range due to calculation erros
    if {$cos<-1} {set cos -1}
    set T1 [transabout $h [expr acos($cos)*180.0/$M_PI]]
    set transCor1 [list]
    lappend transCor1 [vecdot [lindex $T1 0] [list {*}[lindex $cor1 0] 1]] 
    lappend transCor1 [vecdot [lindex $T1 1] [list {*}[lindex $cor1 0] 1]] 
    lappend transCor1 [vecdot [lindex $T1 2] [list {*}[lindex $cor1 0] 1]]
    set transCor1mid [list]
    lappend transCor1mid [vecdot [lindex $T1 0] [list {*}$cor1mid 1]]
    lappend transCor1mid [vecdot [lindex $T1 1] [list {*}$cor1mid 1]]
    lappend transCor1mid [vecdot [lindex $T1 2] [list {*}$cor1mid 1]]  
    set u1 [vecsub $transCor1mid $transCor1]
    set u1 [vecnorm $u1]
    set u2 [vecsub $cor2mid [lindex $cor2 0]] 
    set u2 [vecnorm $u2]
    set h [veccross $u1 $u2]
    set cos [vecdot $u1 $u2]
    if {$cos>1} {set cos 1}; #sometimes it is outside the [-1,1] range due to calculation erros
    if {$cos<-1} {set cos -1}
    set T2 [transabout $h [expr acos($cos)*180.0/$M_PI]]
    #return [transmult $T2 $T1]
    set mat [transmult $T2 $T1]

    set newCor1 [list [coordtrans $mat [lindex $cor1 0]] [coordtrans $mat [lindex $cor1 1]] [coordtrans $mat [lindex $cor1 2]]]
    set newCor1center [vecscale [vecadd [lindex $newCor1 0] [lindex $newCor1 1] [lindex $newCor1 2]] [expr 1.0/3]]
    set cor2center [vecscale [vecadd [lindex $cor2 0] [lindex $cor2 1] [lindex $cor2 2]] [expr 1.0/3]]

    set trans [vecsub $cor2center $newCor1center]
    lset mat 0 3 [lindex $trans 0]
    lset mat 1 3 [lindex $trans 1]
    lset mat 2 3 [lindex $trans 2]
    return $mat
}


proc ::GOLEM::run::matrix_to_axis_angle {matrix} {
    variable M_PI
    lassign $matrix m0 m1 m2 m3
    lassign $m0 m00 m01 m02 m03
    lassign $m1 m10 m11 m12 m13
    lassign $m2 m20 m21 m22 m23
    lassign $m3 m30 m31 m32 m33
    set epsilon 0.01
    set epsilon2 0.1

    if {[expr abs($m01-$m10)]<$epsilon && [expr abs($m02-$m20)]<$epsilon && [expr abs($m12-$m21)]<$epsilon} {
#singular
#0 degree?
	if {[expr abs($m01+$m10)]<$epsilon2 && [expr abs($m02+$m20)]<$epsilon2 && [expr abs($m12+$m21)]<$epsilon2 && [expr abs($m00+$m11+$m22-3)]<$epsilon2} {
	    set angle 0
	    return  [list [list [expr rand()] [expr rand()] [expr rand()]] $angle]
	} else {
#180 degree 
	    set angle 180
	    set xx [expr ($m00+1.0)/2.0]
	    set yy [expr ($m11+1.0)/2.0]
	    set zz [expr ($m22+1.0)/2.0]
	    set xy [expr ($m01+$m10)/4.0]
	    set xz [expr ($m02+$m20)/4.0]
	    set yz [expr ($m12+$m21)/4.0]
	    if {$xx>$xy && $xx>$zz} {
		if {$xx<$epsilon} {
		    set x 0
		    set y 0.7071
		    set z 0.7071
		} else {
		    set x [expr sqrt($xx)]
		    set y [expr $xy/$x]
		    set z [expr $xz/$x]
		} 
	    } elseif {$yy>$zz} {
		if {$yy<$epsilon} {
		    set x 0.7071
		    set y 0
		    set z 0.7071
		} else {
		    set y [expr sqrt($yy)]
		    set x [expr $xy/$y]
		    set z [expr $yz/$y]
		}
	    } else {
		if {$zz<$epsilon} {
		    set x 0.7071
		    set y 0.7071
		    set z 0
		} else {
		    set z [expr sqrt($zz)]
		    set x [expr $xz/$z]
		    set y [expr $yz/$z]
		}
	    }
	    return [list [list $x $y $z] $angle]
	}
    } else {
	set angle [expr 180.0*acos(($m00+$m11+$m22-1)/2)/$M_PI]
    	set d [expr sqrt(($m21-$m12)**2+($m02-$m20)**2+($m10-$m01)**2)]
    	set x [expr ($m21-$m12)/$d]
    	set y [expr ($m02-$m20)/$d]
    	set z [expr ($m10-$m01)/$d]
    	return [list [list $x $y $z] $angle]
    }
}

proc ::GOLEM::run::calc_fitness {subPopDict} {
    variable round
    variable popMax
    variable waterMapCali
    variable waterCoupFactor
    variable subPopNum
    variable subPopSize
    #set newFitList [vecscale -1 [::GOLEM::run::fetch_total]]
    lassign [::GOLEM::run::fetch_total] newFitList newMDFFList newEnergyList
    #calibrate energy by water number and distant water
    variable waterMaxNum
    variable disMaxX
    variable disMaxY
    variable disMaxZ
#no need to calibrate water 
    #variable waterCaliList
    #set waterCaliList [list]
    #for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
    #    for {set i 0} {$i<$subPopSize} {incr i} {
    #        set frame [expr $subPopSize*$subPopID+$i]
    #	    set waterNum [get_water_num [dict get $subPopDict subPop$subPopID $i]]
    #        set waterCali [expr $waterNum*($waterCoupFactor*$waterMapCali*8-4)]
    #        lappend waterCaliList $waterCali
    #        lset newFitList $frame [expr [lindex $newFitList $frame]+$waterCali]
    #	}
    #}
    #variable waterCaliOut
    #puts $waterCaliOut $waterCaliList
    #flush $waterCaliOut
    set fitLL [list]
    for {set i 0} {$i<$subPopNum} {incr i} {
	lappend fitLL [lrange $newFitList [expr $i*$subPopSize] [expr ($i+1)*$subPopSize-1]] 
    }
    #return $fitLL
    return [list $fitLL $newMDFFList $newEnergyList]
}

proc ::GOLEM::run::rewind {oldFitListList newFitListList oldSubPopDict newSubPopDict eliteListList oldMDFFList newMDFFList oldEnergyList newEnergyList} {
#!!only for elite, because only elite has fit before minimization
    variable round
    if {$round==0} {
	return
    } else {
#if elite's fit get lower after minimization, revert them in ligandMinimizedMol, systemMinimizedMol, and pop
	variable systemMinimizedMol
	variable systemMinimizedSel
	variable popMax
#systemMinimizedMol and ligandMinimizedMol are loaded with minimized dcds already in process minimize
#attach unminimized  elite dcd to these two mol 
	variable GAOutDir
	variable subPopNum
	variable subPopSize
	variable eliteMaxNum
	#mol addfile $GAOutDir/$round.system.dcd waitfor all $systemMinimizedMol
	upvar 1 $newFitListList newFitLL	
	upvar 1 $newSubPopDict newSubPopD
	upvar 1 $newMDFFList newMDFFL
	upvar 1 $newEnergyList newEnergyL
	#puts "newMDFFL len [llength $newMDFFL]"
	#puts "$newEnergyList"
	#puts "newEnergyList len [llength $newEnergyList]"
	#puts "newEnergyL len [llength $newEnergyL]"
	for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
#number of elites may be smaller than eliteMaxNum
	    set eliteNum [llength [lindex $eliteListList $subPopID]]
	    for {set i 0} {$i<$eliteNum} {incr i} {
		#set oldFit [lindex $oldFitListList $subPopID $i]
		set oldFit [lindex $oldFitListList $subPopID [lindex $eliteListList $subPopID $i]]
		set newFit [lindex $newFitLL $subPopID $i]
		if {$oldFit>$newFit} {
		    puts "revert subPop$subPopID, elite $i, oldFit $oldFit, newfit $newFit, index [lindex $eliteListList $subPopID $i] in the previous round"
		    #elite's dcd should be read from the previous round
		    dict set newSubPopD subPop$subPopID $i [dict get $oldSubPopDict subPop$subPopID $i]
		    #dict set newSubPopD subPop$subPopID $i [dict get $oldSubPopDict subPop$subPopID [lindex $eliteListList $subPopID $i]]
		    lset newFitLL $subPopID $i $oldFit
		    set frame [expr $subPopID*$subPopSize+$i]
		    set frameBefore [expr $subPopID*$subPopSize+[lindex $eliteListList $subPopID $i]]
		    lset newMDFFL $frame [lindex $oldMDFFList $frameBefore]
		    lset newEnergyL $frame [lindex $oldEnergyList $frameBefore]
		    mol addfile $GAOutDir/[expr {$round-1}].sorted.system.dcd first $frameBefore last $frameBefore waitfor all $systemMinimizedMol
#elite is appended to the last frame
		    $systemMinimizedSel frame $popMax
		    set complexCorr [$systemMinimizedSel get {x y z}]; list
		    $systemMinimizedSel frame $frame
		    $systemMinimizedSel set {x y z} $complexCorr
#delete attached elite dcd
		    animate delete beg $popMax $systemMinimizedMol
		}
	    }
	}
    }
}

proc ::GOLEM::run::sort_fit {subPopList fitListList {dumpSorted False} {dumpBest 0}} {
#sort fitL and pop accroding to fitL decreasingly
#write the sorted pop into a dcd, using ligandMinimizedMol
    upvar 1 $fitListList fitLL
    upvar 1 $subPopList subPopL
    variable subPopSize
    variable subPopNum
    variable popMax
    variable GAOutDir
    variable round
    variable systemMinimizedMol

    variable MDFFList
    variable energyList
    #variable waterCaliList

    set oldMDFFList $MDFFList
    set oldEnergyList $energyList
    #set oldWaterCaliList $waterCaliList

    if {$dumpBest>$popMax} {set dumpBest $popMax}

    if {$dumpBest>0} {
	set oneFitL [concat {*}$fitLL]
	set sortIndices [lsort -indices -real -decreasing $oneFitL]
	for {set i 0} {$i<$dumpBest} {incr i} {
	    set frame [lindex $sortIndices $i]
	    animate dup frame $frame $systemMinimizedMol
	}
	animate write dcd $GAOutDir/$round.best.system.dcd beg $popMax waitfor all $systemMinimizedMol
	animate delete beg $popMax $systemMinimizedMol
    }
    
    for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
	set sortIndices [lsort -indices -real -decreasing [lindex $fitLL $subPopID]]
	lset fitLL $subPopID [lsort -real -decreasing [lindex $fitLL $subPopID]]	
	set sortedPop [dict create]
	for {set i 0} {$i<$subPopSize} {incr i} {
	    dict set sortedPop $i [dict get $subPopL subPop$subPopID [lindex $sortIndices $i]]
	}
	dict set subPopL subPop$subPopID $sortedPop
#dcd
	for {set i 0} {$i<$subPopSize} {incr i} {
	    set frame [expr $subPopSize*$subPopID+[lindex $sortIndices $i]] 
	    animate dup frame $frame $systemMinimizedMol
	}
#MDFF, energy, waterCali
	for {set i 0} {$i<$subPopSize} {incr i} {
	    set frame [expr $subPopSize*$subPopID+$i] 
	    set frameOld [expr $subPopSize*$subPopID+[lindex $sortIndices $i]] 
	    lset MDFFList $frame [lindex $oldMDFFList $frameOld] 
	    lset energyList $frame [lindex $oldEnergyList $frameOld] 
	    #lset waterCaliList $frame [lindex $oldWaterCaliList $frameOld] 
	}
    }
    animate delete beg 0 end [expr $popMax-1] $systemMinimizedMol
    variable continuousMin
    if {$continuousMin} {set dumpSorted True}
    set dumpSorted True
    if {$dumpSorted} {
	animate write dcd $GAOutDir/$round.sorted.system.dcd waitfor all $systemMinimizedMol
    }
}

proc ::GOLEM::run::best_distinct {subPopList fitListList num} {
    variable subPopSize
    variable supPopNum
    variable popMax
    variable GAOutDir
    variable round
    variable systemMinimizedMol
    #variable eliteRoughRMSDCutoff
    variable ligandSimRMSDCutoff
    variable ligandSimRMSDRoughCutoff
    variable ligandSimDisCutoff
    variable ligandSimAngleCutoff
    variable MDFFList
    variable energyList
    #variable waterCaliList
    
    set oneFitL [concat {*}$fitListList]
    set sortIndices [lsort -indices -real -decreasing $oneFitL]
    set groupRef [list]
    set grouped [lrepeat $popMax -1]
    set groupID 0
    set topScoreList [list]
    set topScoreMDFFList [list]
    set topScoreEnergyList [list]
    set topScoreWaterCaliList [list]
    for {set i 0} {$i<$popMax} {incr i} {
	if {[llength $groupRef]>=$num} {break}
	if {[lindex $grouped $i]!=-1} {
	    continue
	}
	lset grouped $i $groupID 
	lappend groupRef $i
	set groupSize 1
	set frame1 [lindex $sortIndices $i]
	animate dup frame $frame1 $systemMinimizedMol
	lappend topScoreList [lindex $oneFitL $frame1]
	lappend topScoreMDFFList [lindex $MDFFList $frame1]
	lappend topScoreEnergyList [lindex $energyList $frame1]
	#lappend topScoreWaterCaliList [lindex $waterCaliList $frame1]
	for {set j [expr $i+1]} {$j<$popMax} {incr j} {
	    if {$j>=$popMax} {continue}
	    if {[lindex $grouped $j]!=-1} {continue}
	    set frame2 [lindex $sortIndices $j]
	    set ligandSim [check_ligand_similarity_RMSD $frame1 $frame2 $ligandSimRMSDRoughCutoff]
	    #set ligandSim [check_ligand_similarity $frame1 $frame2 $ligandSimDisCutoff $ligandSimAngleCutoff]
	    if {$ligandSim==1} {
		lset grouped $j $groupID
	    }
	}
	incr groupID
    }
    animate write dcd $GAOutDir/$round.best_distinct.dcd beg $popMax waitfor all $systemMinimizedMol
    animate delete beg $popMax $systemMinimizedMol
    #return [list $topScoreList $topScoreMDFFList $topScoreEnergyList $topScoreWaterCaliList]
    return [list $topScoreList $topScoreMDFFList $topScoreEnergyList]
}

proc ::GOLEM::run::fetch_total {} {
    variable NAMDlog
    variable popMax
    variable totalEnergyOut
    variable MDFFOut
    variable minStep
    variable round

    #variable energyList
    #variable MDFFList
    
    set energyList [list]
    set MDFFList [list]
    set totalEnergyList [list]
#read total energy; 11th
    for {set i 0} {$i<$popMax} {incr i} {
	set besafe 0
	while {1} {
	    set line [gets $NAMDlog]
	    if { [lindex $line 0]=="ENERGY:" && [lindex $line 1]==$minStep && [llength $line]==16} {
		#puts "PIE $i read"
		lappend totalEnergyList [lindex $line 13]
		lappend MDFFList [lindex $line 9]
		break
	    }
	    if {[eof $NAMDlog]} {
		#puts "PIE sleeping"
		after 1
	    }
	    if {$besafe>100000000} {
		puts "something wrong? long wait for MIN log update"
		break
	    }
	}
    }
    set energyList [vecscale [vecsub $totalEnergyList $MDFFList] -1]
    puts $totalEnergyOut $totalEnergyList
    flush $totalEnergyOut
    puts $MDFFOut $MDFFList
    flush $MDFFOut
    set MDFFList [vecscale $MDFFList -1]
    set totalEnergyList [vecscale $totalEnergyList -1]
   #return these values, instead of changing them, to rewind 
    return [list $totalEnergyList $MDFFList $energyList]
}

proc ::GOLEM::run::tournament {fitL p fold {reverse False}} {
#fitL doesn't need to be sorted; removed individuals have fitness of -Inf
    set size [llength $fitL]
    if {$size<$fold} {set fold $size}
    set selected [list]
    set fitSelected [list]
    for {set i 0} {$i<$fold} {incr i} {
	set rd [expr int(floor(rand()*$size))]
	while {[lindex $fitL $rd]==-Inf || [lsearch $selected $rd]!=-1} {
	    set rd [expr int(floor(rand()*$size))]
	}
	lappend selected $rd
	lappend fitSelected [lindex $fitL $rd]
    }
    set sortIndices [lsort -indices -decreasing -real $fitSelected]
    for {set i 0} {$i<[expr $fold-1]} {incr i} {
	if {[expr rand()]<$p} {
	    if {$reverse} {
		return [lindex $selected [lindex $sortIndices end-$i]]
	    } else {
		return [lindex $selected [lindex $sortIndices $i]]
	    }
	}
    }
    if {$reverse} {
	return [lindex $selected [lindex $sortIndices 0]]
    } else {
	return [lindex $selected [lindex $sortIndices end]]
    }
}

proc ::GOLEM::run::binary_insert {l item} {
    set length [llength $l]
    set left 0
    set right [expr $length-1]
    while {$left<=$right} {
	set mid [expr ($left+$right)/2]
	if {[lindex $l $mid]>$item} {
	    set right [expr $mid-1]
	} else {
	    set left [expr $mid+1]
	}
    }
    return $left
}

proc ::GOLEM::run::group {fitListList} {
    upvar 1 $fitListList fitLL 
    variable nicheCapacity
    variable subPopSize
    variable subPopNum
    variable ligandSimDisCutoff
    variable ligandSimAngleCutoff
    #variable eliteFineRMSDCutoff
    #variable eliteRoughRMSDCutoff
    variable ligandSimRMSDCutoff
    variable ligandSimRMSDRoughCutoff
    variable eliteMaxNum
    variable round
    variable fitSimCutoff

    set eliteListList [list]

    set count 0
    for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
#first, finely group using a large eliteRoughRMSDCutoff
	set fineGroupRef [list]
    	set eliteList [list]
    	set fineGrouped [lrepeat $subPopSize -1]
    	set fineGroupID 0
    	for {set i 0} {$i<$subPopSize} {incr i} {
    	    if {[lindex $fineGrouped $i]!=-1} {
    	        continue
    	    }
    	    lset fineGrouped $i $fineGroupID 
    	    lappend fineGroupRef $i
    	    set groupSize 1
	    set curGroupFrameList [list [expr $subPopSize*$subPopID+$i]];#list of the current group, new members will be appended
    	    for {set j [expr $i+1]} {$j<$subPopSize} {incr j} {
		if {$j>=$subPopSize} {continue}
    	        if {[lindex $fineGrouped $j]!=-1} {
    	    	continue
    	        }
    	        set frame1 [expr $subPopSize*$subPopID+$i]; #ref frame
    	        set frame2 [expr $subPopSize*$subPopID+$j]; #this frame
		set ligandSim [check_ligand_similarity_RMSD $frame1 $frame2 $ligandSimRMSDCutoff]
		#set ligandSim [check_ligand_similarity $frame1 $frame2 $ligandSimDisCutoff $ligandSimAngleCutoff]
		if {$ligandSim!=1} {continue}
		lset fineGrouped $j $fineGroupID 
#exclude (-Inf score) if group is full
		if {$groupSize>=$nicheCapacity} {
		    lset fitLL $subPopID $j -Inf
		    incr count
		    continue
		}
#group not full; check if this frame is similar to other group members in terms of water number and score; if so, give it a pseudo groupID and exclude it (-Inf score); otherwise, add to group, incr groupSize
#after a second thought, I don't think it is useful
		set excludeFlag 0
		#foreach frameInGroup $curGroupFrameList {
		#    set waterSim [check_water_similarity $frameInGroup $frame2]
		#    set fitSim [check_fit_similarity $frameInGroup $frame2 $fitSimCutoff]
		#    if {$waterSim==1 || $fitSim==1} {
		#	set excludeFlag 1
		#	break
		#    }
		#}
		if {$excludeFlag==0} {
		    incr groupSize
		    lappend curGroupFrameList $frame2
		} else {
		    lset fitLL $subPopID $j -Inf
		    incr count
		}
    	    }
    	    incr fineGroupID
    	}

	if {$eliteMaxNum>=1} {lappend eliteList 0}
	set i 1
	while {[llength $eliteList]<$eliteMaxNum && $i<[llength $fineGroupRef]} {
	    set frame1 [expr $subPopSize*$subPopID+[lindex $fineGroupRef $i]]
	    set flag 1
	    for {set j 0} {$j<[llength $eliteList]} {incr j} {
		set frame2 [expr $subPopSize*$subPopID+[lindex $eliteList $j]]
		set ligandSim [check_ligand_similarity_RMSD $frame1 $frame2 $ligandSimRMSDRoughCutoff]
		#set ligandSim [check_ligand_similarity $frame1 $frame2 $ligandSimDisCutoff $ligandSimAngleCutoff]
		if {$ligandSim} {set flag 0}
	    }
	    if {$flag} {
		lappend eliteList [lindex $fineGroupRef $i]
	    }
	    incr i
	}
	lappend eliteListList $eliteList
    }
    puts "round  $round, exclude $count"
    return $eliteListList 
}

proc ::GOLEM::run::evolve {subPopList fitListList eliteListList} {
    variable subPopNum
    variable subPopSize
    variable pList
    set newSubPopList [dict create]
    variable round

    for {set i 0} {$i<$subPopNum} {incr i} {
	set from [expr ($i+1)%$subPopNum]
	dict set newSubPopList subPop$i [evolve_core $i [dict get $subPopList subPop$i] [lindex $eliteListList $i] [lindex $fitListList $i] [lindex $pList $i] $from [dict get $subPopList subPop$from] [lindex $fitListList $from] [lindex $pList $from]]
    }
    return $newSubPopList
}

proc ::GOLEM::run::evolve_core {subPopID subPop eliteList fitL p subPopFromID subPopFrom subPopFromFitL subPopFromP} {
    variable subPopSize
    variable operatorAccuProbList
    set newPop [dict create]
    variable round
    set start 0
    for {set i 0} {$i<[llength $eliteList]} {incr i} {
	dict set newPop $i [dict get $subPop [lindex $eliteList $i]]
    }
    set start [llength $eliteList]
    set end $subPopSize
    for {set i $start} {$i<$end} {incr i} {
	set operatorID [binary_insert $operatorAccuProbList [expr rand()]]
	switch $operatorID {
	    0 {
	    #crossover
		set fatherID [tournament $fitL $p 3]
		set motherID [tournament $fitL $p 3]
		set child [lindex [crossover [dict get $subPop $fatherID] [dict get $subPop $motherID]] 0] 
		#set child [mutate $child]
		dict set newPop $i $child
	    }
	    1 {
	    #mutate  
		set original [tournament $fitL $p 3]
		set mutated [mutate [dict get $subPop $original]]
		dict set newPop $i $mutated
	    }
	    2 {
	    #immigrant
		set immiID [tournament $subPopFromFitL $subPopFromP 3 True]
		#set immiID [tournament $subPopFromFitL $subPopFromP 1]
		dict set newPop $i [dict get $subPopFrom $immiID]
	    }
	}
    }
	
    return $newPop
}

proc ::GOLEM::run::check_ligand_similarity_RMSD {frame1 frame2 cutoff} {
    if {0} {
    variable systemMinimizedLigandSel1
    variable systemMinimizedLigandSel2
    $systemMinimizedLigandSel1 frame $frame1
    $systemMinimizedLigandSel2 frame $frame2
    set ligandRMSD [measure rmsd $systemMinimizedLigandSel1 $systemMinimizedLigandSel2]
    if {$ligandRMSD>$cutoff} {
	return 0
    } else {
	return 1
    }
    }
    variable systemMinimizedLigandNoHSel1
    variable systemMinimizedLigandNoHSel2
    $systemMinimizedLigandNoHSel1 frame $frame1
    $systemMinimizedLigandNoHSel2 frame $frame2
    set ligandRMSD [measure rmsd $systemMinimizedLigandNoHSel1 $systemMinimizedLigandNoHSel2]
    if {$ligandRMSD>$cutoff} {
	return 0
    } else {
	return 1
    }
}


proc ::GOLEM::run::check_ligand_similarity {frame1 frame2 disCutoff angleCutoff} {
    variable systemMinimizedLigandSel1
    variable systemMinimizedLigandSel2
    $systemMinimizedLigandSel1 frame $frame1
    $systemMinimizedLigandSel2 frame $frame2
    set c1 [measure center $systemMinimizedLigandSel1]
    set c2 [measure center $systemMinimizedLigandSel2]
    set dis [veclength [vecsub $c1 $c2]]
    if {$dis>$disCutoff} {
	return 0
    }
    set mat [measure fit $systemMinimizedLigandSel1 $systemMinimizedLigandSel2]
    lassign [matrix_to_axis_angle $mat] axis angle
    if {$angle>$angleCutoff} {
	return 0
    }
    return 1
}

proc ::GOLEM::run::check_water_similarity {frame1 frame2} {
    variable subPopDict
    variable subPopSize
    set subPopID1 [expr $frame1/$subPopSize]
    set subPopID2 [expr $frame2/$subPopSize]
    set i1 [expr $frame1%$subPopSize]
    set i2 [expr $frame2%$subPopSize]
    #set waterNum1 [get_water_num [dict get $subPopDict subPop$subPopID1 $i1]]
    #set waterNum2 [get_water_num [dict get $subPopDict subPop$subPopID2 $i2]]
    #if {$waterNum1==$waterNum2} {
    #    return 1
    #} else {
    #    return 0
    #}
    set gene1 [dict get $subPopDict subPop$subPopID1 $i1]
    set gene2 [dict get $subPopDict subPop$subPopID2 $i2]
    lassign [sort_water $gene1] sortedGene1 gene1waterID
    lassign [sort_water $gene2] sortedGene2 gene2waterID
    if {$gene1waterID==$gene2waterID} {
	return 1
    } else {
	return 0
    }
}

proc ::GOLEM::run::check_fit_similarity {frame1 frame2 cutoff} {
    variable scoreListList
    variable subPopSize
    set subPopID1 [expr $frame1/$subPopSize] 
    set subPopID2 [expr $frame2/$subPopSize]
    set i1 [expr $frame1%$subPopSize]
    set i2 [expr $frame2%$subPopSize]
    set s1 [lindex $scoreListList $subPopID1 $i1]
    set s2 [lindex $scoreListList $subPopID2 $i2]
    if {[expr abs($s1-$s2)]<$cutoff} {
	return 1
    } else {
	return 0
    }
}

proc ::GOLEM::run::gene_to_str {gene} {
    set s [list]
    foreach key [dict keys $gene] {
	lappend s {*}[dict get $gene $key]
    }
    return $s
}

proc ::GOLEM::run::str_to_gene {str} {
#TODO
    variable crystalWaterNum
    variable dihedNum
    variable segmentNum
    set waterNum [expr ([llength $str]-8-$segmentNum-$dihedNum-$crystalWaterNum*4)/7]
    set ligID [lindex $str 0]
    set disArray [lrange $str 1 3]
    set rdAxis [lrange $str 4 6]
    set rdAngle [lindex $str 7]
    dict set tmp ligID $ligID
    dict set tmp ligDisArray $disArray
    dict set tmp ligRdAxis $rdAxis
    dict set tmp ligRdAngle $rdAngle
    for {set i 0} {$i<$segmentNum} {incr i} {
	set segID [lindex $str [expr 8+$i]]
    	dict set tmp segID$i $segID
    }
    for {set i 0} {$i<$dihedNum} {incr i} {
	set ligDihedAngle [lindex $str [expr 8+$segmentNum+$i]]
	dict set tmp ligDihedAngle$i $ligDihedAngle
    }
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
	set start [expr 8+$segmentNum+$dihedNum+4*$i]
	set rdAxis [lrange $str $start [expr $start +2]]
	set rdAngle [lindex $str [expr $start+3]]
	dict set tmp cWatRdAxis$i $rdAxis
	dict set tmp cWatRdAngle$i $rdAngle
    }
    for {set i 0} {$i<$waterNum} {incr i} {
	set start [expr 8+$segmentNum+$dihedNum+$crystalWaterNum*4+$i*7]
	set disArray [lrange $str [expr $start+0] [expr $start+2]]
	set rdAxis [lrange $str [expr $start+3] [expr $start+5]]
	set rdAngle [lindex $str [expr $start+6]]
	dict set tmp watDisArray$i $disArray
	dict set tmp watRdAxis$i $rdAxis
	dict set tmp watRdAngle$i $rdAngle
    }
    return $tmp
}

proc ::GOLEM::run::pair_water {gene1 gene2} {
#use Hungarian algorithm to pair water (reorder them) in gene1 and gene2
#deprecated
    set waterNum1 [get_water_num $gene1]
    set waterNum2 [get_water_num $gene2]
    if {$waterNum1>$waterNum2} {
	set tmp $gene2 
	set gene2 $gene1
	set gene1 $tmp
	set tmp $waterNum2
	set waterNum2 $waterNum1
	set waterNum1 $tmp
    }
#if waterNum1 is 0, there is no need to pair
    if {0} {
    set newGene2 $gene2
    if {0} {
    if {$waterNum1>0} {
#so gene1 is shorter, waterNum1 is smaller
	set disMat [lrepeat $waterNum1 [lrepeat $waterNum2 -1]]
    	for {set i 0} {$i<$waterNum1} {incr i} {
    	    set watDisArray1 [dict get $gene1 watDisArray$i]
    	    for {set j 0} {$j<$waterNum2} {incr j} {
    	        set watDisArray2 [dict get $gene2 watDisArray$j]
    	        set dis [veclength [vecsub $watDisArray1 $watDisArray2]]
    	        lset disMat $i $j $dis
    	    }
    	}
    	lassign [::GOLEM::HungarianAlgorithm::solve $disMat] totDiff disL assignment
	#set assignment [lrepeat $waterNum1 0]
    	for {set i 0} {$i<$waterNum1} {incr i} {
    	    foreach g [list watDisArray watRdAxis watRdAngle] {
		set oldGeneName $g[lindex $assignment $i]
    	        dict set newGene2 $g$i [dict get $gene2 $oldGeneName]
    	        dict set newGene2 $g[lindex $assignment $i] [dict get $gene2 $g$i]
    	    }
    	}
    }
    }
    return [list $gene1 $newGene2]
    }
    if {1} {
	set newGene1 [sort_water $gene1]
	set newGene2 [sort_water $gene2]
	set newGene2 [no_crossover_water $gene2 [expr $waterNum2-$waterNum1]]
	return [list $newGene1 $newGene2]
    }
}

proc ::GOLEM::run::sort_water {gene} {
#sort water in a certain ID order
#ID= xID*yGridCount*zGridCount + yID*zGridCount + zID
#xID = round(xCor)
    variable yGridCount
    variable zGridCount
    if {![info exists yGridCount] || ![info exists zGridCount]} {
	variable disMaxY
	variable disMaxZ
	set yGridCount [expr ceil($disMaxY)*2+1]
	set zGridCount [expr ceil($disMaxZ)*2+1]
    }

    set IDList [list]
    set waterNum [get_water_num $gene]
    for {set i 0} {$i<$waterNum} {incr i} {
	lassign [dict get $gene watDisArray$i] xCor yCor zCor
	set xID [expr round($xCor)]
	set yID [expr round($yCor)]
	set zID [expr round($zCor)]
	set ID [expr $xID*$yGridCount*$zGridCount+$yID*$zGridCount+$zID]
	lappend IDList $ID
    }
    set sortIndices [lsort -indices -increasing -real $IDList]
    set newGene $gene
    for {set i 0} {$i<$waterNum} {incr i} {
	dict set newGene watDisArray$i [dict get $gene watDisArray[lindex $sortIndices $i]]
	dict set newGene watRdAngle$i [dict get $gene watRdAngle[lindex $sortIndices $i]]
	dict set newGene watRdAxis$i [dict get $gene watRdAxis[lindex $sortIndices $i]]
    }
    set sortedID [lsort -increasing -real $IDList]
#make sure no duplicates in sortedID, if so, rename them
    set noDupSortedID [lsort -unique -increasing -real $IDList]
    if {[llength $sortedID]==[llength $noDupSortedID]} {
    } else {
	foreach uniqID $noDupSortedID {
	    set indices [lsearch -all $sortedID $uniqID]
	    if {[llength $indices]==1} {
		continue
	    } else {
		set increment [expr 1.0/[llength $indices]]
		for {set i 1} {$i<[llength $indices]} {incr i} {
		    set newID [expr $uniqID+$increment*$i]
		    set sortedID [lreplace $sortedID [lindex $indices $i] [lindex $indices $i] $newID]
		}
	    }
	}
    }

    return [list $newGene $sortedID]
}   

proc ::GOLEM::run::no_crossover_water {gene number} {
#randomly push $number of water to the end of the gene so that they won't crossover
#deprecated
    set waterNum [get_water_num $gene]
    if {$waterNum<$number} {return}
    set IDList [list]
    for {set i 0} {$i<$waterNum} {incr i} {lappend IDList $i}
    set outIDList [list]
    for {set i 0} {$i<$number} {incr i} {
	set index [expr int(floor(rand()*[llength $IDList]))]
	lappend outIDList [lindex $IDList $index]
	set IDList [lreplace $IDList $index $index]
    }
    set newIDList [concat $IDList $outIDList]
    set newGene $gene
    for {set i 0} {$i<$waterNum} {incr i} {
	dict set newGene watDisArray$i [dict get $gene watDisArray[lindex $newIDList $i]]
	dict set newGene watRdAxis$i [dict get $gene watRdAxis[lindex $newIDList $i]]
	dict set newGene watRdAngle$i [dict get $gene watRdAngle[lindex $newIDList $i]]
    }
    return $newGene
}

#cross over, input two genes, return a child gene
proc ::GOLEM::run::crossover {fatherGene motherGene} {
#sort water, get water ID list
    lassign [sort_water $fatherGene] fatherGene IDList1
    lassign [sort_water $motherGene] motherGene IDList2
    set fatherStr [gene_to_str $fatherGene]
    set motherStr [gene_to_str $motherGene]

#split father and mother gene into three pieces: lig, CW, and water
    variable ligandStrLength
    variable crystalWaterNum
    variable waterMaxNum
    set fatherLigStr [lrange $fatherStr 0 [expr $ligandStrLength-1]]
    set motherLigStr [lrange $motherStr 0 [expr $ligandStrLength-1]]
    set fatherCWStr [lrange $fatherStr $ligandStrLength [expr $ligandStrLength+$crystalWaterNum*4-1]]
    set motherCWStr [lrange $motherStr $ligandStrLength [expr $ligandStrLength+$crystalWaterNum*4-1]]
    set fatherWaterStr [lrange $fatherStr [expr $ligandStrLength+$crystalWaterNum*4] end]
    set motherWaterStr [lrange $motherStr [expr $ligandStrLength+$crystalWaterNum*4] end]
    #pick at least one piece to crossover
    if {0} {
    variable nicheCapacity
    if {$waterMaxNum>0 && $nicheCapacity>1} {
	if {$crystalWaterNum!=0} {
    	    set crossed 0
    	    while {$crossed==0} {
    	        if {[expr rand()]<0.5} {
    	            #lassign [crossover_two_string [list $fatherLigStr $motherLigStr] max True ] ligStr1 ligStr2
    	            lassign [crossover_two_string [list $fatherLigStr $motherLigStr] 1] ligStr1 ligStr2
    	            set crossed 1
    	        } else {
    	            set ligStr1 $fatherLigStr
    	            set ligStr2 $motherLigStr
    	        }
    	        if {[expr rand()]<0.5} {
    	            lassign [crossover_two_string [list $fatherCWStr $motherCWStr] 1] CWStr1 CWStr2
    	            #lassign [crossover_two_string [list $fatherCWStr $motherCWStr] max True] CWStr1 CWStr2
    	            set crossed 1
    	        } else {
    	    	set CWStr1 $fatherCWStr
    	    	set CWStr2 $motherCWStr
    	        }
    	        if {[expr rand()]<0.5} {
    	    	lassign [crossover_water [list $fatherWaterStr $motherWaterStr] [list $IDList1 $IDList2]] waterStr1 waterStr2
    	            set crossed 1
    	        } else {
    	    	set waterStr1 $fatherWaterStr
    	    	set waterStr2 $motherWaterStr
    	        }
    	    }
    	} else {
    	    set crossed 0
    	    lassign [crossover_two_string [list $fatherCWStr $motherCWStr] 1] CWStr1 CWStr2
    	    #lassign [crossover_two_string [list $fatherCWStr $motherCWStr] max True] CWStr1 CWStr2
    	    while {$crossed==0} {
    	        if {[expr rand()]<0.5} {
    	            lassign [crossover_two_string [list $fatherLigStr $motherLigStr] max True ] ligStr1 ligStr2
    	            set crossed 1
    	        } else {
    	            set ligStr1 $fatherLigStr
    	            set ligStr2 $motherLigStr
    	        }
    	        if {[expr rand()]<0.5} {
    	    	lassign [crossover_water [list $fatherWaterStr $motherWaterStr] [list $IDList1 $IDList2]] waterStr1 waterStr2
    	            set crossed 1
    	        } else {
    	    	set waterStr1 $fatherWaterStr
    	    	set waterStr2 $motherWaterStr
    	        }
    	    }
    	}
    } else {
	lassign [crossover_two_string [list $fatherLigStr $motherLigStr] 1] ligStr1 ligStr2
	#lassign [crossover_two_string [list $fatherLigStr $motherLigStr] max True] ligStr1 ligStr2
    	lassign [crossover_two_string [list $fatherCWStr $motherCWStr] 1] CWStr1 CWStr2
    	#lassign [crossover_two_string [list $fatherCWStr $motherCWStr] max True] CWStr1 CWStr2
    	lassign [crossover_water [list $fatherWaterStr $motherWaterStr] [list $IDList1 $IDList2]] waterStr1 waterStr2
    }
    }
    lassign [crossover_two_string [list $fatherLigStr $motherLigStr] 1] ligStr1 ligStr2
    lassign [crossover_two_string [list $fatherCWStr $motherCWStr] 1] CWStr1 CWStr2
    lassign [crossover_water [list $fatherWaterStr $motherWaterStr] [list $IDList1 $IDList2]] waterStr1 waterStr2

    set childStr1 [list {*}$ligStr1 {*}$CWStr1 {*}$waterStr1]
    set childStr2 [list {*}$ligStr2 {*}$CWStr2 {*}$waterStr2]

    set childGene1 [str_to_gene $childStr1]
    set childGene2 [str_to_gene $childStr2]
    if {[expr rand()]<0.5} {
	return [list $childGene1 $childGene2]
    } else {
	return [list $childGene2 $childGene1]
    }
}

proc ::GOLEM::run::crossover_water {listOfString listOfIDList} {
    lassign $listOfString fatherWaterStr motherWaterStr
    lassign $listOfIDList fatherWaterIDList motherWaterIDList

    set jointIDList [lsort -unique -increasing [concat {*}$fatherWaterIDList {*}$motherWaterIDList]]
    set occuList1 [list]
    set occuList2 [list]
    set waterNum1 0
    set waterNum2 0
    foreach ID $jointIDList {
	if {[lsearch $fatherWaterIDList $ID]==-1} {
	    lappend occuList1 -1
	} else {
	    lappend occuList1 $waterNum1
	    incr waterNum1
	}
	if {[lsearch $motherWaterIDList $ID]==-1} {
	    lappend occuList2 -1
	} else {
	    lappend occuList2 $waterNum2
	    incr waterNum2
	}
    }
#check if water number in any child gene exceeds waterMaxNum
    variable waterMaxNum
    set safe 0
    while {!$safe} {
	set bkp1 [expr int(floor(rand()*([llength $jointIDList]+1)))]
    	set bkp2 [expr int(floor(rand()*([llength $jointIDList]+1)))]
    	lassign [lsort -increasing -real [list $bkp1 $bkp2]] bkp1 bkp2
	#two bkp split occuList into three pieces, the 2nd piece is to swap	
    	set fatherOccuPart1 [lsearch -all -inline -not -exact [lrange $occuList1 0 [expr $bkp1-1]] -1]
    	#set fatherOccuPart2 [lsearch -all -inline -not -exact [lrange $occuList1 $bkp1 [expr $bkp2-1]] -1]
    	set fatherOccuPart2 [lsearch -all -inline -not -exact [lrange $occuList1 $bkp1 end] -1]
    	#set fatherOccuPart3 [lsearch -all -inline -not -exact [lrange $occuList1 $bkp2 end] -1]
    	set motherOccuPart1 [lsearch -all -inline -not -exact [lrange $occuList2 0 [expr $bkp1-1]] -1]
    	#set motherOccuPart2 [lsearch -all -inline -not -exact [lrange $occuList2 $bkp1 [expr $bkp2-1]] -1]
    	set motherOccuPart2 [lsearch -all -inline -not -exact [lrange $occuList2 $bkp1 end] -1]
    	#set motherOccuPart3 [lsearch -all -inline -not -exact [lrange $occuList2 $bkp2 end] -1]
    	lassign [crossover_two_waterpiece [list $fatherWaterStr $fatherOccuPart1] [list $motherWaterStr $motherOccuPart1]] child1Part1 child2Part1
    	lassign [crossover_two_waterpiece [list $fatherWaterStr $fatherOccuPart2] [list $motherWaterStr $motherOccuPart2]] child1Part2 child2Part2
    	#lassign [crossover_two_waterpiece [list $fatherWaterStr $fatherOccuPart3] [list $motherWaterStr $motherOccuPart3]] child1Part3 child2Part3
	#combine, 2nd part swapped
    	#set child1 [concat {*}$child1Part1 {*}$child2Part2 {*}$child1Part3]
    	set child1 [concat {*}$child1Part1 {*}$child2Part2]
    	#set child2 [concat {*}$child2Part1 {*}$child1Part2 {*}$child2Part3]
    	set child2 [concat {*}$child2Part1 {*}$child1Part2]
	if {[llength $child1]<=[expr $waterMaxNum*7] && [llength $child2]<=[expr $waterMaxNum*7]} {
	    set safe 1
	}
    }
    return [list $child1 $child2]
}

proc ::GOLEM::run::crossover_two_waterpiece {father mother} {
#given father's and mother's water string and indices of taken water
    lassign $father fatherWaterStr fatherOccu
    lassign $mother motherWaterStr motherOccu
#swap if needed to make mother the longer one; swap back when return if did
    set swapped 0
    if {[llength $fatherOccu]>[llength $motherOccu]} {
	set tmp $motherWaterStr
	set motherWaterStr $fatherWaterStr
	set fatherWaterStr $tmp
	set tmp $motherOccu
	set motherOccu $fatherOccu
	set fatherOccu $tmp
	set swapped 1
    }
    set child1 [list]
    foreach ID $fatherOccu {
	lappend child1 [lrange $fatherWaterStr [expr $ID*7] [expr ($ID+1)*7-1]]
    }
    set child1 [concat {*}$child1]
    set startID [expr int(floor(rand()*([llength $motherOccu]-[llength $fatherOccu]+1)))]
    set child2Part1 [list]
    for {set i 0} {$i<$startID} {incr i} {
	set ID [lindex $motherOccu $i]
	lappend child2Part1 [lrange $motherWaterStr [expr $ID*7] [expr ($ID+1)*7-1]]
    }
    set child2Part1 [concat {*}$child2Part1]
    set child2Part2 [list]
    for {set i $startID} {$i<[expr $startID+[llength $fatherOccu]]} {incr i} {
	set ID [lindex $motherOccu $i]
	lappend child2Part2 [lrange $motherWaterStr [expr $ID*7] [expr ($ID+1)*7-1]]
    }
    set child2Part2 [concat {*}$child2Part2]
    set child2Part3 [list]
    for {set i [expr $startID+[llength $fatherOccu]]} {$i<[llength $motherOccu]} {incr i} {
	set ID [lindex $motherOccu $i]
	lappend child2Part3 [lrange $motherWaterStr [expr $ID*7] [expr ($ID+1)*7-1]]
    }
    set child2Part3 [concat {*}$child2Part3]
    #lassign [crossover_two_string [list $child1 $child2Part2] max True] child1 child2Part2
    lassign [crossover_two_string [list $child1 $child2Part2] 1] child1 child2Part2

    set child2 [concat {*}$child2Part1 {*}$child2Part2 {*}$child2Part3]
    if {$swapped} {
	return [list $child2 $child1]
    } else {
	return [list $child1 $child2]
    }
}

proc ::GOLEM::run::crossover_two_string {listOfString numBreakPoints {random False}} {
#crossover two input string using n-point crossover
    if {[llength $listOfString]!=2} {return}
    set fatherStr [lindex $listOfString 0]
    set motherStr [lindex $listOfString 1]
    set commonGeneLength [::tcl::mathfunc::min [llength $fatherStr] [llength $motherStr]]
    if {$numBreakPoints=="max"} {set numBreakPoints [expr $commonGeneLength-1]}
    if {$commonGeneLength<=$numBreakPoints} {return $listOfString}
    if {$numBreakPoints<1} {return $listOfString}

    set breakPointList [list]
    for {set i 0} {$i<$numBreakPoints} {incr i} {
	set flag 1
	while {$flag} {
	    set tmp [expr int(floor(rand()*($commonGeneLength-1)))]
	    if {[lsearch $breakPointList $tmp]==-1} {
		lappend breakPointList $tmp 
		set flag 0
	    }
	}
    }
    set breakPointList [lsort -increasing -real $breakPointList]
    set childStr1 [lrange $fatherStr 0 [lindex $breakPointList 0]]
    set childStr2 [lrange $motherStr 0 [lindex $breakPointList 0]]
    set flag 1
    for {set i 1} {$i<$numBreakPoints} {incr i} {
	set fp [lrange $fatherStr [expr [lindex $breakPointList [expr $i-1]]+1] [lindex $breakPointList $i]]
	set mp [lrange $motherStr [expr [lindex $breakPointList [expr $i-1]]+1] [lindex $breakPointList $i]]
	if {$random==False} {
	    if {$flag} {
	        set childStr1 [list {*}$childStr1 {*}$mp]
	        set childStr2 [list {*}$childStr2 {*}$fp]
	        set flag 0
	    } else {
	        set childStr1 [list {*}$childStr1 {*}$fp]
	        set childStr2 [list {*}$childStr2 {*}$mp]
	        set flag 1
	    }
	} else {
	    if {[expr rand()]<0.5} {
	        set childStr1 [list {*}$childStr1 {*}$mp]
	        set childStr2 [list {*}$childStr2 {*}$fp]
	    } else {
	        set childStr1 [list {*}$childStr1 {*}$fp]
	        set childStr2 [list {*}$childStr2 {*}$mp]
	    }
	}
    }
    set fp [lrange  $fatherStr [expr [lindex $breakPointList end]+1] [expr [llength $fatherStr]-1]]
#motherStr is longer
    #set mp [lrange  $motherStr [expr [lindex $breakPointList end]+1] [expr $commonGeneLength-1]]
    set mp [lrange  $motherStr [expr [lindex $breakPointList end]+1] [expr [llength $motherStr]-1]]
    if {$flag} {
        set childStr1 [list {*}$childStr1 {*}$mp]
        set childStr2 [list {*}$childStr2 {*}$fp]
    } else {
        set childStr1 [list {*}$childStr1 {*}$fp]
        set childStr2 [list {*}$childStr2 {*}$mp]
    }
    if {[expr rand()]<0.5} {
	return [list $childStr1 $childStr2]
    } else {
	return [list $childStr2 $childStr1]
    }
}

#input an oldGene, mutate, return a new gene
proc ::GOLEM::run::mutate {gene} {
#TODOTODO
    variable ligandLibOriSize
    variable segmentLibUniqIDListList
    variable bindingsiteCenter
    variable disMaxX
    variable disMaxY
    variable disMaxZ
    variable M_PI
    variable dihedNum
    variable segmentNum
    variable waterMaxNum
    variable crystalWaterNum
    variable mutateKeywordCandidateList
    variable minorGeneMutateRate
    set mutateKeyList [list]
    variable round

    set waterNum [get_water_num $gene]
    set myKeyCandidateList $mutateKeywordCandidateList
#never change water number
    #if {$waterMaxNum>0} {
    #    if {$waterNum==0} {
    #	    lappend myKeyCandidateList addWater
    #	} elseif {$waterNum==$waterMaxNum} {
    #	    lappend myKeyCandidateList deleteWater
    #	} else {
    #	    lappend myKeyCandidateList deleteWater
    #	    lappend myKeyCandidateList addWater
    #	}
    #}

    #while {[llength $mutateKeyList]==0} {
    #foreach key $myKeyCandidateList {
    #	if {[expr rand()]<[expr 1.0/[llength $myKeyCandidateList]]} {
    #	    if {[lsearch $mutateKeyList $key]<0} {
    #	    lappend mutateKeyList $key
    #	    }
    #	}
    #}
    #}

    foreach key $myKeyCandidateList {
    	if {[expr rand()]<$minorGeneMutateRate} {
    	    if {[lsearch $mutateKeyList $key]<0} {
		lappend mutateKeyList $key
    	    }
    	}
    }

    set oldWaterNum $waterNum
    if {[lsearch $mutateKeyList deleteWater]>=0} {
	set oldWaterNum [expr $waterNum-1]
    }
    for {set i 0} {$i<$oldWaterNum} {incr i} {
	if {[expr rand()]<$minorGeneMutateRate} {
	    lappend mutateKeyList watDisArray$i
	}
	if {[expr rand()]<$minorGeneMutateRate} {
	    lappend mutateKeyList watRotate$i
	}
    }
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
	if {[expr rand()]<$minorGeneMutateRate} {
	    lappend mutateKeyList cWatRotate$i
	}
    }
    if {[lsearch $mutateKeyList ligID]>=0} {
	set oldLigID [dict get $gene ligID]
	set newLigID [expr int(floor(rand()*$ligandLibOriSize))]
	dict set gene ligID $newLigID
    }
    if {[lsearch $mutateKeyList ligDisArray]>=0} {
    	set oldDisplacementArray [dict get $gene ligDisArray]
    	lassign $oldDisplacementArray oldx oldy oldz
    	set withinFlag 0
    	while {!$withinFlag} {
    	    set dx [expr tan($M_PI*(rand()-0.5))*$disMaxX/10]
    	    set dy [expr tan($M_PI*(rand()-0.5))*$disMaxY/10]
    	    set dz [expr tan($M_PI*(rand()-0.5))*$disMaxZ/10]
    	    #set dx [expr (rand()-0.5)*2*$disMaxX]
    	    #set dy [expr (rand()-0.5)*2*$disMaxY]
    	    #set dz [expr (rand()-0.5)*2*$disMaxZ]
    	    set newDisplacementArray [vecadd [list $dx $dy $dz] $oldDisplacementArray]
    	    lassign $newDisplacementArray newx newy newz
    	    if {[expr abs($newx)]<$disMaxX && [expr abs($newy)]<$disMaxY && [expr abs($newz)]<$disMaxZ} {set withinFlag 1}
    	}
    	dict set gene ligDisArray $newDisplacementArray
    }
    if {[lsearch $mutateKeyList ligRotate]>=0} {
    	set oldRandomAxis [dict get $gene ligRdAxis]
    	set oldRandomAngle [dict get $gene ligRdAngle]
    	set randomAxis [list [expr rand()] [expr rand()] [expr rand()]];
    	set randomAngle [expr tan($M_PI*(rand()-0.5))*180/10]
    	#set randomAngle [expr (rand()-0.5)*2*180]
    	set oldRotationMatrix [transabout $oldRandomAxis $oldRandomAngle]
    	set newRotationMatrix [transmult [transabout $randomAxis $randomAngle] $oldRotationMatrix]
    	lassign [matrix_to_axis_angle $newRotationMatrix] newRandomAxis newRandomAngle
    	dict set gene ligRdAxis $newRandomAxis
    	dict set gene ligRdAngle $newRandomAngle
    }

    for {set i 0} {$i<$segmentNum} {incr i} {
	if {[lsearch $mutateKeyList segID$i]>=0} {
    	    set oldSegID [dict get $gene segID$i]
	    set uniqIDList [lindex $segmentLibUniqIDListList $i]
    	    set newSegID [random_element $uniqIDList]
    	    dict set gene segID$i $newSegID
    	}
	if {0} {
    	if {[lsearch $mutateKeyList segDisArray$i]>=0} {
    	    set oldDisplacementArray [dict get $gene segDisArray$i]
    	    lassign $oldDisplacementArray oldx oldy oldz
    	    set withinFlag 0
    	    while {!$withinFlag} {
    	        #set dx [expr tan($M_PI*(rand()-0.5))*$disMaxX/10]
    	        #set dy [expr tan($M_PI*(rand()-0.5))*$disMaxY/10]
    	        #set dz [expr tan($M_PI*(rand()-0.5))*$disMaxZ/10]
    	        set dx [expr (rand()-0.5)*2*$disMaxX/10]
    	        set dy [expr (rand()-0.5)*2*$disMaxY/10]
    	        set dz [expr (rand()-0.5)*2*$disMaxZ/10]
    	        set newDisplacementArray [vecadd [list $dx $dy $dz] $oldDisplacementArray]
    	        lassign $newDisplacementArray newx newy newz
    	        if {[expr abs($newx)]<$disMaxX && [expr abs($newy)]<$disMaxY && [expr abs($newz)]<$disMaxZ} {set withinFlag 1}
    	    }
    	    dict set gene segDisArray$i $newDisplacementArray
    	}
    	if {[lsearch $mutateKeyList segRotate$i]>=0} {
    	    set oldRandomAxis [dict get $gene segRdAxis$i]
    	    set oldRandomAngle [dict get $gene segRdAngle$i]
    	    set randomAxis [list [expr rand()] [expr rand()] [expr rand()]];
    	    #set randomAngle [expr tan($M_PI*(rand()-0.5))*180/10]
    	    set randomAngle [expr (rand()-0.5)*2*30]
    	    set oldRotationMatrix [transabout $oldRandomAxis $oldRandomAngle]
    	    set newRotationMatrix [transmult [transabout $randomAxis $randomAngle] $oldRotationMatrix]
    	    lassign [matrix_to_axis_angle $newRotationMatrix] newRandomAxis newRandomAngle
    	    dict set gene segRdAxis$i $newRandomAxis
    	    dict set gene segRdAngle$i $newRandomAngle
    	}
	}
    }
    for {set i 0} {$i<$dihedNum} {incr i} {
	if {[lsearch $mutateKeyList ligDihedAngle$i]>=0} {
	    set oldAngle [dict get $gene ligDihedAngle$i]
	    set change [expr tan($M_PI*(rand()-0.5))*180/10]
	    #set change [expr (rand()-0.5)*2*180]
	    set tmp [expr $oldAngle+$change]
	    set newAngle [expr $tmp-360*(int($tmp+180)/360)]
	    dict set gene ligDihedAngle$i $newAngle
	}
    }
#delete and add water 
    if {[lsearch $mutateKeyList deleteWater]>=0} {
	set delWatID [expr int(floor(rand()*$waterNum))]
	set startIndex [expr 8+$segmentNum+$dihedNum+$crystalWaterNum*4+$delWatID*7]
	set str [gene_to_str $gene]
	set str [lreplace $str $startIndex [expr $startIndex+6]]
	set gene [str_to_gene $str]
    }
    if {[lsearch $mutateKeyList addWater]>=0} {
	set newWatID [get_water_num $gene]
	set dx [expr (rand()-0.5)*2*$disMaxX]
	set dy [expr (rand()-0.5)*2*$disMaxY]
	set dz [expr (rand()-0.5)*2*$disMaxZ]
	set displacementArray [list $dx $dy $dz]
	#set displacementArray [roll_water_location]
	set randomAxis [list [expr rand()] [expr rand()] [expr rand()]]
	set randomAngle [expr rand()*360]
	dict set gene watDisArray$newWatID $displacementArray
	dict set gene watRdAxis$newWatID $randomAxis
	dict set gene watRdAngle$newWatID $randomAngle
    }
#mutate disArray or rotation for old water
    for {set i 0} {$i<$oldWaterNum} {incr i} {
	if {[lsearch $mutateKeyList watDisArray$i]>=0} {
	    set oldDisplacementArray [dict get $gene watDisArray$i]
	    lassign $oldDisplacementArray oldx oldy oldz
	    set withinFlag 0
	    set count 0
	    while {!$withinFlag} {
		 set dx [expr tan($M_PI*(rand()-0.5))*$disMaxX/10]
		 set dy [expr tan($M_PI*(rand()-0.5))*$disMaxY/10]
		 set dz [expr tan($M_PI*(rand()-0.5))*$disMaxZ/10]
		 #set dx [expr (rand()-0.5)*2*$disMaxX]
		 #set dy [expr (rand()-0.5)*2*$disMaxY]
		 #set dz [expr (rand()-0.5)*2*$disMaxZ]
		 set newDisplacementArray [vecadd [list $dx $dy $dz] $oldDisplacementArray]
		 lassign $newDisplacementArray newx newy newz
		 if {[expr abs($newx)]<$disMaxX && [expr abs($newy)]<$disMaxY && [expr abs($newz)]<$disMaxZ} {set withinFlag 1}
		 incr count
		 if {$count>100} {puts "something wrong? $oldDisplacementArray"}
	    }
	    dict set gene watDisArray$i $newDisplacementArray
	}
	if {[lsearch $mutateKeyList watRotate$i]>=0} {
	    set oldRandomAxis [dict get $gene watRdAxis$i]
	    set oldRandomAngle [dict get $gene watRdAngle$i]
	    set randomAxis [list [expr rand()] [expr rand()] [expr rand()]];
    	    #set randomAngle [expr (rand()-0.5)*2.0*$mutateRotateMax]
	    set randomAngle [expr tan($M_PI*(rand()-0.5))*180/10]
	    #set randomAngle [expr (rand()-0.5)*2*180]
    	    set oldRotationMatrix [transabout $oldRandomAxis $oldRandomAngle]
    	    set newRotationMatrix [transmult [transabout $randomAxis $randomAngle] $oldRotationMatrix]
	    lassign [matrix_to_axis_angle $newRotationMatrix] newRandomAxis newRandomAngle
	    dict set gene watRdAxis$i $newRandomAxis
	    dict set gene watRdAngle$i $newRandomAngle
	}
    }
    for {set i 0} {$i<$crystalWaterNum} {incr i} {
	if {[lsearch $mutateKeyList cWatRotate$i]>=0} {
	    set oldRandomAxis [dict get $gene cWatRdAxis$i]
	    set oldRandomAngle [dict get $gene cWatRdAngle$i]
	    set randomAxis [list [expr rand()] [expr rand()] [expr rand()]];
    	    #set randomAngle [expr (rand()-0.5)*2.0*$mutateRotateMax]
	    set randomAngle [expr tan($M_PI*(rand()-0.5))*180/10]
	    #set randomAngle [expr (rand()-0.5)*2*180]
    	    set oldRotationMatrix [transabout $oldRandomAxis $oldRandomAngle]
    	    set newRotationMatrix [transmult [transabout $randomAxis $randomAngle] $oldRotationMatrix]
	    lassign [matrix_to_axis_angle $newRotationMatrix] newRandomAxis newRandomAngle
	    dict set gene cWatRdAxis$i $newRandomAxis
	    dict set gene cWatRdAngle$i $newRandomAngle
	}
    }
    return $gene
}

proc ::GOLEM::run::pop_to_dcd {subPopDict {eliteListList {}}} {
    variable subPopSize
    variable subPopNum
    variable bindingsiteCenter
    variable ligandLibSel
    variable segmentLibMolSel1List
    variable segmentNum
#TODO
    variable systemLigandSel
    variable systemSegmentSelList
    variable segmentIndexList
    variable systemMol
    variable GAOutDir
    variable round
    variable systemWaterSelList
    variable waterMaxNum
    variable disMaxX
    variable disMaxY
    variable disMaxZ
    variable waterCorRef
    variable waterCenter
    variable crystalWaterNum
    variable systemCrystalWaterSelList
    variable crystalWaterCorRefList
    variable crystalWaterOxygenCorList
    variable dihedNum
    variable dihedList
    variable systemMolRotateGroupSelList
    variable systemMolBondSelList
    variable popMax
    variable round
    variable continuousMin
    variable systemPortSelList
    variable segmentLibMolPortSel1List

    set complexDcdFileName $GAOutDir/$round.system.dcd

    for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
	set curSubPop [dict get $subPopDict subPop$subPopID]
	if {[llength [concat {*}$eliteListList]]==0} {
	    set eliteNum 0
	} else {
	    set eliteNum [llength [lindex $eliteListList $subPopID]]
	}
	for {set i 0} {$i<$subPopSize} {incr i} {
	    set frame [expr $i+$subPopID*$subPopSize]
#move lig
	    set ligandConfID [dict get $curSubPop $i ligID]
	    set displacementArray [dict get $curSubPop $i ligDisArray]
	    set randomAxis [dict get $curSubPop $i ligRdAxis]
	    set randomAngle [dict get $curSubPop $i ligRdAngle]
	    set rotationMatrix [transabout $randomAxis $randomAngle]
	    $ligandLibSel frame $ligandConfID
	    $systemLigandSel frame $frame
	    $systemLigandSel set {x y z} [$ligandLibSel get {x y z}]
	    $systemLigandSel move $rotationMatrix
	    $systemLigandSel moveby $bindingsiteCenter
	    $systemLigandSel moveby $displacementArray
	    #change segment conformation
	    for {set seg 0} {$seg<$segmentNum} {incr seg} {
		set segSel [lindex $systemSegmentSelList $seg]
		$segSel frame $frame
		set refSel [lindex $segmentLibMolSel1List $seg]
		$refSel frame [dict get $curSubPop $i segID$seg]

		set indexList [lindex $segmentIndexList $seg]
		if {[llength $indexList]==3} {
		    set mat1 [three_atoms_align [$refSel get {x y z}] [$segSel get {x y z}]]
		} else {
		    set mat1 [measure fit $refSel $segSel]
		}
		#$segSel set {x y z} [$refSel get {x y z}];list
		#$segSel move $mat
		set refOriCor [$refSel get {x y z}]; list
		$refSel move $mat1 ;#remember to set it back

		set portSel [lindex $systemPortSelList $seg]
		$portSel frame $frame
		set portRefSel [lindex $segmentLibMolPortSel1List $seg]
		$portRefSel frame [dict get $curSubPop $i segID$seg]
		if {[$portSel num]==3} {
		    set mat2 [three_atoms_align [$portRefSel get {x y z}] [$portSel get {x y z}]]
		} else {
		    set mat2 [measure fit $portRefSel $portSel]
		}
		#$segSel move $mat
		$refSel set {x y z} $refOriCor
		$segSel set {x y z} $refOriCor
		$segSel move $mat1
		$segSel move $mat2

	    }
	    for {set j 0} {$j<$dihedNum} {incr j} {
		set targetDihed [dict get $curSubPop $i ligDihedAngle$j]
		set curDihed [measure dihed [lindex $dihedList $j] molid $systemMol frame $frame]
		[lindex [lindex $systemMolBondSelList $j] 0] frame $frame
		[lindex [lindex $systemMolBondSelList $j] 1] frame $frame
		set c1 [lindex [[lindex [lindex $systemMolBondSelList $j] 0] get {x y z}] 0]
		set c2 [lindex [[lindex [lindex $systemMolBondSelList $j] 1] get {x y z}] 0]
		set mat [trans bond $c1 $c2 [expr $targetDihed-$curDihed] deg]
		[lindex $systemMolRotateGroupSelList $j] frame $frame
		[lindex $systemMolRotateGroupSelList $j] move $mat
		set curDihed2 [measure dihed [lindex $dihedList $j] molid $systemMol frame $frame]
	    }
	    if {0} {
	    for {set seg 0} {$seg<$segmentNum} {incr seg} {
		set segID [dict get $curSubPop $i segID$seg]
		set displacementArray [dict get $curSubPop $i segDisArray$seg]
		set randomAxis [dict get $curSubPop $i segRdAxis$seg]
	    	set randomAngle [dict get $curSubPop $i segRdAngle$seg]
	    	set rotationMatrix [transabout $randomAxis $randomAngle]
		set segSel [lindex $systemSegmentSelList $seg]
		$segSel frame $frame
		$segSel move $rotationMatrix
		$segSel moveby [vecscale [measure center $segSel] -1]
		$segSel moveby $bindingsiteCenter
		$segSel moveby $displacementArray
	    }
	    }
	    set outID 0
	    set waterNum [get_water_num [dict get $curSubPop $i]]
	    for {set j 0} {$j<$waterNum} {incr j} {
	        set watSel [lindex $systemWaterSelList $j]
	        $watSel frame $frame
		$watSel set {x y z} $waterCorRef
		#$watSel moveby [vecscale [measure center $watSel weight mass] -1]
		set displacementArray [dict get $curSubPop $i watDisArray$j]
		lassign $displacementArray x y z
		if {[expr abs($x)]>[expr 1.5*$disMaxX] || [expr abs($y)]>[expr 1.5*$disMaxY] || [expr abs($z)]>[expr 1.5*$disMaxZ]} {
		    puts "distant water found during popToDcd, subPop $subPopID, individual $i, water $j"
		}
		set randomAxis [dict get $curSubPop $i watRdAxis$j]
		set randomAngle [dict get $curSubPop $i watRdAngle$j]
		set rotationMatrix [trans center $bindingsiteCenter axis $randomAxis $randomAngle]
		$watSel move $rotationMatrix
		$watSel moveby $displacementArray
	    }
	    set outID 0
	    for {set j $waterNum} {$j<$waterMaxNum} {incr j} {
	        set watSel [lindex $systemWaterSelList $j]
	        $watSel frame $frame
		$watSel set {x y z} $waterCorRef
		$watSel moveby [vecadd $bindingsiteCenter [list [expr ($outID%5)*15] [expr (($outID%25)/5)*15] [expr ($outID/25)*15+$disMaxX+$disMaxY+$disMaxZ+30]]]
		incr outID
	    }
	    for {set j 0} {$j<$crystalWaterNum} {incr j} {
	        set watSel [lindex $systemCrystalWaterSelList $j]
	        $watSel frame $frame
	        $watSel set {x y z} [lindex $crystalWaterCorRefList $j]
	        set randomAxis [dict get $curSubPop $i cWatRdAxis$j]
	        set randomAngle [dict get $curSubPop $i cWatRdAngle$j]
	        set rotationMatrix [trans center [lindex $crystalWaterOxygenCorList $j] axis $randomAxis $randomAngle]
	        $watSel move $rotationMatrix
	    }
	}
    }

    if {$continuousMin && [llength [concat {*}$eliteListList]]!=0} {
	variable eliteMaxNum
	variable systemSel
	variable oriXYZ
	for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
	    for {set i 0} {$i<[llength [lindex $eliteListList $subPopID]]} {incr i} {
		set frameNow [expr $subPopID*$subPopSize+$i]
		set frameBefore [expr $subPopID*$subPopSize+[lindex $eliteListList $subPopID $i]]
		mol addfile $GAOutDir/[expr {$round-1}].sorted.system.dcd first $frameBefore last $frameBefore waitfor all $systemMol 
		$systemSel frame [expr $popMax+$i]
		set tmpXYZ [$systemSel get {x y z}]; list
		$systemSel frame $frameNow
		$systemSel set {x y z} $tmpXYZ
	    }
	    animate delete beg $popMax $systemMol
    	}
    }

    animate write dcd $complexDcdFileName waitfor all $systemMol 

    if {$continuousMin && [llength [concat {*}$eliteListList]]!=0} {
	for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
	    for {set i 0} {$i<$eliteMaxNum} {incr i} {
		set frameNow [expr $subPopID*$subPopSize+$i]
		$systemSel frame $frameNow
		$systemSel set {x y z} $oriXYZ
	    }
    	}
    }
}

proc ::GOLEM::run::save_output {} {
    variable guiMode
    variable outDir
    set statusText "results saved in $outDir/result.tcl"
    if {$guiMode} {
	::GOLEM::gui::update_status_text $statusText
    } else { 
	puts $statusText
    }
    set filename $outDir/result.tcl
    set f [open $filename w]
    foreach v [info vars ::GOLEM::gui::*] {
	if {[info exists $v]} {
	    set l [llength [subst $$v]]
	    if {$l==1} {
		puts $f "set $v [subst $$v]"
	    }
	    if {$l>1} {
		puts $f "set $v {[subst $$v]}"
	    }
	}
    }
    foreach v [info vars ::GOLEM::run::*] {
	if {[info exists $v]} {
	    set l [llength [subst $$v]]
            if {$l==1} {
    	    puts $f "set $v [subst $$v]"
            }
            if {$l>1} {
    	    puts $f "set $v {[subst $$v]}"
            }
	}
    }
    close $f
}

proc ::GOLEM::run::check_distant_water {} {
    variable subPopDict
    variable subPopNum
    variable subPopSize
    variable waterMaxNum
    variable round
    for {set subPopID 0} {$subPopID<$subPopNum} {incr subPopID} {
	for {set i 0} {$i<$subPopSize} {incr i} {
	    for {set j 0} {$j<$waterMaxNum} {incr j} {
		if {[dict exists $subPopDict subPop$subPopID $i watDisArray$j]} {
		    set disArray [dict get $subPopDict subPop$subPopID $i watDisArray$j]
		    lassign $disArray x y z
		    if {[expr abs($z)>20] || [expr abs($y)>20] || [expr abs($x)>20]} {
			puts "$round, subPop$subPopID, ind $i, water $j, $x, $y, $z"
			return
		    }
		}
	    }
	}
    }

}


proc ::GOLEM::run::check_one_distant_water {gene} {
    variable subPopDict
    variable subPopNum
    variable subPopSize
    variable waterMaxNum
    variable round
    for {set j 0} {$j<$waterMaxNum} {incr j} {
	if {[dict exists $gene watDisArray$j]} {
	    set disArray [dict get $gene watDisArray$j]
	    lassign $disArray x y z
	    if {[expr abs($z)>20] || [expr abs($y)>20] || [expr abs($x)>20]} {
	    puts "found distant water, water$j, $x, $y, $z"
	    return
	    }
	}
    }
}

proc ::GOLEM::run::roll_water_location {} {
    variable locationList
    variable locationAccuWeightList
    if {![info exists locationList] || ![info exists locationAccuWeightList]} {
	puts "preparing location weight"
	variable disMaxX
	variable disMaxY
	variable disMaxZ
	variable bindingsiteCenter
	variable ligandPot
	set locationList [list]
	set locationAccuWeightList [list]
	set weightSum 0
	set interval 0.5
	set tmpMol [mol new atoms 1]
	animate dup $tmpMol
	set tmpSel [atomselect $tmpMol all]
	mol addfile $ligandPot $tmpMol
	for {set dx [expr -1*$disMaxX]} {$dx<$disMaxX} {set dx [expr $dx+$interval]} {
	    for {set dy [expr -1*$disMaxY]} {$dy<$disMaxY} {set dy [expr $dy+$interval]} {
		for {set dz [expr -1*$disMaxZ]} {$dz<$disMaxZ} {set dz [expr $dz+$interval]} {
		    set xyz [vecadd [list $dx $dy $dz] $bindingsiteCenter]
		    lappend locationList [list $dx $dy $dz]
		    $tmpSel set x [lindex $xyz 0]
		    $tmpSel set y [lindex $xyz 1]
		    $tmpSel set z [lindex $xyz 2]
		    set weight [expr 1-[$tmpSel get interpvol0]]
		    set weightSum [expr $weight+$weightSum]
		    lappend locationAccuWeightList $weightSum
		}
	    }
	}
	set locationAccuWeightList [vecscale $locationAccuWeightList [expr 1.0/[lindex $locationAccuWeightList end]]]
	$tmpSel delete
	mol delete $tmpMol
    }
    return [lindex $locationList [binary_insert $locationAccuWeightList [expr rand()]]]
}
