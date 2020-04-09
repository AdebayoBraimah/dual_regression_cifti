#!/usr/bin/env bash

# Re-compile mex files to be compatible with anoter version of GNU Octave.
# This link contained the relative information: https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;e6eae2bd.1903

# PALM directory
PALMDIR=${1}

# 4 Various files need to be compiled for compatibility with the local system (OCTAVE in my case).

cd ${PALMDIR}/fileio/@file_array/private
./compile.sh

cd ${PALMDIR}/fileio/@gifti/private
./compile.sh

# Recompile *.mex files to make compatible with Octave
# * Files Not needed in a Linux system
# rm *.mexw32 --> windows32 files
# rm *.mexw64 --> windows64 files
# rm *.mexmaci64 --> mac files

# Below is my inefficient, but conceptually simple re-compiling steps

cd ${PALMDIR}/fileio/@file_array/private/
rm *.mex
mkoctfile --mex mat2file.c
mkoctfile --mex init.c
mkoctfile --mex file2mat.c

cd ${PALMDIR}/fileio/@gifti/private/
rm *.mex
mkoctfile --mex zstream.c
mkoctfile --mex miniz.c

cd ${PALMDIR}/fileio/@nifti/private/
rm *.mex
mkoctfile --mex nifti_stats_mex.c
mkoctfile --mex nifti_stats.c

cd ${PALMDIR}/fileio/@xmltree/private/
rm *.mex
mkoctfile --mex xml_findstr.c

# Remove all spm_existfile.* files  Or recompile
cd ${PALMDIR}/fileio/extras/
rm *.mex
mkoctfile --mex spm_existfile.c