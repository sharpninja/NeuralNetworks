FUTURE COMPUTING: NEURAL NETWORKS - C64 PROGRAMS
Kevin E. Martin, COMPUTE!'s Gazette, January-March 1990

These five PRG files were extracted unchanged from archived magazine disk
images using VICE c1541 3.10. Their original C64 load-address headers are
included. No OCR reconstruction, retokenization, or program changes were made.
Part 1 (January) contains no type-in programs for this series.

FILES

Host filename    C64 disk filename    Purpose                         Load address
BP.ML.prg        BP.ML                Backpropagation engine          $C000
XOR.prg          XOR                  Exclusive-OR example           $0801
ENCODE.prg       ENCODE               Encoding example                $0801
CL.ML.prg        CL.ML                Competitive-learning engine     $C000
DIPOLE.prg       DIPOLE               Graph-partitioning example      $0801

BP.ML, XOR, and ENCODE are from the February 1990 disk (Part 2).
CL.ML and DIPOLE are from the March 1990 disk (Part 3).

LOADING

The accompanying Neural-Networks-C64.d64 already contains all five files
with their required C64 filenames. Mount it as device 8.

If importing the separate PRGs into another disk, use the C64 disk filenames
shown above. The .prg suffix is a host-computer extension: do not include it
in the filenames stored inside the C64 disk image.

With that disk mounted as device 8, load ONE example and run it:

LOAD"XOR",8
RUN

or

LOAD"ENCODE",8
RUN

or

LOAD"DIPOLE",8
RUN

XOR and ENCODE load BP.ML automatically; DIPOLE loads CL.ML automatically.
The matching machine-language file must be available on device 8.
The machine-language engines are companion files, not standalone BASIC programs.

SOURCES

February disk: 1990-02-good.d64
https://commodore.bombjack.org/commodore/disks/magazines/compute-gazette/1990-02-good.d64

March disk: 1990-03.d64 inside the archived disk collection
https://commodore.bombjack.org/commodore/disks/magazines/compute-gazette/Compute!'s_Gazette_Disks_(04-21-2024).zip

Collection page:
https://commodore.bombjack.org/commodore/magazines-disk/compute-gazette/compute-gazette-disk.htm

VERIFICATION

All five extracted files were independently checked byte-for-byte against
their source D64 sector chains. Load addresses were checked for all five,
and the BASIC line links were checked in XOR, ENCODE, and DIPOLE.
SHA256SUMS.txt contains the hashes of the five PRGs.
The programs were not executed in an emulator during this extraction.
