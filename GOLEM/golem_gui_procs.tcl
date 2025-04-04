proc ::GOLEM::gui::about {} {
#Help->About
    tk_messageBox -type ok -title "About" -message "Written by Zhiyu Zhao"
}

proc ::GOLEM::gui::how_to_use {} {
#Help->How to use
    tk_messageBox -type ok -title "Usage" -message "Hover mouse over text for information"
}

proc ::GOLEM::gui::open_gui_script {} {
    variable w
#File->Load Gui Status
    set tempFile [tk_getOpenFile -filetypes {{{TCL files} {.tcl}} {{All Files} *}}]
    if  {![string equal $tempFile ""]} {
	::GOLEM::gui::clean
	source $tempFile
    }
    if {[info exists ::GOLEM::run::bestDistinctScoreAll] && [llength $::GOLEM::run::bestDistinctScoreAll]>0} {
	for {set i 0} {$i<[llength $::GOLEM::run::bestDistinctScoreAll]} {incr i} {
	    $w.console.output insert end [list $i {*}[lindex $::GOLEM::run::bestDistinctScoreAll $i]]
	}
    }
}

proc ::GOLEM::gui::save_gui_script {} {
#File->Save Gui Status
    variable w
    set filename [tk_getSaveFile -title "Save script" -defaultextension ".tcl" -parent $w]
    if {$filename==""} {return}
    ::GOLEM::gui::save_gui_script_core $filename
}

proc ::GOLEM::gui::save_gui_script_core {filename} {
    if {$filename==""} {return}
    set f [open $filename w]
    puts $f "package require golem"
    puts $f "global tk_version"
    foreach v $::GOLEM::gui::variableList {
	if {[info exists ::GOLEM::gui::$v]} {
	    set l [llength [subst $[subst ::GOLEM::gui::$v]]]
	    if {$l==1} {
		puts $f "set ::GOLEM::gui::$v [subst $[subst ::GOLEM::gui::$v]]"
	    }
	    if {$l>1} {
		puts $f "set ::GOLEM::gui::$v {[subst $[subst ::GOLEM::gui::$v]]}"
	    }
	}
    }
#also save ::GOLEM::run variables if exist
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
    if {![info exists ::GOLEM::run::bestDistinctScoreAll]} {
	puts $f "if {\!\[info exists tk_version\]} {::GOLEM::run::run}"
    } elseif {[llength $::GOLEM::run::bestDistinctScoreAll]==0} { 
	puts $f "if {\!\[info exists tk_version\]} {::GOLEM::run::run}"
    }
    close $f
}

proc ::GOLEM::gui::is_file {f {extList {}}} {
#check if a file exists and is a file, matching extension if provided as a list
    if {[file exists $f] && [file isfile $f] && [lsearch $extList [file extension $f]]!=-1} {
	return 1
    } else {
	return 0
    }
}

proc ::GOLEM::gui::validate_file {f w} {
#check if a file exists and is a file, color the provided label widget accordingly
    if {[file exists $f] && [file isfile $f]} {
	$w configure -fg black
	return 1
    } else {
	$w configure -fg red
	return 0
    }
}

proc ::GOLEM::gui::show_bindingsite {} {
#visualize the binding site in vmd display
    if {[::GOLEM::gui::sanity_bindingsite]==1} {return}
    set minmax [list $::GOLEM::gui::siteMinX $::GOLEM::gui::siteMinY $::GOLEM::gui::siteMinZ $::GOLEM::gui::siteMaxX $::GOLEM::gui::siteMaxY $::GOLEM::gui::siteMaxZ]
    foreach item $minmax {
	if {$item==""} {return}
    }
    if {([llength $::GOLEM::gui::receptorPDBMol]==0 || [lsearch [molinfo list] $::GOLEM::gui::receptorPDBMol]==-1 || ([llength $::GOLEM::gui::receptorPDBMol]==1 && [lsearch [molinfo list] $::GOLEM::gui::receptorPDBMol]>=0 && [molinfo $::GOLEM::gui::receptorPDBMol get name]!=[file tail $::GOLEM::gui::receptorPDB])) && [llength $::GOLEM::gui::receptorPDB]==1} {
	set ::GOLEM::gui::receptorPDBMol [mol new $::GOLEM::gui::receptorPDB]
	mol rename $::GOLEM::gui::receptorPDBMol [file tail $::GOLEM::gui::receptorPDB]
    }
    if {([llength $::GOLEM::gui::mapMol]==0 || [lsearch [molinfo list] $::GOLEM::gui::mapMol]==-1 || ([llength $::GOLEM::gui::mapMol]==1 && [lsearch [molinfo list] $::GOLEM::gui::mapMol]>=0 && [molinfo $::GOLEM::gui::mapMol get name]!=[file tail $::GOLEM::gui::oriMap])) && [llength $::GOLEM::gui::oriMap]==1} {
	if {[file extension $::GOLEM::gui::oriMap]==".map"} {
	    set ::GOLEM::gui::mapMol [mol new $::GOLEM::gui::oriMap type ccp4]
	} else {
	    set ::GOLEM::gui::mapMol [mol new $::GOLEM::gui::oriMap]
	}
	mol rename $::GOLEM::gui::mapMol [file tail $::GOLEM::gui::oriMap]
    }
    if {[llength $::GOLEM::gui::drawMol]==0 || [lsearch [molinfo list] $::GOLEM::gui::drawMol]==-1} {
	set ::GOLEM::gui::drawMol [mol new]
	mol rename $::GOLEM::gui::drawMol "bindingsite box"
    }
    ::GOLEM::gui::reset_reps

    foreach id [molinfo list] {mol off $id}

    if {[llength $::GOLEM::gui::receptorPDBMol]==1 && [lsearch [molinfo list] $::GOLEM::gui::receptorPDBMol]!=-1} {
	mol top $::GOLEM::gui::receptorPDBMol
	mol on $::GOLEM::gui::receptorPDBMol
	for {set i 0} {$i<[molinfo $::GOLEM::gui::receptorPDBMol get numreps]} {incr i} {
	    mol showrep $::GOLEM::gui::receptorPDBMol $i off
	}
	#this rep show all in receptor pdb as lines
	mol color Name
    	mol representation NewRibbons
    	mol material Opaque
    	mol selection "all"
    	mol addrep $::GOLEM::gui::receptorPDBMol
    	set repid [expr [molinfo $::GOLEM::gui::receptorPDBMol get numreps] -1]
    	set repname [mol repname $::GOLEM::gui::receptorPDBMol $repid]
    	lappend ::GOLEM::gui::reps $::GOLEM::gui::receptorPDBMol
    	lappend ::GOLEM::gui::reps $repname

    	#this rep show binding site residues
	#set ::GOLEM::gui::bindingsiteStr "sidechain and same residue as (x>$::GOLEM::gui::siteMinX and x<$::GOLEM::gui::siteMaxX and y>$::GOLEM::gui::siteMinY and y<$::GOLEM::gui::siteMaxY and z>$::GOLEM::gui::siteMinZ and z<$::GOLEM::gui::siteMaxZ)"
	if {$::GOLEM::gui::bindingsiteStr!=""} {
	   mol color Name
    	   mol representation CPK
    	   mol material Opaque
    	   mol selection $::GOLEM::gui::bindingsiteStr
    	   mol addrep $::GOLEM::gui::receptorPDBMol
    	   set repid [expr [molinfo $::GOLEM::gui::receptorPDBMol get numreps] -1]
    	   set repname [mol repname $::GOLEM::gui::receptorPDBMol $repid]
    	   lappend ::GOLEM::gui::reps $::GOLEM::gui::receptorPDBMol
    	   lappend ::GOLEM::gui::reps $repname
	}
    }

    if {[llength $::GOLEM::gui::mapMol]==1 && [lsearch [molinfo list] $::GOLEM::gui::mapMol]!=-1} {
	mol top $::GOLEM::gui::mapMol
    	mol on $::GOLEM::gui::mapMol 
	for {set i 0} {$i<[molinfo $::GOLEM::gui::mapMol get numreps]} {incr i} {
	    mol showrep $::GOLEM::gui::mapMol $i off
	}
    	#this rep show map
    	mol color Element
    	mol representation Isosurface 0.50000 0 2 1 1 1
    	mol material Opaque
    	mol selection "not resname DUM"
	mol addrep $::GOLEM::gui::mapMol
    	set repid [expr [molinfo $::GOLEM::gui::mapMol get numreps] -1]
    	set repname [mol repname $::GOLEM::gui::mapMol $repid]
    	lappend ::GOLEM::gui::reps $::GOLEM::gui::mapMol
    	lappend ::GOLEM::gui::reps $repname
    }

    mol top $::GOLEM::gui::drawMol
    mol on $::GOLEM::gui::drawMol
    #draw the box
    set pointList [list]
    for {set i 0} {$i<2} {incr i} {
	for {set j 0} {$j<2} {incr j} {
	    for {set k 0} {$k<2} {incr k} {
		set p [list]
		lappend p [lindex $minmax [expr int(0+3*$i)]]
		lappend p [lindex $minmax [expr int(1+3*$j)]]
		lappend p [lindex $minmax [expr int(2+3*$k)]]
		lappend pointList $p
	    }
	}
    }
    set pairs [list {0 1} {0 2} {1 3} {2 3} {0 4} {1 5} {2 6} {3 7} {4 5} {4 6} {5 7} {6 7}]
    foreach pair $pairs {
	lappend ::GOLEM::gui::draws $::GOLEM::gui::drawMol
	lappend ::GOLEM::gui::draws [graphics $::GOLEM::gui::drawMol line [lindex $pointList [lindex $pair 0]] [lindex $pointList [lindex $pair 1]] width 3]
    }
    set center [list [expr ([lindex $minmax 0]+[lindex $minmax 3])/2.0] [expr ([lindex $minmax 1]+[lindex $minmax 4])/2.0] [expr ([lindex $minmax 2]+[lindex $minmax 5])/2.0]]
    display resetview
    molinfo $::GOLEM::gui::drawMol set center [list $center]
    #scale to 0.1
    translate to 0 0 0 
    display update

    return
}

proc ::GOLEM::gui::measure_bindingsite_minmax {} {
#measure the minmax of the provided bindingsite atomselection string
    if {([llength $::GOLEM::gui::receptorPDBMol]==0 || [lsearch [molinfo list] $::GOLEM::gui::receptorPDBMol]==-1 || ([llength $::GOLEM::gui::receptorPDBMol]==1 && [lsearch [molinfo list] $::GOLEM::gui::receptorPDBMol]>=0 && [molinfo $::GOLEM::gui::receptorPDBMol get name]!=[file tail $::GOLEM::gui::receptorPDB])) && [llength $::GOLEM::gui::receptorPDB]==1} {
	set ::GOLEM::gui::receptorPDBMol [mol new $::GOLEM::gui::receptorPDB]
	mol rename $::GOLEM::gui::receptorPDBMol $::GOLEM::gui::receptorPDB
    }
    if {[llength $::GOLEM::gui::receptorPDBMol]==1 && [lsearch [molinfo list] $::GOLEM::gui::receptorPDBMol]!=-1 && $::GOLEM::gui::bindingsiteStr!=""} {
	if {[catch {set tmp [atomselect $::GOLEM::gui::receptorPDBMol $::GOLEM::gui::bindingsiteStr]}]} {
#raise an error if atomselection failed
	    tk_messageBox -icon error -message "Not a valid atomselection string"
	    return
	} else {
	    if {[$tmp num]>0} {
	        lassign [measure minmax $tmp] mins maxs
	        lassign $mins minx miny minz 
	        lassign $maxs maxx maxy maxz
	        set ::GOLEM::gui::siteMinX [format "%.2f" $minx]
	        set ::GOLEM::gui::siteMinY [format "%.2f" $miny]
	        set ::GOLEM::gui::siteMinZ [format "%.2f" $minz]
	        set ::GOLEM::gui::siteMaxX [format "%.2f" $maxx]
	        set ::GOLEM::gui::siteMaxY [format "%.2f" $maxy]
	        set ::GOLEM::gui::siteMaxZ [format "%.2f" $maxz]
	    }
	    $tmp delete
	}
    }
}

proc ::GOLEM::gui::switch_peptide {} {
    variable w
    if {$::GOLEM::gui::isPeptide} {
	$w.ligand.resname.label configure -text "Peptide Seq:"
	$w.ligand.title.build configure -state disabled
	catch {::TKTOOLTIP::balloon $w.ligand.resname.label "Sequence of the peptide ligand in one-letter capital symbols."}
    } else {
	$w.ligand.resname.label configure -text "Lig Resname:"
	$w.ligand.title.build configure -state normal
	catch {::TKTOOLTIP::balloon $w.ligand.resname.label "Resname of the ligand in Charmm36 force filed, or in the provided mol2/psf/topology files."}
    }
    ::GOLEM::gui::check_resname
}

proc ::GOLEM::gui::check_resname {} {
    variable w
    set n $::GOLEM::gui::ligandResnameStr
    #no resname input
    if {$n==""} {
	::GOLEM::gui::need_file mol2 0
	::GOLEM::gui::need_file top 0
	::GOLEM::gui::need_file psf 0
	::GOLEM::gui::need_file pdb 0
	$w.ligand.resname.warning configure -text ""
	grid forget $w.ligand.resname.warning
	return
    }
    #peptide, check if every letter is in the amino acid list
    if  {$::GOLEM::gui::isPeptide==1} {
	::GOLEM::gui::need_file mol2 0
	::GOLEM::gui::need_file top 0
	::GOLEM::gui::need_file psf 0
	::GOLEM::gui::need_file pdb 0
	foreach l [split $n {}] {
	    if {$l!={}} {
		if {[lsearch $::GOLEM::gui::aaResnameList $l]==-1} {
		    $w.ligand.resname.warning configure -text "letter $l is an unknown amino acid"
		    grid $w.ligand.resname.warning -row 1 -column 1 -columnspan 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
		    return 1
		}
	    }
	}
	$w.ligand.resname.warning configure -text ""
	grid forget $w.ligand.resname.warning
	return 0
    }
    #not peptide, check if it is in default charmm top
    if {[lsearch $::GOLEM::gui::topResnameList $n]!=-1} {
	#it is found in default charmm top, then top file and psf file are not needed
	if {[lsearch $::GOLEM::gui::inputPDBResnameList $n]!=-1} {
	    ::GOLEM::gui::need_file mol2 0
	    ::GOLEM::gui::need_file top 0
	    ::GOLEM::gui::need_file psf 0
	    ::GOLEM::gui::need_file pdb 1
	} elseif {[lsearch $::GOLEM::gui::inputMOL2ResnameList $n]!=-1} {
	    ::GOLEM::gui::need_file mol2 1
	    ::GOLEM::gui::need_file top 0
	    ::GOLEM::gui::need_file psf 0
	    ::GOLEM::gui::need_file pdb 0
	} else {
	    $w.ligand.resname.warning configure -text "Please provide a coordinate file (either PDB or MOL2 format) and a topology file (either PSF or TOP/str format) of the ligand.\nEnsure that the ligand's parameter file is included in the Force Field Paramter Files."
	    grid $w.ligand.resname.warning -row 1 -column 1 -columnspan 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
	    ::GOLEM::gui::need_file mol2 1
	    ::GOLEM::gui::need_file top 0
	    ::GOLEM::gui::need_file psf 0
	    ::GOLEM::gui::need_file pdb 1
	    return 2
	}
	$w.ligand.resname.warning configure -text ""
	grid forget $w.ligand.resname.warning
	return 0
    }
    #not peptide, top not found, need user input
    if {[lsearch $::GOLEM::gui::topResnameList $n]==-1} {
	#if ligandMOL2 is read
	if {[lsearch $::GOLEM::gui::inputMOL2ResnameList $n]!=-1} {
	    #input ligand resname is found in the provided ligand mol2 file
	    ::GOLEM::gui::need_file mol2 1
	    ::GOLEM::gui::need_file top 0
	    ::GOLEM::gui::need_file psf 0
	    ::GOLEM::gui::need_file pdb 0
	    $w.ligand.resname.warning configure -text ""
	    grid forget $w.ligand.resname.warning
	    return 0
	}
	#if ligandMOL2 not provided or doesn't contain the required resname, check ligandTOP
	if {[lsearch $::GOLEM::gui::inputTOPResnameList $n]!=-1} {
	    #input ligand resname is found in the provided ligand TOP file
	    #must provide a pdb or mol2 to coordinate the ligand
	    if {[lsearch $::GOLEM::gui::inputPDBResnameList $n]!=-1} {
		#pdb provided
	        ::GOLEM::gui::need_file mol2 0
		::GOLEM::gui::need_file top 0
		::GOLEM::gui::need_file psf 0
	        ::GOLEM::gui::need_file pdb 1
	    } elseif {[lsearch $::GOLEM::gui::inputMOL2ResnameList $n]!=-1} {
		#mol2 provided
	        ::GOLEM::gui::need_file mol2 1
		::GOLEM::gui::need_file top 0
		::GOLEM::gui::need_file psf 0
	        ::GOLEM::gui::need_file pdb 0
	    } else {
	        $w.ligand.resname.warning configure -text "Please provide a coordinate file (either PDB or MOL2 format) and a topology file (either PSF or TOP/str format) of the ligand.\nEnsure that the ligand's parameter file is included in the Force Field Paramter Files"
		grid $w.ligand.resname.warning -row 1 -column 1 -columnspan 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
	        ::GOLEM::gui::need_file mol2 1
		::GOLEM::gui::need_file top 0
		::GOLEM::gui::need_file psf 0
	        ::GOLEM::gui::need_file pdb 1
	        return 3
	    }
	    $w.ligand.resname.warning configure -text ""
	    grid forget $w.ligand.resname.warning
	    return 0
	}
	#required resname not found in MOL2 or TOP file, check PSF
	if {[lsearch $::GOLEM::gui::inputPSFResnameList $n]!=-1} {
	    #input ligand resname is found in the provided ligand PSF file
	    #must provide a pdb or mol2 to coordinate the ligand
	    if {[lsearch $::GOLEM::gui::inputPDBResnameList $n]!=-1} {
		#pdb provided
	        ::GOLEM::gui::need_file mol2 0
		::GOLEM::gui::need_file top 0
		::GOLEM::gui::need_file psf 1
	        ::GOLEM::gui::need_file pdb 1
	    } elseif {[lsearch $::GOLEM::gui::inputMOL2ResnameList $n]!=-1} {
		#mol2 provided
	        ::GOLEM::gui::need_file mol2 1
		::GOLEM::gui::need_file top 0
		::GOLEM::gui::need_file psf 1
	        ::GOLEM::gui::need_file pdb 0
	    } else {
	        $w.ligand.resname.warning configure -text "Please provide a coordinate file (either PDB or MOL2 format) and a topology file (either PSF or TOP/str format) of the ligand.\nEnsure that the ligand's parameter file is included in the Force Field Paramter Files"
		grid $w.ligand.resname.warning -row 1 -column 1 -columnspan 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
	        ::GOLEM::gui::need_file mol2 1
		::GOLEM::gui::need_file top 0
		::GOLEM::gui::need_file psf 1
	        ::GOLEM::gui::need_file pdb 1
	        return 4
	    }
	    $w.ligand.resname.warning configure -text ""
	    grid forget $w.ligand.resname.warning
	    return 0
	}
	#no topology information and no psf, requesting all files
	$w.ligand.resname.warning configure -text "Please provide a coordinate file (either PDB or MOL2 format) and a topology file (either PSF or TOP/str format) of the ligand.\nEnsure th     at the ligand's parameter file is included in the Force Field Paramter Files"
	grid $w.ligand.resname.warning -row 1 -column 1 -columnspan 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
	::GOLEM::gui::need_file mol2 1
	::GOLEM::gui::need_file top 1
	::GOLEM::gui::need_file psf 1
	::GOLEM::gui::need_file pdb 1

	return 5
    }
}

proc ::GOLEM::gui::ready_status {varname args} {
    variable w
    if {$::GOLEM::gui::readyToRun==1} {
	$w.buttons.run configure -state normal
    } else {
	$w.buttons.run configure -state disabled
    }
    update
}

proc ::GOLEM::gui::check_ligand_mol2 {varname args} {
    variable w
    set filename $::GOLEM::gui::ligandMOL2
    set isFile [::GOLEM::gui::is_file $filename {".mol2"}]
    if {$isFile} {
	$w.ligand.additional.mol2.path configure -fg black
	$w.ligand.optional.mol2.path configure -fg black
	$w.ligand.additional.mol2.path configure -fg black
	set tmpmol [mol new $filename]
	set tmpsel [atomselect $tmpmol all]
	set ::GOLEM::gui::inputMOL2ResnameList [lsort -unique [$tmpsel get resname]]
	$tmpsel delete
	mol delete $tmpmol
	::GOLEM::gui::check_resname
    } else {
	$w.ligand.additional.mol2.path configure -fg red
	$w.ligand.optional.mol2.path configure -fg red
	set ::GOLEM::gui::inputMOL2ResnameList ""
    }
}

proc ::GOLEM::gui::check_ligand_pdb {varname args} {
    variable w
    set filename $::GOLEM::gui::ligandPDB
    set isFile [::GOLEM::gui::is_file $filename {".pdb"}]
    if {$isFile} {
	$w.ligand.additional.pdb.path configure -fg black
	$w.ligand.optional.pdb.path configure -fg black
	set tmpmol [mol new $filename]
	set tmpsel [atomselect $tmpmol all]
	set ::GOLEM::gui::inputPDBResnameList [lsort -unique [$tmpsel get resname]]
	$tmpsel delete
	mol delete $tmpmol
	::GOLEM::gui::check_resname
    } else {
	$w.ligand.additional.pdb.path configure -fg red
	$w.ligand.optional.pdb.path configure -fg red
	set ::GOLEM::gui::inputPDBResnameList ""
    }
}

proc ::GOLEM::gui::check_ligand_psf {varname args} {
    variable w
    set filename $::GOLEM::gui::ligandPSF
    set isFile [::GOLEM::gui::is_file $filename {".psf"}]
    if {$isFile} {
	$w.ligand.additional.psf.path configure -fg black
	$w.ligand.optional.psf.path configure -fg black
	set tmpmol [mol new $filename]
	set tmpsel [atomselect $tmpmol all]
	set ::GOLEM::gui::inputPSFResnameList [lsort -unique [$tmpsel get resname]]
	$tmpsel delete
	mol delete $tmpmol
	::GOLEM::gui::check_resname
    } else {
	$w.ligand.additional.psf.path configure -fg red
	$w.ligand.optional.psf.path configure -fg red
	set ::GOLEM::gui::inputPSFResnameList ""
    }
}

proc ::GOLEM::gui::check_ligand_top {varname args} {
    variable w
    set filename $::GOLEM::gui::ligandTOP
    set isFile [::GOLEM::gui::is_file $filename {".top" ".rtf" ".inp" ".str"}]
    if {$isFile} {
	set handler [::Toporead::read_charmm_topology $filename 1]
	set info [::Toporead::topology_from_handler $handler]
	#the 6th item in info is a list of resname
	set resnames [lindex $info 6]
	set ::GOLEM::gui::inputTOPResnameList $resnames
	::GOLEM::gui::check_resname
    } else {
	$w.ligand.additional.top.path configure -fg red
	$w.ligand.optional.top.path configure -fg red
	set ::GOLEM::gui::inputTOPResnameList ""
    }
}

proc ::GOLEM::gui::need_file {name yesno} {
    variable w
#name can be mol2, top, psf, pdb
    set id [lsearch {mol2 top psf pdb} $name]
    if {$id==-1} {return}
    if {$yesno==1} {
	#need it, show it in additional
	grid $w.ligand.additional.$name -row $id -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
	grid forget $w.ligand.optional.$name
    } else {
#not needed, put it in optional
	grid $w.ligand.optional.$name -row $id -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
	grid forget $w.ligand.additional.$name
    }
    update
}

proc ::GOLEM::gui::clean {} {
#set variables to null
    variable w
    foreach v $::GOLEM::gui::variableList {
	set ::GOLEM::gui::$v ""
    }
#also clean ::GOLEM::run variables
#try to terminate namd and close open log files
    catch {::GOLEM::run::terminate}
    catch {close $::GOLEM::run::MDFFout}
    catch {close $::GOLEM::run::totolEnergyOut}
    catch {close $::GOLEM::run::waterCaliOut}
    catch {close $::GOLEM::run::scoreOriOut}
    catch {close $::GOLEM::run::sortOut}
    catch {close $::GOLEM::run::bestOut}
    foreach v [info vars ::GOLEM::run::*] {
	if {[info exists $v]} {
	    unset $v 
	}
    }
    $w.console.output delete 0 end
    set traceInfo [trace info execution ::Molefacture::run_cgenff]
    foreach t $traceInfo {
	trace remove execution ::Molefacture::run_cgenff [lindex $t 0] [lindex $t 1]
    }
    $w.ligand.title.build configure -text "Build Molecule"
    $w.buttons.run config -state disabled
    update_status_text "IDLE"
}

proc ::GOLEM::gui::init {} {
#set variables to defaut values
    ::GOLEM::gui::init_par
    ::GOLEM::gui::init_top
    set ::GOLEM::gui::outDir [pwd]
    #set ::GOLEM::gui::namdBin "namd2"
    if {![catch {which namd2}]} {
	set ::GOLEM::gui::namdBin [which namd2]
    }
    #set ::GOLEM::gui::namdOpt "-gpu +p[::tcl::mathfunc::min [::GOLEM::gui::getProcs] 4]"
    set ::GOLEM::gui::namdOpt " "
    set ::GOLEM::gui::keepCrystalWater 1
    set ::GOLEM::gui::optimizeCrystalWaterOrientation 1
    .golemGui.receptor.input.water.orientation config -state normal
    set ::GOLEM::gui::waterMaxNum 5
    set ::GOLEM::gui::ligandCoupFactor 6
    set ::GOLEM::gui::waterCoupFactor 3
    set ::GOLEM::gui::fixedSidechain 0
    set ::GOLEM::gui::hideOptional 1
    set ::GOLEM::gui::isPeptide 0
    set ::GOLEM::gui::readyToRun 0
}

proc ::GOLEM::gui::refresh {} {
    ::GOLEM::gui::clean
    ::GOLEM::gui::init
    ::GOLEM::gui::check_resname 
}

proc ::GOLEM::gui::reset_reps {} {
    foreach {molid repname} $::GOLEM::gui::reps {
	if { [lsearch [molinfo list] $molid] != -1} {
	    set repid [mol repindex $molid $repname]
	    mol delrep $repid $molid
	}
    }
    set ::GOLEM::gui::reps {}
    foreach {molid drawid} $::GOLEM::gui::draws {
	if { [lsearch [molinfo list] $molid] != -1} {
	    graphics $molid delete $drawid
	}
    }
    set ::GOLEM::gui::draws {}
}

proc ::GOLEM::gui::sanity_bindingsite {} {
    foreach item {::GOLEM::gui::siteMinX ::GOLEM::gui::siteMinY ::GOLEM::gui::siteMinZ ::GOLEM::gui::siteMaxX ::GOLEM::gui::siteMaxY ::GOLEM::gui::siteMaxZ} {
	if {[subst $$item]==""} {
	    tk_messageBox -icon error -message "[string range $item 18 end] is not defined"
	    return 1
	}
    }
    if {$::GOLEM::gui::siteMinX>=$::GOLEM::gui::siteMaxX} {
	tk_messageBox -icon error -message "MinX shoud be smaller than MaxX"
	return 1
    }
    if {$::GOLEM::gui::siteMinY>=$::GOLEM::gui::siteMaxY} {
	tk_messageBox -icon error -message "MinY shoud be smaller than MaxY"
	return 1
    }
    if {$::GOLEM::gui::siteMinZ>=$::GOLEM::gui::siteMaxZ} {
	tk_messageBox -icon error -message "MinZ shoud be smaller than MaxZ"
	return 1
    }
    return 0
}

proc ::GOLEM::gui::sanity_files {} {
    set file $::GOLEM::gui::receptorPDB
    set name "receptor pdb"
#only check when the file extension is .pdb; it could be a pdbid
    if {$file==""} {
	tk_messageBox -icon error -message "Please provide a valid $name file"
	return 1
    }
    if {[file extension $file]!=""} {
	if {[::GOLEM::gui::is_file $file {".pdb"}]} {
	} else {
	    tk_messageBox -icon error -message "Please provide a valid $name file"
	    return 1
	}
    }
    set file $::GOLEM::gui::oriMap
    set name "map"
    if {$file==""} {
	tk_messageBox -icon error -message "Please provide a valid $name file"
	return 1
    }
    if {[::GOLEM::gui::is_file $file {.map .mrc .situs .ccp4 .dx}]} {
    } else {
        tk_messageBox -icon error -message "Please provide a valid $name file"
        return 1
    }
    set fileList [list $::GOLEM::gui::receptorPSF $::GOLEM::gui::ligandPSF $::GOLEM::gui::ligandPDB $::GOLEM::gui::ligandDCD]
    set nameList {"receptor psf" "ligand psf" "ligand pdb" "ligand dcd"}
    set extList {.psf .psf .pdb .dcd}
    foreach file $fileList name $nameList ext $extList {
	if {$file!=""} {
	    if {[::GOLEM::gui::is_file $file [list $ext]]} {
    	    } else {
    	        tk_messageBox -icon error -message "Please provide a valid $name file"
    	        return 2
    	    }
	}
    }
    if {[file exists $::GOLEM::gui::namdBin] && [file executable $::GOLEM::gui::namdBin]} {
    } else {
	tk_messageBox -icon error -message "Please provide the location of NAMD bin"
	return 3
    }
    if {[llength $::GOLEM::gui::parFileList]==0} {
	tk_messageBox -icon error -message "Please provide parameter files to run NAMD!"
	return 4
    }
    return 0
}

proc ::GOLEM::gui::sanity_inputs {} {
    if {[::GOLEM::gui::sanity_bindingsite]!=0} {return 1}
    set varList [list $::GOLEM::gui::ligandCoupFactor $::GOLEM::gui::waterCoupFactor $::GOLEM::gui::waterMaxNum]
    set nameList {"Ligand-map Coupling Facotr" "Water-map Coupling Facotr" "Maximal number of water molecules"}
    foreach var $varList name $nameList {
	if {$var==""} {
	    tk_messageBox -icon error -message "Please specify $name"
	    return 2
	}
	if {$var<0} {
	    tk_messageBox -icon error -message "$name can not be negative"
	    return 2
	}
    }
    return 0
}

proc ::GOLEM::gui::sanity_ligand {} {
    if {$::GOLEM::gui::ligandResnameStr==""} {
	if {$::GOLEM::gui::isPeptide==1} {
	    tk_messageBox -icon error -message "Please provide the sequence of the peptide ligand"
	} else {
	    tk_messageBox -icon error -message "Please provide the resname of the ligand"
	}
	return 1
    }
    return [::GOLEM::gui::check_resname]
}

proc ::GOLEM::gui::prepare {} {
    ::GOLEM::gui::update_status_text "Sanity checking"
    if {[::GOLEM::gui::sanity]!=0} {
	::GOLEM::gui::update_status_text "Sanity check failed"
	return 1
    }
    ::GOLEM::gui::update_status_text "Sanity check passed"
    ::GOLEM::gui::mkdir
    ::GOLEM::gui::generate_receptor_psfpdb
    #::GOLEM::gui::generate_ligand_str
    #::GOLEM::gui::generate_ligand_psfpdb
}

proc ::GOLEM::gui::mkdir {} {
    #remove space in $outDir
    set tmpdir [file dirname $::GOLEM::gui::outDir]
    set tmptail [file tail $::GOLEM::gui::outDir]
    set wd_master [file join $tmpdir [regsub {[ ]} $tmptail {} ]]
    set ::GOLEM::gui::outDir $wd_master
    file mkdir $wd_master
    file mkdir $wd_master/prepare
    file mkdir $wd_master/run
}

proc ::GOLEM::gui::sanity {} {
    if {[::GOLEM::gui::sanity_files]!=0} {return 1}
    ::GOLEM::gui::update_status_text "Required files---ok"
    if {[::GOLEM::gui::sanity_inputs]!=0} {return 2}
    ::GOLEM::gui::update_status_text "Required inputs---ok"
    if {[::GOLEM::gui::sanity_ligand]!=0} {return 3}
    ::GOLEM::gui::update_status_text "Required ligand information---ok"
    return 0
}

proc ::GOLEM::gui::init_par {} {
    global env
    set ::GOLEM::gui::parFileList [glob $env(CHARMMPARDIR)/*36*.prm]
    lappend ::GOLEM::gui::parFileList $env(CHARMMPARDIR)/toppar_water_ions_namd.str
    lappend ::GOLEM::gui::parFileList $env(CHARMMPARDIR)/toppar_all36_carb_glycopeptide.str
}

proc ::GOLEM::gui::init_top {} {
    global env 
    set ::GOLEM::gui::topFileList [glob $env(CHARMMTOPDIR)/*36*]
    lappend ::GOLEM::gui::topFileList $env(CHARMMTOPDIR)/toppar_water_ions_namd.str
    lappend ::GOLEM::gui::topFileList $env(CHARMMTOPDIR)/toppar_all36_carb_glycopeptide.str

    set ::GOLEM::gui::topResnameList {}
    foreach topFile $::GOLEM::gui::topFileList {
	set handler [::Toporead::read_charmm_topology $topFile 1]
	set info [::Toporead::topology_from_handler $handler]
	#the 6th item in info is a list of resname
	set resnames [lindex $info 6]
	lappend ::GOLEM::gui::topResnameList $resnames
    }
    set ::GOLEM::gui::topResnameList [concat {*}$::GOLEM::gui::topResnameList]
}

proc ::GOLEM::gui::getProcs {} {
    global tcl_platform env
    if {$::tcl_platform(os) == "Darwin" } {
	catch {exec sysctl -n hw.ncpu} proce
	return $proce
    } elseif {$::tcl_platform(os) == "Linux" } {
	catch {exec grep -c "model name" /proc/cpuinfo} proce
	return $proce
    } elseif {[string first "Windows" $::tcl_platform(os)] != -1} {
	catch {HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor } proce
	set proce [llength $proce]
	return $proce
    }
}

proc ::GOLEM::gui::call_molefacture_mol2 {{filename ""}} {
    variable w
    if {[$w.ligand.title.build cget -text]=="Build Molecule"} {
	if {![winfo exists .molefac] || ![winfo viewable .molefac]} {
	    catch {::Molefacture::initialize}
	    ::Molefacture::molefacture_gui
	    ::Molefacture::moleculeChanged
	    ::Molefacture::loadDefaulTopo
	    ::Molefacture::setHotKeys
	}
	trace add execution ::Molefacture::run_cgenff leave ::GOLEM::gui::wait_molefacture_mol2
	$w.ligand.title.build configure -text "Get Built Molecule"
	bind .molefac <Unmap> {
	    .golemGui.ligand.title.build configure -text "Build Molecule"
	    trace remove execution ::Molefacture::run_cgenff leave ::GOLEM::gui::wait_molefacture_mol2
	}
	bind .molefac <Destroy> {
	    .golemGui.ligand.title.build configure -text "Build Molecule"
	    trace remove execution ::Molefacture::run_cgenff leave ::GOLEM::gui::wait_molefacture_mol2
	}
	return
    }
    if {[$w.ligand.title.build cget -text]=="Get Built Molecule"} {
	if {[lsearch [molinfo list] $::Molefacture::tmpmolid]!=-1} {
	    ::Molefacture::run_cgenff export
	}
	return
    }
}

proc ::GOLEM::gui::wait_molefacture_mol2 {call code result op} {
    variable w
    if {[file extension $result]==".mol2" && [file exists $result] && [file isfile $result]} {
	set tmpmol [mol new $result]
	set tmpsel [atomselect $tmpmol all]
	if {[$tmpsel num]>0} {
	    set ::GOLEM::gui::ligandResnameStr [lsort -unique [$tmpsel get resname]]
	    set ::GOLEM::gui::ligandMOL2 $result
	    $w.ligand.title.build configure -text "Build Molecule"
	    $w.ligand.resname.warning config -text ""
	    #pretending I'm qmtool
	    ::Molefacture::closeMainWindow export_qmtool
	    trace remove execution ::Molefacture::run_cgenff leave ::GOLEM::gui::wait_molefacture_mol2
	}
	$tmpsel delete
	mol delete $tmpmol
    }
}

proc ::GOLEM::gui::generate_receptor_psfpdb {} {
    if {$::GOLEM::gui::receptorPSF==""} {
    set answer [tk_messageBox -icon question -message "Missing PSF file of the receptor. We will use QwikMD to generate the necessary PSF/PDB files of the receptor. Please follow these steps:" -detail "-Use \"Structure Manipulation\" to correct any erros or warning in the input PDB file.\n-Clike \"Prepare\" in the QwikMD window or \"OK\" button here to proceed.\n-Ensure that the docking ligand is not included in the receptor's structure.\n-Do not alter any other settings." -type okcancel]
    switch $answer {
	cancel {return}
	ok {
	    variable dialogQwikMD [toplevel .golemGui.dialogQwikMD]
	    wm title $dialogQwikMD ""
	    wm resizable $dialogQwikMD 1 1
	    lassign [split [winfo geometry .golemGui] {x +}] sizex sizey x y
	    wm geometry $dialogQwikMD 300x150+[expr int($x+($sizex/2.0)-150)]+[expr int($y+($sizey/2.0)-75)]
	    #in case the dialogQwikMD window is closed by user
	    bind .golemGui.dialogQwikMD <Destroy> {
		::GOLEM::gui::update_status_text "Preparation stopped"
		set traceInfo [trace info execution ::QWIKMD::PrepareBttProc]
		foreach t $traceInfo {
		    trace remove execution ::QWIKMD::PrepareBttProc [lindex $t 0] [lindex $t 1]
		}
	    }
	    frame $dialogQwikMD.window
	    label $dialogQwikMD.window.message -text "Please use QwikMD to generate receptor's psf/pdb?" -wraplength 250
	    button $dialogQwikMD.window.ok -text "Next" -command {
		if {![info exists ::QWIKMD::warnresid] || $::QWIKMD::warnresid!=0} {
		    .golemGui.dialogQwikMD.window.message config -text  "Please use QwikMD to generate the receptor's PSF/PDB files.\nAddress any active errors or warnings using \"Structure Manipulation\".\n-You may click \"Ignore\" to bypass warnings.\n-Ensure to remove the docking ligand if it is present in the structure."
		    update
		} else {
###test1
		    .golemGui.dialogQwikMD.window.ok config -state disabled
		    set ::QWIKMD::basicGui(workdir,0) $::GOLEM::gui::outDir/prepare/receptor.qwikmd
		    ::QWIKMD::PrepareBttProc $::QWIKMD::basicGui(workdir,0)
		}
	    }
	    grid $dialogQwikMD.window.message -row 0 -column 0  -sticky nesw
	    grid $dialogQwikMD.window.ok -row 1 -column 0 -sticky nesw
	    grid $dialogQwikMD.window -row 0 -column 0 -sticky nesw
	    grid columnconfigure $dialogQwikMD 0 -weight 1
	    grid rowconfigure $dialogQwikMD 0 -weight 1
	    grid columnconfigure $dialogQwikMD.window 0 -weight 1
	    grid rowconfigure $dialogQwikMD.window 0 -weight 1
	    ::GOLEM::gui::update_status_text "Generating recpetor psf/pdb"
	    ::QWIKMD::qwikmd
	    set ::QWIKMD::inputstrct $::GOLEM::gui::receptorPDB
	    ::QWIKMD::loadStructGui
	    set ::QWIKMD::basicGui(workdir,0) $::GOLEM::gui::outDir/prepare/receptor.qwikmd
#this trace will call generate_ligand_str when receptor psf/pdb are saved
	    trace add execution ::QWIKMD::PrepareBttProc leave ::GOLEM::gui::wait_qwikmd
	}
    } 
    } else {
#no need to generate receptor psf, go to generate_ligand_str directly
	::GOLEM::gui::generate_ligand_str
    }
#if ::QWIKMD::warnresid is 0, the structure is ready to save
#set ::QWIKMD::basicGui(workdir,0)
}

proc ::GOLEM::gui::wait_qwikmd {call code result op} {
    if {$result==0} {
	#trace remove execution ::QWIKMD::PrepareBttProc leave ::GOLEM::gui::wait_qwikmd
	::GOLEM::gui::alignback_receptor
	::GOLEM::gui::update_status_text "Receptor psf/pdb generated"
	#destroy $::QWIKMD::topGui
	::QWIKMD::closeQwikmd
	destroy .golemGui.dialogQwikMD
	::GOLEM::gui::generate_ligand_str
    } else {
	.golemGui.dialogQwikMD.window.message config -text  "Please use QwikMD to generate receptor's psf/pdb?\nFailed to save receptor's psf/pdb"
    }
}

proc ::GOLEM::gui::alignback_receptor {} {
    puts "start aligning"
    ::GOLEM::gui::update_status_text "Aligning receptor pdb"
    set qwikmdpsf $::GOLEM::gui::outDir/prepare/receptor/run/receptor_QwikMD.psf
    set qwikmdpdb $::GOLEM::gui::outDir/prepare/receptor/run/receptor_QwikMD.pdb
    set qwikmdmol [mol new $qwikmdpsf]
    mol addfile $qwikmdpdb $qwikmdmol
    set pdbmol [mol new $::GOLEM::gui::receptorPDB]
    set qwikmdallsel [atomselect $qwikmdmol all]
    set chains [lsort -unique [$qwikmdallsel get chain]]
#qwikmdpdb should moveby $move to centered back
    set move -1
    foreach chain $chains {
	#try protein CA first 
	puts "trying CA"
	set qwikmdsel [atomselect $qwikmdmol "chain $chain and name CA and protein"]
	set qwikmdselresid [$qwikmdsel get resid];list
	if {[$qwikmdsel num]>0} {
	    set pdbsel [atomselect $pdbmol "chain $chain and name CA and protein and resid $qwikmdselresid"]
	    if {[$qwikmdsel num]>0 && [$qwikmdsel num]==[$pdbsel num]} {
	        set matrix [measure fit $qwikmdsel $pdbsel]
	        if {[::GOLEM::gui::sim_equal [lindex $matrix 0 0] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 1 1] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 2 2] 1]} {
	    	set move [list [lindex $matrix 0 3] [lindex $matrix 1 3] [lindex $matrix 2 3]]
	    	puts "CA aligned"
	    	break
	        }
	    }
	}
	if {$move!=-1} {break}
	#try protein N 
	puts "trying N"
	set qwikmdsel [atomselect $qwikmdmol "chain $chain and name N and protein"]
	set qwikmdselresid [$qwikmdsel get resid];list
	if {[$qwikmdsel num]>0} {
	    set pdbsel [atomselect $pdbmol "chain $chain and name N and protein and resid $qwikmdselresid"]
	    if {[$qwikmdsel num]>0 && [$qwikmdsel num]==[$pdbsel num]} {
	        set matrix [measure fit $qwikmdsel $pdbsel]
	        if {[::GOLEM::gui::sim_equal [lindex $matrix 0 0] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 1 1] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 2 2] 1]} {
	    	set move [list [lindex $matrix 0 3] [lindex $matrix 1 3] [lindex $matrix 2 3]]
	    	break
	        }
	    }
	}
	if {$move!=-1} {break}
	#try nucleic
	puts "trying nucleic"
	set qwikmdsel [atomselect $qwikmdmol "chain $chain and name P and nucleic"]
	set qwikmdselresid [$qwikmdsel get resid];list
	if {[$qwikmdsel num]>0} {
	    set pdbsel [atomselect $pdbmol "chain $chain and name P and nucleic and resid $qwikmdselresid"]
	    if {[$qwikmdsel num]>0 && [$qwikmdsel num]==[$pdbsel num]} {
	        set matrix [measure fit $qwikmdsel $pdbsel]
	        if {[::GOLEM::gui::sim_equal [lindex $matrix 0 0] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 1 1] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 2 2] 1]} {
	    	set move [list [lindex $matrix 0 3] [lindex $matrix 1 3] [lindex $matrix 2 3]]
	    	break
	        }
	    }
	}
	if {$move!=-1} {break}

	puts "align using whatever is similar"
	set qwikmdsel [atomselect $qwikmdmol "chain $chain and name CA and protein"]
	set qwikmdselresid [$qwikmdsel get resid];list
	foreach resid $qwikmdselresid {
	    set pdbsel [atomselect $pdbmol "chain $chain and name CA and protein and resid $resid"]
	    set qwikmdsel [atomselect $qwikmdmol "chain $chain and name CA and protein and resid $resid"]
	    if {[$pdbsel get resname]==[$qwikmdsel get resname]} {
	        set matrix [measure fit $qwikmdsel $pdbsel]
	        if {[::GOLEM::gui::sim_equal [lindex $matrix 0 0] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 1 1] 1] && [::GOLEM::gui::sim_equal [lindex $matrix 2 2] 1]} {
	    	set move [list [lindex $matrix 0 3] [lindex $matrix 1 3] [lindex $matrix 2 3]]
	    	break
		}
	    }
	}
	if {$move!=-1} {break}
    }
    if {$move==-1} {
	tk_messageBox -icon warning -message "Failed to align qwikmd pdb to the input pdb!"
    } else {
	$qwikmdallsel moveby $move
	$qwikmdallsel writepdb $::GOLEM::gui::outDir/prepare/receptor.pdb
	$qwikmdallsel writepsf $::GOLEM::gui::outDir/prepare/receptor.psf
	set ::GOLEM::gui::receptorPDB $::GOLEM::gui::outDir/prepare/receptor.pdb
	set ::GOLEM::gui::receptorPSF $::GOLEM::gui::outDir/prepare/receptor.psf
    }
    $qwikmdsel delete
    $pdbsel delete
    $qwikmdallsel delete
    mol delete $qwikmdmol
    mol delete $pdbmol
}

proc ::GOLEM::gui::sim_equal {x y} {
    set epsilon 0.0001
    if {[expr abs($x-$y)]<$epsilon} {
	return 1
    } else {
	return 0
    }
}

proc ::GOLEM::gui::generate_ligand_str {} {
    global env
    ::GOLEM::gui::update_status_text "generating ligand str"
    if {$::GOLEM::gui::isPeptide==0 && [llength $::GOLEM::gui::ligandResnameStr]==1 && $::GOLEM::gui::ligandMOL2!="" && $::GOLEM::gui::ligandTOP==""} {
	set answer [tk_messageBox -icon question -message "Missing topology file of the ligand. Will direct you to Molefacture to generate a topology file (str) of the receptor." -detail "-Please provide a CGENFF user name and then save the topology file in a desired location" -type okcancel]
	switch $answer {
	    cancel {return} 
	    ok {
		#call molefacture when ligandMOL2 is provided and ligandTOP is missing
		variable dialogMolefac [toplevel .golemGui.dialogMolefac]
		wm title $dialogMolefac ""
		wm resizable $dialogMolefac 1 1
		lassign [split [winfo geometry .golemGui] {x +}] sizex sizey x y
		wm geometry $dialogMolefac 300x150+[expr int($x+($sizex/2.0)-150)]+[expr int($y+($sizey/2.0)-75)]
		#in case the dialogMolefac window is closed by user
		bind .golemGui.dialogMolefac <Destroy> {
		    ::GOLEM::gui::update_status_text "Preparation stopped"
		    set traceInfo [trace info execution ::Molefacture::write_topology_gui]
		    foreach t $traceInfo {
		        trace remove execution ::Molefacture::write_topology_gui [lindex $t 0] [lindex $t 1]
		    }
		    set traceInfo [trace info execution ::Molefacture::checkCgenffUser]
		    foreach t $traceInfo {
		        trace remove execution ::Molefacture::checkCgenffUser [lindex $t 0] [lindex $t 1]
		    }
		    set traceInfo [trace info variable ::Molefacture::topocgenff]
		    foreach t $traceInfo {
		        trace remove variable ::Molefacture::topocgenff [lindex $t 0] [lindex $t 1]
		    }

		}
		frame $dialogMolefac.window
		label $dialogMolefac.window.message -text "Please use Molefacture to generate ligand's str file" -wraplength 250
		button $dialogMolefac.window.ok -text "Next" -command {
		    if {$env(CGENFFUSERNAME)==-1} {
		        .golemGui.dialogMolefac.window.message config -text  "Please use Molefacture to generate ligand's str file\nPlease provide a CGENFF user name in the \"CGenFF Settings\" window. You may check http\:\/\/cgenff.umaryland.edu to register"
		        update
			::Molefacture::cgenffUserWindows
		    } elseif {$::Molefacture::topocgenff!=1} {
		        .golemGui.dialogMolefac.window.message config -text  "Please use Molefacture to generate ligand's str file?\nTopology hasn't retrived from CGENFF"
		        update
			::Molefacture::CgenffServerCall
		    } else {
			::Molefacture::write_topology_gui
		    }
		}
		grid $dialogMolefac.window.message -row 0 -column 0  -sticky nesw
	    	grid $dialogMolefac.window.ok -row 1 -column 0 -sticky nesw
	    	grid $dialogMolefac.window -row 0 -column 0 -sticky nesw
	    	grid columnconfigure $dialogMolefac 0 -weight 1
	    	grid rowconfigure $dialogMolefac 0 -weight 1
	    	grid columnconfigure $dialogMolefac.window 0 -weight 1
	    	grid rowconfigure $dialogMolefac.window 0 -weight 1

		set tmpmol [mol new $::GOLEM::gui::ligandMOL2]
		if {![winfo exists .molefac] || ![winfo viewable .molefac]} {
		    catch {::Molefacture::initialize}
		    ::Molefacture::molefacture_gui
		    ::Molefacture::moleculeChanged
		    ::Molefacture::loadDefaulTopo
		    ::Molefacture::setHotKeys
		}
		set ::Molefacture::atomsel "resname $::GOLEM::gui::ligandResnameStr"
		::Molefacture::molefacture_gui_aux $::Molefacture::atomsel
		mol delete $tmpmol
		trace add variable ::Molefacture::topocgenff write ::GOLEM::gui::wait_cgenff
		trace add execution ::Molefacture::write_topology_gui leave ::GOLEM::gui::wait_top
		if {$env(CGENFFUSERNAME)==-1} {
		    ::Molefacture::cgenffUserWindows
		    #whenever env(CGENFFUSERNAME) is written, do CgenffServerCall
		    trace add execution ::Molefacture::checkCgenffUser leave ::GOLEM::gui::wait_cgenffusername
		} else {
		    ::Molefacture::CgenffServerCall
		}
	    }
	}
    } else {
	::GOLEM::gui::generate_ligand_psfpdb
    }

#::Molefacture::molefacture_start
#::Molefacture::submitCGENFF
#set ::Molefacture::atomsel "resname $::GOLEM::gui::ligandResnameStr"
#::Molefacture::molefacture_gui_aux $::Molefacture::atomsel
#::cgenffUserWindows
#::Molefacture::CgenffServerCall
}

proc ::GOLEM::gui::wait_cgenffusername {call code result op} {
    global env
    if {$env(CGENFFUSERNAME)!=-1} {
	::Molefacture::CgenffServerCall
    } else {
	::Molefacture::cgenffUserWindows
    }
}

proc ::GOLEM::gui::wait_cgenff {varname args} {
    if {$::Molefacture::topocgenff==1} {
	::Molefacture::write_topology_gui
    } else {
	.golemGui.dialogMolefac.window.message config -text "Proceed?\nFailed to connect to CGENFF server. Wrong user name?"
	::Molefacture::cgenffUserWindows
    }
}

proc ::GOLEM::gui::wait_top {call code result op} {
    if {[file extension $result]==".str" && [file exists $result] && [file isfile $result]} {
	set ::GOLEM::gui::ligandTOP $result
	lappend ::GOLEM::gui::parFileList $result
	#if {[winfo exists $::Molefacture::cgenffWindow] && [winfo viewable $::Molefacture::cgenffWindow]} {
	#    wm iconify $::Molefacture::cgenffWindow
	#}
	#if {[winfo exists $::Molefacture::topGui] && [winfo viewable $::Molefacture::topGui]} {
	#    wm iconify $::Molefacture::topGui
	#}
	catch {::Molefacture::closeMainWindow export_qmtool}
	if {[winfo exists .golemGui.dialogMolefac]} {
	    destroy .golemGui.dialogMolefac
	}
	lappend ::GOLEM::gui::parFileList $result
	::GOLEM::gui::generate_ligand_psfpdb
    } else {
	.golemGui.dialogMolefac.window.message config -text "Proceed?\nFailed to save ligand's str" 
    }
}

proc ::GOLEM::gui::generate_ligand_psfpdb {} {
    ::GOLEM::gui::update_status_text "generating ligand psf/pdb"
    #first, generate pdb if not provided
    if {[::GOLEM::gui::is_file $::GOLEM::gui::ligandPDB {.pdb}]!=1 || [lsearch $::GOLEM::gui::inputPDBResnameList $::GOLEM::gui::ligandResnameStr]==-1} {
	if {$::GOLEM::gui::isPeptide==0} {
	    #single residue
	    #for single residue, if pdb is not provided, a mol2 file must be provided
	    set tmpmol [mol new $::GOLEM::gui::ligandMOL2]
	    set tmpsel [atomselect $tmpmol "resname $::GOLEM::gui::ligandResnameStr"]
	    $tmpsel set segname LIG
	    $tmpsel writepdb $::GOLEM::gui::outDir/prepare/ligand.pdb
	    $tmpsel delete
	    mol delete $tmpmol
	    set ::GOLEM::gui::ligandPDB $::GOLEM::gui::outDir/prepare/ligand.pdb
	} else {
	#peptide
	    if {![winfo exists .molefac] || ![winfo viewable .molefac]} {
		catch {::Molefacture::initialize}
	    	::Molefacture::molefacture_gui
	    	::Molefacture::moleculeChanged
	    	::Molefacture::loadDefaulTopo
	    	::Molefacture::setHotKeys
	    }
	    ::Molefacture::molefacture_gui_aux
	    set ::Molefacture::origseltext ""
	    set ::Molefacture::origmolid -1
	    #::Molefacture::prot_builder_gu
	    ::Molefacture::build_textseq $::GOLEM::gui::ligandResnameStr
	    set tmpsel [atomselect $::Molefacture::tmpmolid "$::Molefacture::notDumSel and not water and not ions"]
	    $tmpsel set segname LIG
	    $tmpsel writepdb $::GOLEM::gui::outDir/prepare/ligand.pdb
	    $tmpsel delete
	    set ::GOLEM::gui::ligandPDB $::GOLEM::gui::outDir/prepare/ligand.pdb
	    catch {::Molefacture::closeMainWindow export_qmtool}
	}
	::GOLEM::gui::update_status_text "ligand pdb generated"
    } else {
    #make sure the segname of the ligand is LIG
	set tmpmol [mol new $::GOLEM::gui::ligandPDB]
	set tmpsel [atomselect $tmpmol "resname $::GOLEM::gui::ligandResnameStr"]
	$tmpsel set segname LIG
	$tmpsel writepdb $::GOLEM::gui::outDir/prepare/ligand.pdb
	$tmpsel delete
	mol delete $tmpmol
	set ::GOLEM::gui::ligandPDB $::GOLEM::gui::outDir/prepare/ligand.pdb
    }
    #second, generate psf if not provided
    if {[::GOLEM::gui::is_file $::GOLEM::gui::ligandPSF {.psf}]!=1 && [lsearch $::GOLEM::gui::inputPSFResnameList $::GOLEM::gui::ligandResnameStr]==-1} {
	psfcontext reset
	resetpsf
	set golemcontext [psfcontext new]
	psfcontext eval $golemcontext {
	    foreach top $::GOLEM::gui::topFileList {
		topology $top 
	    }
	    if {[::GOLEM::gui::is_file $::GOLEM::gui::ligandTOP {.top .rtf .inp .str}]==1} {
		topology $::GOLEM::gui::ligandTOP
	    }
	    pdbalias residue HIS HSD
	    segment LIG {
		pdb $::GOLEM::gui::ligandPDB
		if {$::GOLEM::gui::isPeptide} {
		    first NTER
		    last CTER
		} else {
		    first none
		    last none
		}
		auto angles dihedrals
	    }
	    coordpdb $::GOLEM::gui::ligandPDB
	    guesscoord
	    writepsf $::GOLEM::gui::outDir/prepare/ligand.psf
	    writepdb $::GOLEM::gui::outDir/prepare/ligand.pdb
	    set ::GOLEM::gui::ligandPSF $::GOLEM::gui::outDir/prepare/ligand.psf
	    set ::GOLEM::gui::ligandPDB $::GOLEM::gui::outDir/prepare/ligand.pdb
	}
	psfcontext delete $golemcontext
	::GOLEM::gui::update_status_text "ligand psf generated"
    } else {
    #make sure the segname of the ligand is LIG
	set tmpmol [mol new $::GOLEM::gui::ligandPSF]
	mol addfile $::GOLEM::gui::ligandPDB $tmpmol
	set tmpsel [atomselect $tmpmol "resname $::GOLEM::gui::ligandResnameStr"]
	$tmpsel set segname LIG
	$tmpsel writepsf $::GOLEM::gui::outDir/prepare/ligand.psf
	$tmpsel delete
	mol delete $tmpmol
	set ::GOLEM::gui::ligandPSF $::GOLEM::gui::outDir/prepare/ligand.psf
    }
    ::GOLEM::gui::update_status_text "ligand psf/pdb generated"
    set ::GOLEM::gui::readyToRun 1
    ::GOLEM::gui::update_status_text "Ready to run! Click Run to start docking!"
}

proc ::GOLEM::gui::update_status_text {text} {
    variable w
    $w.console.status configure -text $text
    update
}

proc ::GOLEM::gui::output_selected {w} {
    set sel [get_output_cell_selection $w] 
    if {$sel==-1} {return}
    lassign $sel round rank
    puts "MDFF score: [lindex $::GOLEM::run::bestDistinctScoreAllMDFF $round $rank], energy score: [lindex $::GOLEM::run::bestDistinctScoreAllEnergy $round $rank], water calibration: [lindex $::GOLEM::run::bestDistinctScoreAllWaterCali $round $rank]"
    show_result $round $rank
}

proc ::GOLEM::gui::get_output_cell_selection {w} {
    set curcell [$w curcellselection]
    if {$curcell==""} {return -1}
    set row [lindex [split $curcell {,}] 0]
    set col [lindex [split $curcell {,}] 1]
    if {$col==0} {return -1}
    set score [lindex $::GOLEM::run::bestDistinctScoreAll $row [expr $col-1]]
    if {$score==""} {return -1}
    set round $row
    set rank [expr $col-1]
    return [list $round $rank]
}

proc ::GOLEM::gui::show_result_loadpsf {} {
    variable showResultMol
    foreach id [molinfo list] {mol off $id}
    set showResultMol [mol new $::GOLEM::run::systemPSF]
    mol addfile $::GOLEM::run::ligandPot $showResultMol
    for {set i 0} {$i<[molinfo $showResultMol get numreps]} {incr i} {
    mol showrep $showResultMol $i off
    }
    #map
    mol color Element
    mol representation Isosurface 0.50000 0 2 1 1 1
    mol material Opaque
    mol selection "not resname DUM"
    mol addrep $showResultMol
    #ligand
    mol color Name
    mol representation Licorice
    mol material Opaque
    mol selection $::GOLEM::run::ligandSelStr
    mol addrep $showResultMol
    #receptor
    mol color Chain
    mol representation NewCartoon
    mol material Opaque
    mol selection "(protein or nucleic) and not segname GW and not ($::GOLEM::run::ligandSelStr)"
    mol addrep $showResultMol
    #other molecules
    mol color Name
    mol representation CPK
    mol material Opaque
    mol selection "same residue as (all and not protein and not nucleic and not segname GW and not ($::GOLEM::run::ligandSelStr) and (x>$::GOLEM::run::siteMinX and x<$::GOLEM::run::siteMaxX and y>$::GOLEM::run::siteMinY and y<$::GOLEM::run::siteMaxY and z>$::GOLEM::run::siteMinZ and z<$::GOLEM::run::siteMaxZ))"
    mol addrep $showResultMol
    mol selupdate [expr [molinfo $showResultMol get numreps]-1] $showResultMol 1
    #molinfo $showResultMol set center $::GOLEM::run::bindingsiteCenter
    #water
    mol color Name
    mol representation CPK
    mol material Opaque
    mol selection "segname GW and same residue as (x>$::GOLEM::run::siteMinX and x<$::GOLEM::run::siteMaxX and y>$::GOLEM::run::siteMinY and y<$::GOLEM::run::siteMaxY and z>$::GOLEM::run::siteMinZ and z<$::GOLEM::run::siteMaxZ)"
    mol addrep $showResultMol
    mol selupdate [expr [molinfo $showResultMol get numreps]-1] $showResultMol 1
    display resetview
    translate to 0 0 0
    display update
}

proc ::GOLEM::gui::show_result {round rank} {
    variable showResultMol
    if {![info exists showResultMol] || [lsearch [molinfo list] $showResultMol]==-1 } {
	::GOLEM::gui::show_result_loadpsf
    }
    #mol addfile may not work because of mismatched atom number, so record frame number to check if it succeed
    set nfbefore [molinfo $showResultMol get numframes]
    if {[catch {mol addfile $::GOLEM::run::GAOutDir/$round.best_distinct.dcd first $rank last $rank $showResultMol}]} {
	#file not exists
	return
    }
    set nfafter [molinfo $showResultMol get numframes]
    if {$nfbefore==$nfafter} {
	#nothing loaded, must have a mismatched atom number; reload psf
	::GOLEM::gui::show_result_loadpsf
	mol addfile $::GOLEM::run::GAOutDir/$round.best_distinct.dcd first $rank last $rank $showResultMol
    }
    if {[molinfo $showResultMol get numframes]>1} {
	animate delete beg 0 end [expr [molinfo $showResultMol get numframes]-2] $showResultMol
    }
    if {[molinfo top]!=$showResultMol} {
	mol top $showResultMol
	display resetview
    }
    mol on $showResultMol 
}

proc ::GOLEM::gui::save_selected_pose {w} {
    set sel [get_output_cell_selection $w]
    if {$sel==-1} {return}
    lassign $sel round rank
    ::GOLEM::run::save_docking_result $round $rank
    update_status_text "Selected pose saved as $::GOLEM::gui::outDir/result/docked_iteration$round\_rank$rank"
}

proc ::GOLEM::gui::abort {} {
    catch {::GOLEM::run::terminate}
}
