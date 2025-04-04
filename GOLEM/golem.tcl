package provide golem 1.0

#package require HungarianAlgorithm; make it part of golem
package require psfgen
package require readcharmmpar
package require readcharmmtop
package require topotools
package require volutil
package require mdff
package require molefacture
package require forcefieldtoolkit

if {$::tcl_version < 8.5} {
    package require dict
}

namespace eval ::GOLEM:: {
    namespace export golem
}

source [file join $env(GOLEMDIR) golem_run.tcl]
source [file join $env(GOLEMDIR) golem_run_rotamer.tcl]
source [file join $env(GOLEMDIR) golem_run_GA.tcl]
#source [file join $env(GOLEMDIR) golem_hungarian.tcl]

catch {package require tktooltip}
source [file join $env(GOLEMDIR) golem_gui_interface.tcl]
source [file join $env(GOLEMDIR) golem_gui_procs.tcl]

proc golem_tk {} {
    ::GOLEM::golem
    return $::GOLEM::gui::w
}
