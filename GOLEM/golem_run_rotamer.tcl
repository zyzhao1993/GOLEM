proc ::GOLEM::run::en_queue {q i} {
#add item to the end of the queue
    upvar 1 $q myq 
    lappend myq $i
}
proc ::GOLEM::run::de_queue {q} {
#take 0th item
    upvar 1 $q myq
    set myq [lassign $myq item]
    return $item 
}
proc ::GOLEM::run::add_edge {g u v l} {
#g: graph, u: node from, v: node to, l: length
    upvar 1 $g myg
    dict set myg $u $v $l
    if {$v!=$u} {dict set myg $v $u $l}
    #lappend myg($u) [list $v $l]
    #if {$v!=$u} {lappend myg($v) [list $u $l] }
}
proc ::GOLEM::run::is_reachable {g s d} {
    upvar 1 $g myg
    set visited [dict create]
    foreach id [dict keys $myg] {
	dict set visited $id False
    }
    set Q [list]    
    ::GOLEM::run::en_queue Q $s
    dict set visited $s True
   
    while {[llength $Q]} {
	set n [::GOLEM::run::de_queue Q]
	if {$n==$d} {
	    #finish
	    return True
	}
	if {[dict exists $myg $n]} {
	    set neighborList [dict keys [dict get $myg $n]]
	    foreach neighbor $neighborList {
		set length [dict get $myg $n $neighbor]
		if {$length!=Inf} {
		    if {[dict get $visited $neighbor]==False} {
			::GOLEM::run::en_queue Q $neighbor
			dict set visited $neighbor True
		    }
		}
	    }
	}
    }
    return False
}

proc ::GOLEM::run::list_connected_nodes {g s} {
    upvar 1 $g myg
    set visited [dict create]
    foreach id [dict keys $myg] {
	dict set visited $id False
    }
    set Q [list]
    ::GOLEM::run::en_queue Q $s
    dict set visited $s True
    set connectedNodes [list]

    while {[llength $Q]} {
	set n [::GOLEM::run::de_queue Q]
	if {[dict exists $myg $n]} {
	    set neighborList [dict keys [dict get $myg $n]]
	    foreach neighbor $neighborList {
		set length [dict get $myg $n $neighbor]
		if {$length!=Inf} {
		    if {[dict get $visited $neighbor]==False} {
			::GOLEM::run::en_queue Q $neighbor
			dict set visited $neighbor True
			lappend connectedNodes $neighbor
		    }
		}
	    }
	}
    }
    return $connectedNodes
}

proc ::GOLEM::run::build_graph {g bondList} {
    upvar 1 $g myg
    #all nodes
    foreach {$id1 $id2} $bondList {
	::GOLEM::run::add_edge myg $id1 $id2 0
    }
}

proc ::GOLEM::run::is_rotamer {g id1 id2} {
    set myg $g
    dict set myg $id1 $id2 Inf
    dict set myg $id2 $id1 Inf
    set reach [::GOLEM::run::is_reachable myg $id1 $id2]
    if {$reach} {
	return 0
    } else {
	return 1
    }
}

proc ::GOLEM::run::rotamer_split {g dihed} {
    set myg $g
    lassign $dihed id1 id2 id3 id4
    dict set myg $id2 $id3 Inf
    dict set myg $id3 $id2 Inf
    set group1 [::GOLEM::run::list_connected_nodes myg $id2]
    set group2 [::GOLEM::run::list_connected_nodes myg $id3]
#return the smaller group
    if {[llength $group1]>=[llength $group2]} {
	return [list $dihed $group2]
    } else {
	return [list [lreverse $dihed] $group1]
    }
}

proc ::GOLEM::run::find_rotamer {ligandPSF ligandPDB atomSel} {
    set molid [mol new $ligandPSF]
    mol addfile $ligandPDB waitfor all $molid

    set bondList [topo getbondlist -molid $molid -sel "$atomSel"]; list
    set g [dict create]
    foreach bondPair $bondList {
	lassign $bondPair id1 id2
	::GOLEM::run::add_edge g $id1 $id2 0
    }
#used to check if new bond creats a too small group
    set heavyBondList [topo getbondlist -molid $molid -sel "$atomSel and noh"]; list
    set tmpg [dict create]
    foreach bondPair $heavyBondList {
	lassign $bondPair id1 id2
	::GOLEM::run::add_edge tmpg $id1 $id2 0
    }

    set dihedList [topo getdihedrallist -molid $molid -sel "$atomSel and noh"]; list
    set rotBondList [list]
    set rotDihedList [list]
    foreach dihedGroup $dihedList {
	set idList [lassign $dihedGroup name] 
	lassign $idList id1 id2 id3 id4
	if {[::GOLEM::run::is_rotamer $g $id2 $id3]} {
	    #puts "$id1 $id2 $id3 $id4 is a rotamer"
	    if {$id2>$id3} {set idList [lreverse $idList]}
#to avoid too small segment
#previously, if the smaller group has less than three heavy atoms, drop it
#but it is not enough, because it doesn't check for segment size after breaking all rotamers
	    lassign [rotamer_split $g $idList] tmp group
	    set tmpsel [atomselect $molid "index $group and noh"]
	    #if {[$tmpsel num]<3} {continue}
	    dict set tmpg $id2 $id3 Inf
	    dict set tmpg $id3 $id2 Inf
	    if {[llength [::GOLEM::run::list_connected_nodes tmpg $id2]]<2 || [llength [::GOLEM::run::list_connected_nodes tmpg $id3]]<2} {
		#puts "doesn't break $id2 $id3: $id2 connect [::GOLEM::run::list_connected_nodes tmpg $id2]; $id3 connect [::GOLEM::run::list_connected_nodes tmpg $id3]"
		dict set tmpg $id2 $id3 0
		dict set tmpg $id3 $id2 0
		continue
	    }
	    lappend rotBondList [lrange $idList 1 2]
	    lappend rotDihedList $idList
	}
    }
    set rotBondListNoDup [lsort -unique $rotBondList]
    if {0} {
    set dihedParas [list]
    foreach parFile $parFiles {
        lappend dihedParas {*}[lindex [::ForceFieldToolKit::SharedFcns::readParFile $parFile] 2]; list
    }
    set types [[atomselect $molid all] get type]
    set rotBondListNoDoubleBond [list]
    foreach rotBond $rotBondListNoDup {
        if {![::GOLEM::run::is_double_bond $rotBond g $types $dihedParas]} {
            lappend rotBondListNoDoubleBond $rotBond
        }
    }
    }
    set rotBondListNoDoubleBond $rotBondListNoDup
    set rotDihedListNoDup [list]
    foreach rotBond $rotBondListNoDoubleBond {
	lappend rotDihedListNoDup [lindex $rotDihedList [lsearch $rotBondList $rotBond]]
    }
    foreach rotBond $rotBondListNoDup rotDihed $rotDihedListNoDup {
	puts "bond: $rotBond; dihed: $rotDihed"
    }

    set rotamers [list]
    foreach dihed $rotDihedListNoDup {
	lappend rotamers [::GOLEM::run::rotamer_split $g $dihed]
    }
    mol delete $molid
    return $rotamers
}

proc ::GOLEM::run::split_all_rotamer {ligandPSF ligandPDB atomSel} {
    set molid [mol new $ligandPSF]
    mol addfile $ligandPDB waitfor all $molid

    set bondList [topo getbondlist -molid $molid -sel "$atomSel"]; list
    set g [dict create]
    foreach bondPair $bondList {
	lassign $bondPair id1 id2
	::GOLEM::run::add_edge g $id1 $id2 0
    }
#used to check if new bond creats a too small group
    set heavyBondList [topo getbondlist -molid $molid -sel "$atomSel and noh"]; list
    set tmpg [dict create]
    foreach bondPair $heavyBondList {
	lassign $bondPair id1 id2
	::GOLEM::run::add_edge tmpg $id1 $id2 0
    }

    set dihedList [topo getdihedrallist -molid $molid -sel "$atomSel and noh"]; list
    set rotBondList [list]
    set rotDihedList [list]
    foreach dihedGroup $dihedList {
	set idList [lassign $dihedGroup name] 
	lassign $idList id1 id2 id3 id4
	if {[::GOLEM::run::is_rotamer $g $id2 $id3]} {
	    #puts "$id1 $id2 $id3 $id4 is a rotamer"
	    if {$id2>$id3} {set idList [lreverse $idList]}
#to avoid too small segment
#previously, if the smaller group has less than three heavy atoms, drop it
#but it is not enough, because it doesn't check for segment size after breaking all rotamers
	    lassign [rotamer_split $g $idList] tmp group
	    set tmpsel [atomselect $molid "index $group and noh"]
	    #if {[$tmpsel num]<3} {continue}
	    dict set tmpg $id2 $id3 Inf
	    dict set tmpg $id3 $id2 Inf
	    if {[llength [::GOLEM::run::list_connected_nodes tmpg $id2]]<2 || [llength [::GOLEM::run::list_connected_nodes tmpg $id3]]<2} {
		#puts "doesn't break $id2 $id3: $id2 connect [::GOLEM::run::list_connected_nodes tmpg $id2]; $id3 connect [::GOLEM::run::list_connected_nodes tmpg $id3]"
		dict set tmpg $id2 $id3 0
		dict set tmpg $id3 $id2 0
		continue
	    }
	    lappend rotBondList [lrange $idList 1 2]
	    lappend rotDihedList $idList
	}
    }
    set rotBondListNoDup [lsort -unique $rotBondList]
    set rotDihedListNoDup [list]
    foreach rotBond $rotBondListNoDup {
	lappend rotDihedListNoDup [lindex $rotDihedList [lsearch $rotBondList $rotBond]]
    }
    foreach rotBond $rotBondListNoDup rotDihed $rotDihedListNoDup {
	puts "bond: $rotBond; dihed: $rotDihed"
    }

    #set rotamers [list]
    #foreach dihed $rotDihedListNoDup {
    #    lappend rotamers [::GOLEM::run::rotamer_split $g $dihed]
    #}
    set segments [list]
    foreach dihed $rotDihedListNoDup {
	lassign $dihed id1 id2 id3 id4
	dict set g $id2 $id3 Inf
	dict set g $id3 $id2 Inf
    }
    set unassigned [lsort -unique [concat {*}$bondList]]
    puts "unassigned before: $unassigned"
    while {[llength $unassigned]>0} {
	set group [concat {*}[::GOLEM::run::list_connected_nodes g [lindex $unassigned 0]] [lindex $unassigned 0]]
	puts "adding group $group"
	lappend segments $group
	foreach added $group {
	    set index [lsearch $unassigned $added]
	    set unassigned [lreplace $unassigned $index $index]
	}
	puts "current unassigned $unassigned"
    }
    mol delete $molid
    return $segments
}

#proc ::GOLEM::run::is_double_bond {bond g types dihedParas} {
#    upvar 1 $g myg
#    set id2 [lindex $bond 0]
#    set id3 [lindex $bond 1]
#    puts [dict get $myg $id2]
#    puts [dict get $myg $id3]
#    set id1List [lsearch -inline -all -not -exact [dict keys [dict get $myg $id2]]  $id3]
#    set id4List [lsearch -inline -all -not -exact [dict keys [dict get $myg $id3]]  $id2]
#
#    foreach id1 $id1List {
#	foreach id4 $id4List {
#	    set type [list [lindex $types $id1] [lindex $types $id2] [lindex $types $id3] [lindex $types $id4]]
#	    set para [::Pararead::getdihedparam $dihedParas $type]
#	    if {$para=={}} {
#		continue
#	    } else {
#		lassign [lindex $para 1] kchi n
#		if {$kchi>0 && $n==3} {
#		    return 0
#		}
#	    }
#	}
#    }
#    puts "$bond is a double bond"
#    return 1
#}
