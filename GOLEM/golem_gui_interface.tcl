namespace eval ::GOLEM::gui {
    variable w
    # general variables
    variable outDir 

    # namd variables
    variable namdBin
    variable namdOpt

    # receptor variables
    variable receptorPSF
    variable receptorPDB
    variable keepCrystalWater
    variable optimizeCrystalWaterOrientation

    # map variables
    variable oriMap
    variable siteMinX
    variable siteMinY
    variable siteMinZ
    variable siteMaxX
    variable siteMaxY
    variable siteMaxZ
    variable bindingsiteStr

    # ligand variables
    variable ligandPSF
    variable ligandPDB
    variable ligandDCD
    variable ligandMOL2
    variable ligandTOP 
    variable ligandResnameStr

    #parameter files
    variable parFileList {}

    # ga variables
    variable waterMaxNum
    variable ligandCoupFactor 
    variable waterCoupFactor
    variable fixedSidechain

    # gui variables
    variable isPeptide
    variable needTOP
    variable needMOL2
    variable needPSF
    variable needPDB

    variable readyToRun

    # mol; not written in status_script
    variable receptorPDBMol {}
    variable drawMol {}
    variable mapMol {}

    # reps and draws; not written in status_script
    variable reps {}
    variable draws {}
    variable hideOptional 1

    variable topFileList {}
    variable topResnameList {}
    variable aaResnameList {A R N D C Q E G H I L K M F P S T W Y V}

    variable inputMOL2ResnameList {}
    variable inputTOPResnameList {}
    variable inputPSFResnameList {}
    variable inputPDBResnameList {}

    variable variableList [list outDir namdBin namdOpt receptorPSF receptorPDB keepCrystalWater optimizeCrystalWaterOrientation oriMap siteMinX siteMinY siteMinZ siteMaxX siteMaxY siteMaxZ bindingsiteStr ligandPSF ligandPDB ligandDCD ligandMOL2 ligandTOP ligandResnameStr parFileList waterMaxNum ligandCoupFactor waterCoupFactor fixedSidechain isPeptide readyToRun]
}

proc ::GOLEM::golem {} {
    ::GOLEM::gui::golem_gui
    ::GOLEM::gui::init
}


proc ::GOLEM::gui::golem_gui {} {
    # type lists for file dialogs
    set ::GOLEM::gui::psfType { {{PSF Files} {.psf}} {{All Files} *}}
    set ::GOLEM::gui::pdbType { {{PDB Files} {.pdb}} {{All Files} *}}
    set ::GOLEM::gui::dcdType { {{DCD Files} {.dcd}} {{All Files} *}}
    set ::GOLEM::gui::mol2Type { {{MOL2 Files} {.mol2}} {{All Files} *}}
    set ::GOLEM::gui::topType { {{Topology Files} {.top .rtf .inp .str}} {{All Files} *}}
    set ::GOLEM::gui::parType { {{Parameter Files} {.par .prm .inp .str}} {{All Files} *}}
    set ::GOLEM::gui::mapType { {{map Files} {.map .mrc .situs .ccp4 .dx}} {{All Files} *}}
    set ::GOLEM::gui::allType { {{All Files} *}}

    set ::GOLEM::gui::vbPadX [list 10 0]; #boundary pad
    set ::GOLEM::gui::vsepPadX 2
    set ::GOLEM::gui::vsepPadY 0
    set ::GOLEM::gui::largevsepPadY 5
    set ::GOLEM::gui::buttonWidth  5
    set ::GOLEM::gui::tableHeight  5
    set ::GOLEM::gui::buttonHeight  1
    set ::GOLEM::gui::labelWidth  13
    set ::GOLEM::gui::largeLabelWidth  30
    set ::GOLEM::gui::smallLabelWidth  5
    set ::GOLEM::gui::entryWidth  90
    set ::GOLEM::gui::smallEntryWidth  5
    set ::GOLEM::gui::bd 2

    variable w
    if { [winfo exists .golemGui] } {
	wm deiconify .golemGui
	return
    }
    set w [toplevel ".golemGui"]
    wm title $w "Cryo-EM-guided ligand docking (GOLEM)"
    wm resizable $w 1 0
    grid columnconfigure $w 0 -weight 1
    #grid rowconfigure $w 0 -weight 1

    #wm geometry $w 825x500

    ::GOLEM::gui::build_menu
    ::GOLEM::gui::build_map
    ::GOLEM::gui::build_receptor
    ::GOLEM::gui::build_bindingsite
    ::GOLEM::gui::build_ligand
    ::GOLEM::gui::build_parameters
    ::GOLEM::gui::build_setting
    ::GOLEM::gui::build_general
    ::GOLEM::gui::build_buttons
    ::GOLEM::gui::build_console


    grid $w.menubar -row 0 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.map -row 1 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.receptor -row 2 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    #grid $w.bindingsite -row 3 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand -row 3 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.parameters -row 4 -column 0 -sticky nswe -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite -row 5 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting -row 6 -column 0 -sticky nswe -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general -row 7 -column 0 -sticky nswe -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.buttons -row 8 -column 0 -sticky nswe -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.console -row 9 -column 0 -sticky nswe -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    ::GOLEM::gui::check_resname
    set ::GOLEM::gui::ligandMOL2 $::GOLEM::gui::ligandMOL2
    set ::GOLEM::gui::ligandTOP $::GOLEM::gui::ligandTOP
    set ::GOLEM::gui::ligandPSF $::GOLEM::gui::ligandPSF
    set ::GOLEM::gui::ligandPDB $::GOLEM::gui::ligandPDB
}

proc ::GOLEM::gui::build_menu {} {
    variable w
    frame $w.menubar -relief raised -bd $::GOLEM::gui::bd
    #grid columnconfigure $w.menubar 0 -weight 1
    grid rowconfigure $w.menubar 0 -weight 0

    menubutton $w.menubar.help -text Help -underline 0 -menu $w.menubar.help.menu 
    menu $w.menubar.help.menu -tearoff no
    $w.menubar.help.menu add command -label "About" -underline 0 -command ::GOLEM::gui::about
    $w.menubar.help.menu add command -label "How to use" -underline 0 -command ::GOLEM::gui::how_to_use
    $w.menubar.help config -width $::GOLEM::gui::buttonWidth

    menubutton $w.menubar.file -text File -underline 0 -menu $w.menubar.file.menu 
    menu $w.menubar.file.menu -tearoff no
    $w.menubar.file.menu add command -label "Load Status" -underline 0 -command ::GOLEM::gui::open_gui_script
    $w.menubar.file.menu add command -label "Save Status" -underline 0 -command ::GOLEM::gui::save_gui_script
    $w.menubar.file.menu add command -label "Refresh" -underline 0 -command ::GOLEM::gui::refresh
    $w.menubar.file config -width $::GOLEM::gui::buttonWidth

    grid $w.menubar.file -row 1 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.menubar.help -row 1 -column 1 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
}

proc ::GOLEM::gui::build_map {} {
    variable w
    frame $w.map -relief ridge -bd $::GOLEM::gui::bd

    #title label
    frame $w.map.title
    label $w.map.title.label -text "Experimental Map" -anchor nw
    catch {::TKTOOLTIP::balloon $w.map.title.label "The experimental map of the system"}
    grid $w.map.title.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #input map file
    frame $w.map.input
    label $w.map.input.mapLabel -text "Map File:" -anchor nw -width $::GOLEM::gui::labelWidth
    catch {::TKTOOLTIP::balloon $w.map.input.mapLabel "Please provide a map file that VMD can read.\nSupported extensions are .mrc, .map, .dx, .ccp4, and .situs."}
    entry $w.map.input.mapPath -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::oriMap 
    button $w.map.input.mapButton -text "Browse" -width $::GOLEM::gui::buttonWidth\
        -command {
            set tempFile [tk_getOpenFile -filetypes $::GOLEM::gui::mapType]
            if {![string equal $tempFile ""]} {set ::GOLEM::gui::oriMap $tempFile}
        }

    grid $w.map.input.mapLabel -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.map.input.mapPath -row 0 -column 1 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.map.input.mapButton -row 0 -column 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.map.input 1 -weight 1

    grid $w.map.title -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.map.input -row 1 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.map 0 -weight 1
}

proc ::GOLEM::gui::build_receptor {} {
    variable w
    frame $w.receptor -relief ridge -bd $::GOLEM::gui::bd

    #title label
    frame $w.receptor.title
    label $w.receptor.title.label -text "Receptor" -anchor nw
    grid $w.receptor.title.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #input pdb and psf
    frame $w.receptor.input
    label $w.receptor.input.pdbLabel -text "PDB File\nor PDBID:" -anchor nw -width $::GOLEM::gui::labelWidth
    catch {::TKTOOLTIP::balloon $w.receptor.input.pdbLabel "Please provide the structure of the receptor, either as a PDB file or PDB ID. Ensure that the docking ligand is not included in the receptor structure, and the coordinates of the receptor are aligned with the provided map file."}
    entry $w.receptor.input.pdbPath -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::receptorPDB 
    button $w.receptor.input.pdbButton -text "Browse" -width $::GOLEM::gui::buttonWidth\
        -command {
            set tempFile [tk_getOpenFile -filetypes $::GOLEM::gui::pdbType]
            if {![string equal $tempFile ""]} {set ::GOLEM::gui::receptorPDB $tempFile}
        }
    label $w.receptor.input.psfLabel -text "PSF File:\n(optional)" -anchor nw -width $::GOLEM::gui::labelWidth
    catch {::TKTOOLTIP::balloon $w.receptor.input.psfLabel "(Optional) Please provide a psf file of the receptor that matches with the provided receptor's pdb file.\nIf not provided, it will be generated during preparation."}
    entry $w.receptor.input.psfPath -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::receptorPSF 
    button $w.receptor.input.psfButton -text "Browse" -width $::GOLEM::gui::buttonWidth\
        -command {
            set tempFile [tk_getOpenFile -filetypes $::GOLEM::gui::psfType]
            if {![string equal $tempFile ""]} {set ::GOLEM::gui::receptorPSF $tempFile}
        }
    grid $w.receptor.input.pdbLabel -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.receptor.input.pdbPath -row 0 -column 1 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY 
    grid $w.receptor.input.pdbButton -row 0 -column 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.receptor.input.psfLabel -row 1 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.receptor.input.psfPath -row 1 -column 1 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.receptor.input.psfButton -row 1 -column 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.receptor.input 1 -weight 1

    #water in input pdb
    frame $w.receptor.input.water
    checkbutton $w.receptor.input.water.keep -text "Include Water Found in PDB" -onvalue 1 -offvalue 0 -variable ::GOLEM::gui::keepCrystalWater\
	-command {
	    if {$::GOLEM::gui::keepCrystalWater} {
		.golemGui.receptor.input.water.orientation config -state normal
		.golemGui.receptor.input.water.orientation select
	    } else {
		.golemGui.receptor.input.water.orientation deselect
		.golemGui.receptor.input.water.orientation config -state disabled
	    }
	}
    checkbutton $w.receptor.input.water.orientation -text "Optimize Water Orientation" -onvalue 1 -offvalue 0 -variable ::GOLEM::gui::optimizeCrystalWaterOrientation
    catch {::TKTOOLTIP::balloon $w.receptor.input.water.keep "Keep or discard water molecules in the provided pdb within the docking box."}
    catch {::TKTOOLTIP::balloon $w.receptor.input.water.orientation "Optimize or fix the orientation of those water molecules in the receptor structure file within the docking box.\nCoordinates of oxygen atoms will be fixed.\nIf the water molecules in the receptor structure lack hydrogen atoms, pleae enable this option."}
    grid $w.receptor.input.water.keep -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.receptor.input.water.orientation -row 0 -column 1 -sticky e -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    grid $w.receptor.input.water -row 2 -column 1 -columnspan 2 -sticky we

    grid $w.receptor.title -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.receptor.input -row 1 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.receptor 0 -weight 1
}

proc ::GOLEM::gui::build_bindingsite {} {
    variable w
    frame $w.bindingsite -relief ridge -bd $::GOLEM::gui::bd

    #title label
    frame $w.bindingsite.title
    label $w.bindingsite.title.label -text "Docking box" -anchor nw
    catch {::TKTOOLTIP::balloon $w.bindingsite.title.label "Define the spatial boundaries for ligand docking by providing the minimum and maximum x, y, and z coordinates.\nAlternatively, you may specify these dimensions based on the minimum and maximum coordinates of a selected atom group."}
    grid $w.bindingsite.title.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #min max x, y z
    frame $w.bindingsite.minmax
    label $w.bindingsite.minmax.minxLabel -text "Min X:" -anchor e -width $::GOLEM::gui::labelWidth
    entry $w.bindingsite.minmax.minxEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::siteMinX -validate all -validatecommand {expr {[string is double %P]}}
    label $w.bindingsite.minmax.minyLabel -text "Min Y:" -anchor e -width $::GOLEM::gui::smallLabelWidth
    entry $w.bindingsite.minmax.minyEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::siteMinY -validate all -validatecommand {expr {[string is double %P]}}
    label $w.bindingsite.minmax.minzLabel -text "Min Z:" -anchor e -width $::GOLEM::gui::smallLabelWidth
    entry $w.bindingsite.minmax.minzEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::siteMinZ -validate all -validatecommand {expr {[string is double %P]}}
    label $w.bindingsite.minmax.maxxLabel -text "Max X:" -anchor e -width $::GOLEM::gui::smallLabelWidth
    entry $w.bindingsite.minmax.maxxEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::siteMaxX -validate all -validatecommand {expr {[string is double %P]}}
    label $w.bindingsite.minmax.maxyLabel -text "Max Y:" -anchor e -width $::GOLEM::gui::smallLabelWidth
    entry $w.bindingsite.minmax.maxyEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::siteMaxY -validate all -validatecommand {expr {[string is double %P]}}
    label $w.bindingsite.minmax.maxzLabel -text "Max Z:" -anchor e -width $::GOLEM::gui::smallLabelWidth
    entry $w.bindingsite.minmax.maxzEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::siteMaxZ -validate all -validatecommand {expr {[string is double %P]}}
    catch {::TKTOOLTIP::balloon $w.bindingsite.minmax.minxLabel "Minmum x coordinate of the docking box"}
    catch {::TKTOOLTIP::balloon $w.bindingsite.minmax.minyLabel "Minmum y coordinate of the docking box"}
    catch {::TKTOOLTIP::balloon $w.bindingsite.minmax.minzLabel "Minmum z coordinate of the docking box"}
    catch {::TKTOOLTIP::balloon $w.bindingsite.minmax.maxxLabel "Maxmum x coordinate of the docking box"}
    catch {::TKTOOLTIP::balloon $w.bindingsite.minmax.maxyLabel "Maxmum y coordinate of the docking box"}
    catch {::TKTOOLTIP::balloon $w.bindingsite.minmax.maxzLabel "Maxmum z coordinate of the docking box"}
    button $w.bindingsite.minmax.showButton -text "Show" -width $::GOLEM::gui::buttonWidth -command ::GOLEM::gui::show_bindingsite
    catch {::TKTOOLTIP::balloon $w.bindingsite.minmax.showButton "Visualize the docking box in VMD display."}
    grid $w.bindingsite.minmax.minxLabel -row 0 -column 0 -sticky we -pady $::GOLEM::gui::vsepPadY -padx $::GOLEM::gui::vbPadX
    grid $w.bindingsite.minmax.minxEntry -row 0 -column 1 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.minyLabel -row 0 -column 2 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.minyEntry -row 0 -column 3 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.minzLabel -row 0 -column 4 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.minzEntry -row 0 -column 5 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.maxxLabel -row 0 -column 6 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.maxxEntry -row 0 -column 7 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.maxyLabel -row 0 -column 8 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.maxyEntry -row 0 -column 9 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.maxzLabel -row 0 -column 10 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.maxzEntry -row 0 -column 11 -sticky we -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax.showButton -row 0 -column 12 -sticky e -pady $::GOLEM::gui::vsepPadY -padx $::GOLEM::gui::vsepPadX
    grid columnconfigure $w.bindingsite.minmax 1 -weight 1
    grid columnconfigure $w.bindingsite.minmax 2 -weight 1
    grid columnconfigure $w.bindingsite.minmax 3 -weight 1
    grid columnconfigure $w.bindingsite.minmax 4 -weight 1
    grid columnconfigure $w.bindingsite.minmax 5 -weight 1
    grid columnconfigure $w.bindingsite.minmax 6 -weight 1
    grid columnconfigure $w.bindingsite.minmax 7 -weight 1
    grid columnconfigure $w.bindingsite.minmax 8 -weight 1
    grid columnconfigure $w.bindingsite.minmax 9 -weight 1
    grid columnconfigure $w.bindingsite.minmax 10 -weight 1
    grid columnconfigure $w.bindingsite.minmax 11 -weight 1

    frame $w.bindingsite.atomselect
    label $w.bindingsite.atomselect.label -text "Define From\nAtomselection:" -anchor nw -width $::GOLEM::gui::labelWidth
    catch {::TKTOOLTIP::balloon $w.bindingsite.atomselect.label "Define the spatial boundaries for ligand docking by measuring the minimum and maximum coordinates of the selected atom group.\nClick \"Measure\" to measure the minimum and maximum coordinates of the atom group and \"Show\" to visualize."}
    entry $w.bindingsite.atomselect.entry -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::bindingsiteStr
    button $w.bindingsite.atomselect.button -text "Measure"  -width $::GOLEM::gui::buttonWidth -command {::GOLEM::gui::measure_bindingsite_minmax}
    catch {::TKTOOLTIP::balloon $w.bindingsite.atomselect.button "Determine the docking box dimensions by measuring the minimum and maximum coordinates of the selected atom group and setting these as the boundaries."}
    grid $w.bindingsite.atomselect.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.atomselect.entry -row 0 -column 1 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.atomselect.button -row 0 -column 12 -sticky e -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.bindingsite.atomselect 1 -weight 1

    grid $w.bindingsite.title -row 0 -column 0 -columnspan 13 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.minmax -row 2 -column 0 -columnspan 13  -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.bindingsite.atomselect -row 1 -column 0 -columnspan 13  -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.bindingsite 1 -weight 1
}

proc ::GOLEM::gui::build_ligand {} {
    variable w
    frame $w.ligand -relief ridge -bd $::GOLEM::gui::bd

    #title label
    frame $w.ligand.title
    label $w.ligand.title.label -text "Ligand" -anchor nw -width $::GOLEM::gui::labelWidth
    catch {::TKTOOLTIP::balloon $w.ligand.title.label "The ligand to be docked."}
    button $w.ligand.title.build -text "Build Molecule" -anchor ne -command ::GOLEM::gui::call_molefacture_mol2
    catch {::TKTOOLTIP::balloon $w.ligand.title.build "If you don't have the essential files of the small-molecule ligand (mol2 or pdb if ligand is defined in Charmm36 force field; otherwise, mol2, or psf+pdb+paramter, or topology+pdb+parameter files), you may build the ligand from scratch.\nBy clicking this button, a new window \"Molefacute - Molecule Builder\" will open, within which you can create and edit your molecule.\nOnce your molecule is ready, click this button again to save it as a mol2 file in your desired location.\nRefer to http://www.ks.uiuc.edu/Research/vmd/plugins/molefacture for help with Molefacture."}
    radiobutton $w.ligand.title.notPeptide -text "Small-molecule Ligand" -variable ::GOLEM::gui::isPeptide -value 0 -anchor w -command ::GOLEM::gui::switch_peptide
    radiobutton $w.ligand.title.peptide -text "Peptide Ligand" -variable ::GOLEM::gui::isPeptide -value 1 -anchor w -command ::GOLEM::gui::switch_peptide
    set ::GOLEM::gui::isPeptide 0
    #checkbutton $w.ligand.title.peptide -text "Peptide Ligand" -anchor nw -onvalue 1 -offvalue 0 -variable ::GOLEM::gui::isPeptide -state normal -command ::GOLEM::gui::switch_peptide
    $w.ligand.title.peptide deselect 
    grid $w.ligand.title.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    #grid $w.ligand.title.notPeptide -row 0 -column 1 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    #grid $w.ligand.title.peptide -row 1 -column 1 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    #grid $w.ligand.title.build -row 0 -column 2 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.ligand.title 2 -weight 1

    #resname/sequence
    frame $w.ligand.resname
    label $w.ligand.resname.label -text "Ligand Resname:" -anchor nw -width $::GOLEM::gui::labelWidth
    catch {::TKTOOLTIP::balloon $w.ligand.resname.label "Resname of the ligand in Charmm36 force field, or in the provided mol2/psf/topology files."}
    entry $w.ligand.resname.entry -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::ligandResnameStr 
    label $w.ligand.resname.warning -width $::GOLEM::gui::entryWidth -wraplength 600 -text ""  -fg red  -justify left
    grid $w.ligand.resname.label -row 0 -column 0 -sticky w  -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.resname.entry -row 0 -column 1 -columnspan 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.resname.warning -row 1 -column 1 -columnspan 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.ligand.resname 1 -weight 1

    #additional requried inputs when 
    frame $w.ligand.additional
    set names {MOL2 TOP PSF PDB}
    set types {mol2 top psf pdb}
    foreach name $names  type $types {
	frame $w.ligand.additional.$type
    	label $w.ligand.additional.$type.label -text "$name File:" -anchor w -width $::GOLEM::gui::labelWidth
    	entry $w.ligand.additional.$type.path -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::ligand$name
    	button $w.ligand.additional.$type.button -text "Browse" -width $::GOLEM::gui::buttonWidth
    	grid $w.ligand.additional.$type.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    	grid $w.ligand.additional.$type.path -row 0 -column 1 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    	grid $w.ligand.additional.$type.button -row 0 -column 2 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    	grid columnconfigure $w.ligand.additional.$type 1 -weight 1
    }
    $w.ligand.additional.mol2.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::mol2Type]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandMOL2 $tempFile}
	}
    $w.ligand.additional.top.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::topType]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandTOP $tempFile}
	}
    $w.ligand.additional.psf.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::psfType]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandPSF $tempFile}
	}
    $w.ligand.additional.pdb.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::pdbType]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandPDB $tempFile}
	}

    grid $w.ligand.additional.mol2 -row 0 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.additional.top -row 1 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.additional.psf -row 2 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.additional.pdb -row 3 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.ligand.additional 0 -weight 1

    #optional input label
    frame $w.ligand.optionallabel
    label $w.ligand.optionallabel.label -text "+ Optional Files" -anchor w -width $::GOLEM::gui::largeLabelWidth
    grid $w.ligand.optionallabel.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY

    #optional inputs
    frame $w.ligand.optional
    set names {MOL2 TOP PSF PDB DCD}
    set types {mol2 top psf pdb dcd}
    foreach name $names type $types {
	frame $w.ligand.optional.$type
    	label $w.ligand.optional.$type.label -text "$name File:" -anchor w -width $::GOLEM::gui::labelWidth
    	entry $w.ligand.optional.$type.path -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::ligand$name 
    	button $w.ligand.optional.$type.button -text "Browse" -width $::GOLEM::gui::buttonWidth
    	grid $w.ligand.optional.$type.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    	grid $w.ligand.optional.$type.path -row 0 -column 1 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    	grid $w.ligand.optional.$type.button -row 0 -column 2 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    	grid columnconfigure $w.ligand.optional.$type 1 -weight 1
    }
    $w.ligand.optional.mol2.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::mol2Type]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandMOL2 $tempFile}
	}
    $w.ligand.optional.top.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::topType]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandTOP $tempFile}
	}
    $w.ligand.optional.psf.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::psfType]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandPSF $tempFile}
	}
    $w.ligand.optional.pdb.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::pdbType]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandPDB $tempFile}
	}
    $w.ligand.optional.dcd.button configure -command {
	    set tempFile [tk_getOpenFile -filetypes [subst $[subst ::GOLEM::gui::dcdType]]]
    	    if {![string equal $tempFile ""]} {set ::GOLEM::gui::ligandDCD $tempFile}
	}
    grid $w.ligand.optional.mol2 -row 0 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.optional.top -row 1 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.optional.psf -row 2 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.optional.pdb -row 3 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.optional.dcd -row 4 -column 0 -sticky we  -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.ligand.optional 0 -weight 1

    bind $w.ligand.optionallabel.label <Button-1> {
	switch $::GOLEM::gui::hideOptional {
	    1 {
		#optionalinputs were hiden, now expand
		.golemGui.ligand.optionallabel.label configure  -text "- Optional Files" -anchor w -width $::GOLEM::gui::largeLabelWidth
		grid .golemGui.ligand.optional -row 4 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
		set ::GOLEM::gui::hideOptional 0
		break
	    }
	    0 {
		#optionalinputs were expanded, now hide
		.golemGui.ligand.optionallabel.label configure  -text "+ Optional Files" -anchor w -width $::GOLEM::gui::largeLabelWidth
		grid forget .golemGui.ligand.optional
		set ::GOLEM::gui::hideOptional 1
		break
	    }
	}
    }
    bind $w.ligand.resname.entry <KeyPress> {::GOLEM::gui::check_resname}
    bind $w.ligand.resname.entry <KeyRelease> {::GOLEM::gui::check_resname}
    bind $w.ligand.resname.entry <FocusIn> {::GOLEM::gui::check_resname}
    bind $w.ligand.resname.entry <FocusOut> {::GOLEM::gui::check_resname}
    bind $w.ligand.resname.entry <Activate> {::GOLEM::gui::check_resname}

    grid $w.ligand.title -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.resname -row 1 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.additional -row 2 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.ligand.optionallabel -row 3 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    #grid $w.ligand.optional -row 4 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.ligand 0 -weight 1

    trace add variable ::GOLEM::gui::ligandMOL2 write ::GOLEM::gui::check_ligand_mol2
    trace add variable ::GOLEM::gui::ligandTOP write ::GOLEM::gui::check_ligand_top
    trace add variable ::GOLEM::gui::ligandPSF write ::GOLEM::gui::check_ligand_psf
    trace add variable ::GOLEM::gui::ligandPDB write ::GOLEM::gui::check_ligand_pdb
}

proc ::GOLEM::gui::build_parameters {} {
    variable w
    frame $w.parameters -relief ridge -bd $::GOLEM::gui::bd

    #title label
    frame $w.parameters.title
    label $w.parameters.title.label -text "Force Field Parameter Files" -anchor nw
    catch {::TKTOOLTIP::balloon $w.parameters.title.label "Please ensure you include the force field parameter files necessary for system simulation.\nIf the ligand's parameters are not included in the CHARMM36 force field, add the ligand's parameter file."}
    grid $w.parameters.title.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #files
    frame $w.parameters.files
    tablelist::tablelist $w.parameters.files.box -stretch all -background white -xscrollcommand [list $w.parameters.files.srl_x set] -yscrollcommand [list $w.parameters.files.srl_y set]  -showlabels False -showseparators True -height $::GOLEM::gui::tableHeight -listvariable ::GOLEM::gui::parFileList
    $w.parameters.files.box config -columns {1 "Parameter Files"}
    scrollbar $w.parameters.files.srl_y -command [list $w.parameters.files.box yview] -orient v
    scrollbar $w.parameters.files.srl_x -command [list $w.parameters.files.box xview] -orient h
    grid $w.parameters.files.box -row 0 -column 0 -sticky wens -padx $::GOLEM::gui::vbPadX 
    grid $w.parameters.files.srl_y -row 0 -column 1 -sticky ns 
    grid $w.parameters.files.srl_x -row 1 -column 0 -sticky we -padx $::GOLEM::gui::vbPadX
    grid columnconfigure $w.parameters.files 0 -weight 1

    #buttons
    frame $w.parameters.buttons
    button $w.parameters.buttons.add -text "Add" -width $::GOLEM::gui::buttonWidth -height $::GOLEM::gui::buttonHeight\
	-command {
	    set tempfiles [tk_getOpenFile -title "Select Parameters File(s)" -multiple 1 -filetypes $::GOLEM::gui::parType]
	    foreach tempfile $tempfiles {
		if {![string equal $tempfile ""]} {
		    #if {[lsearch [.golemGui.parameters.files.box get 0 end] $tempfile]<0} {
		    #    .golemGui.parameters.files.box insert end $tempfile
		    #}
		    if {[lsearch $::GOLEM::gui::parFileList $tempfile]<0} {
			lappend ::GOLEM::gui::parFileList $tempfile
		    }
		}
	    }
	}
    button $w.parameters.buttons.delete -text "Delete" -width $::GOLEM::gui::buttonWidth -height $::GOLEM::gui::buttonHeight\
	-command {
	    .golemGui.parameters.files.box delete [.golemGui.parameters.files.box curselection]
	}
    button $w.parameters.buttons.clear -text "Clear" -width $::GOLEM::gui::buttonWidth -height $::GOLEM::gui::buttonHeight\
	-command {
	    .golemGui.parameters.files.box delete 0 end
	}
    grid $w.parameters.buttons.add -row 0 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.parameters.buttons.delete -row 1 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.parameters.buttons.clear -row 2 -column 0 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    grid $w.parameters.title -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.parameters.files -row 1 -column 0 -columnspan 2 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.parameters.buttons -row 1 -rowspan 3 -column 2 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.parameters 0 -weight 1
}

proc ::GOLEM::gui::build_general {} {
    variable w
    frame $w.general -relief ridge -bd $::GOLEM::gui::bd

    #title label
    frame $w.general.title
    label $w.general.title.label -text "NAMD Settings" -anchor nw
    grid $w.general.title.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #setting
    frame $w.general.setting
    label $w.general.setting.outputLabel -text "Output Path:" -anchor w -width $::GOLEM::gui::labelWidth
    entry $w.general.setting.outputPath -width $::GOLEM::gui::entryWidth -textvariable ::GOLEM::gui::outDir
    button $w.general.setting.outputButton -text "Browse" -width $::GOLEM::gui::buttonWidth\
        -command {
            set tempDir [tk_chooseDirectory -title "Select an output folder"]
            if {![string equal $tempDir ""]} {set ::GOLEM::gui::outDir $tempDir}
        }
    label $w.general.setting.namdLabel -text "NAMD Path:" -anchor w -width $::GOLEM::gui::labelWidth
    entry $w.general.setting.namdPath -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::namdBin 
    button $w.general.setting.namdButton -text "Browse" -width $::GOLEM::gui::buttonWidth\
        -command {
            set tempFile [tk_getOpenFile -filetypes $::GOLEM::gui::allType]
            if {![string equal $tempFile ""]} {set ::GOLEM::gui::namdBin $tempFile}
        }
    label $w.general.setting.namdOptLabel -text "NAMD Options:" -anchor w -width $::GOLEM::gui::labelWidth
    entry $w.general.setting.namdOptPath -width $::GOLEM::gui::entryWidth -text "" -textvariable ::GOLEM::gui::namdOpt 

    grid $w.general.setting.outputLabel -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general.setting.outputPath -row 0 -column 1 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general.setting.outputButton -row 0 -column 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general.setting.namdLabel -row 1 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general.setting.namdPath -row 1 -column 1 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general.setting.namdButton -row 1 -column 2 -sticky we -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general.setting.namdOptLabel -row 2 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY 
    grid $w.general.setting.namdOptPath -row 2 -column 1 -columnspan 2 -sticky we
    grid columnconfigure $w.general.setting 1 -weight 1

    grid $w.general.title -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.general.setting -row 1 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.general 0 -weight 1
}

proc ::GOLEM::gui::build_setting {} {
    variable w
    frame $w.setting -relief ridge -bd $::GOLEM::gui::bd

    #title label
    frame $w.setting.title
    label $w.setting.title.label -text "Docking Settings" -anchor nw
    grid $w.setting.title.label -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #two coupling factor
    frame $w.setting.coupling
    label $w.setting.coupling.ligandLabel -text "Ligand-map Coupling Factor:" -anchor w
    catch {::TKTOOLTIP::balloon $w.setting.coupling.ligandLabel "How strong the ligand is coupled to the experimental map during docking. Default is 6."}
    entry $w.setting.coupling.ligandEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::ligandCoupFactor -validate all -validatecommand {expr {[string is double %P]}}
    label $w.setting.coupling.waterLabel -text "Water-map Coupling Factor:" -anchor w
    catch {::TKTOOLTIP::balloon $w.setting.coupling.waterLabel "How strong water molecules are coupled to the experimental map during docking. Default is 3."}
    entry $w.setting.coupling.waterEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::waterCoupFactor -validate all -validatecommand {expr {[string is double %P]}}
    grid $w.setting.coupling.ligandLabel -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.coupling.ligandEntry -row 0 -column 1 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.coupling.waterLabel -row 1 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.coupling.waterEntry -row 1 -column 1 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #max wate number
    frame $w.setting.water
    label $w.setting.water.waterNumLabel -text "Number of water molecules:" -anchor w
    catch {::TKTOOLTIP::balloon $w.setting.water.waterNumLabel "Number of water molecules to be added into the docking box during docking."}
    entry $w.setting.water.waterNumEntry -width $::GOLEM::gui::smallEntryWidth -textvariable ::GOLEM::gui::waterMaxNum -validate all -validatecommand {expr {[string is int %P]}}
    grid $w.setting.water.waterNumLabel -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.water.waterNumEntry -row 0 -column 1 -sticky w -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    #side chain fix or flexible
    frame $w.setting.sidechain
    radiobutton $w.setting.sidechain.fixed -text "Fixed Side Chains" -variable ::GOLEM::gui::fixedSidechain -value 1 -anchor e
    catch {::TKTOOLTIP::balloon $w.setting.sidechain.fixed "Fix coordinates of receptor's side chains during docking."}
    radiobutton $w.setting.sidechain.flexible -text "Flexible Side Chains" -variable ::GOLEM::gui::fixedSidechain -value 0 -anchor e
    catch {::TKTOOLTIP::balloon $w.setting.sidechain.flexible "Allow receptor's side chains to move during docking.\nSide chains will be coupled to the experimental map."}
    $w.setting.sidechain.fixed select
    grid $w.setting.sidechain.fixed -row 0 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.sidechain.flexible -row 1 -column 0 -sticky w -padx $::GOLEM::gui::vbPadX -pady $::GOLEM::gui::vsepPadY

    grid $w.setting.title -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.coupling -row 1 -column 1 -rowspan 2 -sticky ne -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.water -row 1 -column 2 -sticky ne -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.setting.sidechain -row 1 -column 0 -rowspan 2 -sticky nw -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.setting 1 -weight 1 
    grid columnconfigure $w.setting 2 -weight 1 
}

proc ::GOLEM::gui::build_buttons {} {
    variable w
    frame $w.buttons -relief ridge -bd $::GOLEM::gui::bd

    button $w.buttons.prepare -text "Prepare" -state normal -command ::GOLEM::gui::prepare
    catch {::TKTOOLTIP::balloon $w.buttons.prepare "Prepare essential files using provided information to perform docking. Must do Prepare before Run."}
    button $w.buttons.run -text "Run!" -state normal -command ::GOLEM::run::run

    trace add variable ::GOLEM::gui::readyToRun write ::GOLEM::gui::ready_status

    grid $w.buttons.prepare -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::largevsepPadY
    grid $w.buttons.run -row 1 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::largevsepPadY
    $w.buttons.run config -state disabled
    grid columnconfigure $w.buttons 0 -weight 1
}

proc ::GOLEM::gui::build_console {} {
    variable  w
    frame $w.console -relief ridge -bd $::GOLEM::gui::bd

    label $w.console.status -text "IDLE" -anchor w
    #text $w.console.output -height $::GOLEM::gui::tableHeight -yscrollcommand "$w.console.srl_y set"
    tablelist::tablelist $w.console.output -height $::GOLEM::gui::tableHeight -stretch all -background white -xscrollcommand "$w.console.srl_x set" -yscrollcommand "$w.console.srl_y set" -showseparators true -selecttype cell
    $w.console.output config -columns {1 "Iteration" 1 "1st" 1 "2nd" 1 "3rd" 1 "4th" 1 "5th" 1 "6th" 1 "7th" 1 "8th" 1 "9th" 1 "10th"}
    scrollbar $w.console.srl_y -command "$w.console.output yview" -orient v
    scrollbar $w.console.srl_x -command "$w.console.output xview" -orient h
    #bind $w.console.output <<TablelistSelect>> [list ::GOLEM::gui::output_selected %W]
    bind $w.console.output <<ListboxSelect>> [list ::GOLEM::gui::output_selected %W]

    frame $w.console.buttons
    button $w.console.buttons.save -text "Save as pdb/psf" -state normal -command {::GOLEM::gui::save_selected_pose .golemGui.console.output}
    catch {::TKTOOLTIP::balloon $w.console.buttons.save "Save the selected pose as pdb/psf files."}
    button $w.console.buttons.abort -text "Abort" -state normal -command {::GOLEM::gui::abort}
    catch {::TKTOOLTIP::balloon $w.console.buttons.abort "Abort docking."}
    grid $w.console.buttons.save -row 0 -column 0 -sticky e -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.console.buttons.abort -row 0 -column 1 -sticky e -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    grid $w.console.status -row 0 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.console.output -row 1 -column 0 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.console.srl_y -row 1 -column 1 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid $w.console.srl_x -row 2 -column 0 -columnspan 2 -sticky nsew -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY

    grid $w.console.buttons -row 3 -column 0 -columnspan 2 -sticky e -padx $::GOLEM::gui::vsepPadX -pady $::GOLEM::gui::vsepPadY
    grid columnconfigure $w.console 0 -weight 1
}
