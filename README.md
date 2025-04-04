# GOLEM
GOLEM (Genetic Optimization of Ligands in Experimental Maps) provides an automated and robust way to perform cryo-EM-guided ligand docking with explicit water molecules. It employs a Lamarckian genetic algorithm to explore the ligand's conformational, orientational, and positional space, with explicit consideration of water displacement and bridging water molecules' position and orientation. GOLEM takes into account both energetics and the correlation with electron density maps in its scoring function, which combines the system's energy and the energy of the ligand in a cryo-EM-derived external potential.

## Publication
For detailed information about the method, please refer to the paper:  
[GOLEM: Cryo-EM-Guided Ligand Docking with Explicit Water Molecules](https://pubs.acs.org/doi/10.1021/acs.jcim.4c00917)

## Download and Installation (Linux)
Download the code within GOLEM to your desired location. A brief tutorial and an example case are also included.

Add the following two lines of code to your .vmdrc file (usually found as ~/.vmdrc).
```
lappend auto_path /WHERE/YOU/EXTRACTED/THE/CODE/GOLEM
vmd_install_extension golem golem "Modeling/GOLEM"
```

**Note**: You must have the line: `menu main on` in your .vmdrc file for VMD to work properly.

Open VMD, click Extensions>Modeling>GOLEM to see if it works.

## The Graphical User Interface
Generally, the user will need to provide a density map, PSF and PDB files of the receptor, PSF, PDB, and parameter files (if not presented in the standard CHARMM force field) of the ligand to be docked. While GOLEM is designed to dock one ligand molecule each time, the receptor may contain any other molecules (e.g., other bound ligands, ions) as long as additional parameter files are provided. Alternative inputs are possible provided they are sufficient to generate all the aforementioned files.

### Input Files

#### Experimental Map
- **Map File**: select the experimental map file. Supported file extensions are .mrc, .map, .dx, .ccp4, and .situs.

#### Receptor
- **PDB File or PDBID**: select the .pdb file of the receptor, or provide the PDB ID for GOLEM to fetch the pdb file. The receptor should not contain the ligand to be docked.
- **PSF File**: select the .psf file of the receptor. If not provided, GOLEM will try generating a psf file using VMD plugin QwikMD during the preparation phase.
- **Include Water Found in PDB**: if checked, water molecules that fall within the docking box will be kept and coordinates of oxygen atoms will be fixed; otherwise, these water molecules will be removed.
- **Optimize Water Orientation**: if checked, orientations of water molecules within the docking box will be optimized; otherwise, their coordinates will be fixed.

#### Ligand
<!-- - **Ligand type**: choose between "Small-molecule Ligand" and "Peptide Ligand". The graphical user interface will update accordingly.-->
- **Lig Resname/Peptide Seq**: resname of the ligand, or the sequence of the peptide ligand to be docked. The graphical user interface will update automatically to require essential input files. To provide optional files, click "Optional Files" to expand.
- **MOL2 File**: select the .mol2 file of the ligand.
- **TOP File**: select the topology file of the ligand. Supported file extensions are .top, .rtf, .inp, and .str.
- **PSF File**: select the .psf file of the ligand.
- **PDB File**: select the .pdb file of the ligand.
- **DCD file**: select the .dcd file of the ligand. It will serve as the initial ligand conformation library.

#### Parameter Files
Force field parameter files used by NAMD to calculate energetics.

### Settings

#### Docking Box
Define a docking box within which the ligand pose will be explored.
- **Min/Max X/Y/Z**: define the minimum/maximum X/Y/Z values (in Ångström) of the docking box.
- **Define From Atomselection**: the docking box dimensions can be automatically determined based on an atom selection in the receptor. Provide the atom selection text and click the "Measure" button.

#### Docking Settings
- **Fixed/Flexible Side Chains**: specify whether the receptor side chains within the docking box are allowed to move. Backbone atoms are always fixed.
- **Ligand-map Coupling Factor**: specify how tight the ligand is coupled to the map (default 6).
- **Water-map Coupling Factor**: specify how tight the water molecules are coupled to the map (default 4).
- **Maximum number of water molecules**: maximum number of water molecules to be added within the docking box (default 32).

#### NAMD Settings
- **Output Path**: specify the root folder where all related files will be placed. The folder will be created if it doesn't exist.
- **NAMD Path**: specify the absolute path to the NAMD executable.
- **NAMD options**: additional NAMD running options. You may need to modify these options to maximize calculation speed and ensure compatibility.

### Run
- **Prepare**: the plugin will perform a sanity check to determine if all required files are provided and generate essential intermediate files if needed.
- **Run!**: the plugin will execute the docking process in the current VMD session, automatically running all necessary NAMD calculations in the background. This button is only clickable after passing the sanity check during preparation.
- **Status bar**: displays the current status of the docking process.

The table below the status bar lists the scores of the top 10 poses in each iteration. Click to visualize the docking pose in VMD in real-time.
