#!/usr/bin/env bash
# 
# -*- coding: utf-8 -*-
# title           : dual_regression_cifti.sh
# description     : [description]
# author          : Adebayo B. Braimah
# e-mail          : adebayo.braimah@cchmc.org
# date            : 2020 02 18 17:31:22
# version         : 0.0.1
# usage           : dual_regression_cifti.sh [-h,--help]
# notes           : [notes]
# bash_version    : 5.0.7
#==============================================================================

#
# Define Usage & (Miscellaneous) Function(s)
#==============================================================================

Usage() {
  cat << USAGE

  Usage: $(basename ${0}) -i <image> -o <out_dir> -f <list.txt> -tsL <left_surf_template> -tsR <right_surf_template>

Performs FSL's dual regression for CIFTI files in addition to permutation based analyses.

Required arguements:

-i, -ics, --ica-maps          Input CIFTI dscalar IC maps
-f, -files, --file-list       Text file list of CIFTI dtseries subject files
-o, -out, --out-dir           Output directory
-tsL, --template-surf-L       Template midthickness (left) surface
-tsR, --template-surf-R       Template midthickness (right) surface

Optional arguements:

-j, -jobs, --jobs             Number of jobs that can be run in parallel.
                              The default varies per system and is defined as 
                              N-1 the maximum number of cores available. [default: $(expr $(getconf _NPROCESSORS_ONLN) - 1)]
-sL, --surf-list-L            Text file list of subject left midthickness surface files
-sR, --surf-list-R            Text file list of subject right midthickness surface files
--atlas-dir                   Surface template atlas directory. If specified, then the 
                              '--template-surf-L' and '--template-surf-R' options do not
                              need to be specified. Atlas directory name and layout are expected
                              to be similar to that of the HCP S1200 fs_LR atlas(es).
--no-stats-cleanup            No clean-up of PALM's IC map sub-directory will be done
--convert-all                 Converts all output files from (fake) NIFTI-1 images to CIFTI (recommended)

Dual Regression specific arguements:

-des, --des-norm              Whether to variance-normalise the timecourses used as the stage-2 regressors (recommended)
-d, -design, --design         Design matrix for final cross-subject modelling with PALM
-c, -contrast, --t-contrast   Design t-contrast for final cross-subject modelling with PALM
-f, --f-contrast              Design F-contrast for final cross-subject modelling with PALM
-n, -nperm, --permutations    Number of permutations for PALM. If not set or set to 0, then
                              permutations are performed exhaustively.
--thr                         Perform thresholded dual regression to obtain unbiased timeseries for connectomics 
                              analyses (e.g., with FSLnets)

PALM specific arguements:

--fdr                         Produce FDR-adjusted p-values.
--f-only                      Run only the F-contrasts, not the t-contrasts.
--save1-p                     Save (1-p) instead of the actual p-values (mutually exclusive with '--log-p').
--log-p                       Save the output p-values as -log(p) (mutually exclusive with '--save1-p', recommended).
--two-tail                    Run two-tailed tests for all the t-contrasts instead of one-tailed.
--demean                      Mean center the data, as well as all columns of the design matrix. If the design has 
                              an intercept, the intercept is removed.
--sig                         Significance threshold for statistical thresholding [default: 0.05]
--method                      Method used for determining corrected cifti-stat threshold. 
                              Valid options include: Bonferroni ('bonf') and Šidák ('sid') [default: bonf]
--precision                   Precision for input files ('single' or 'double')

LSF specific arguements:

--mem, --memory               The amount of memory to be used when submitting jobs for PALM (in MB) [default: 5000]
--wall                        The amount of wall-time to be allocated to each job for PALM (in hours) [default: 100]
-q, --queue                   LSF queue name to submit jobs to (, look up queue names with the command 'bqueues') [default: normal]
--resub                       Re-submit LSF jobs in the case of initial job failure [default: false]

----------------------------------------

-h,-help,--help     Prints usage and exits.

NOTE:
- Requires bash v4.0+
- Requires FSL v5.0.11+
- Requires Connectome Workbench v1.2.0+
- Requires FSL's PALM version alpha115+
- Requires GNU parallel to be installed and
  added to system path
- Default LSF arguements are unlikely to result 
  in all PALM jobs running to completion.
- Output statistics files from PALM are automatically
  thresholded.
    - In the case that the '--two-tail' option is used
      but neither the '--log-p' or '--save1-p' option 
      is used, then the output statistics files will only
      show one-tailed results (due to hardcoded settings)
- Not providing any design matix, t-contrasts, or F-contrasts
  will automatically run a 1-sample t-test in PALM, testing for
  both positive and negative correlations.

----------------------------------------

Adebayo B. Braimah - 2020 02 18 17:31:22

$(basename ${0}) v0.0.1

----------------------------------------

  Usage: $(basename ${0}) -i <image> -o <out_dir> -f <list.txt> -tsL <left_surf_template> -tsR <right_surf_template>

USAGE
  exit 1
}

readme_palm_cmds(){
  # Writes a text file of example commands passed 
  # to PLAM to some output directory provided a 
  # filename and several example commands.

  # local PALM_CMD_vol=${1}
  # local PALM_CMD_surf_L=${2}
  # local PALM_CMD_surf_R=${3}
  local readme=${1}
  local alpha=${2}
  local approach=${3}
  local method=${4}
  local threshold=${5}
  local vars=${@}

cat <<- read_palm > ${readme}

This directory contains the outputs of dual regression of CIFTI-2 files (performed via dual_regression_cifti).
Dual regression was performed using fsl_glm with cifti-converted NIFTI-1 images. The resulting output images
were then converted back to CIFTI-2 file format.

Cross subject modeling was performed via FSL's PALM with the following commands:

1. Split the CIFTI-2 file into volumetric and surface metric files:
    
    wb_command -cifti-separate <file>.dscalar.nii COLUMN -volume-all <vol>.nii -metric CORTEX_LEFT <metric>.L.func.gii -metric CORTEX_RIGHT <metric>.R.func.gii

2. PALM commands used in this analysis

    ${vars}

ASIDE:  As the statistics for the surfaces and the volumetric data were performed separately, the statistical threshold also needs to reflect this analysis. As a
        result - the corrected statistical threshold for alpha=${alpha} with ${approach} using the ${method} correction method is ${threshold}. The output maps should reflect this change.
        See the note at the bottom for additional details/references.

NOTE:
- Threshold Free Cluster Enhancment (TFCE) was enabled and applied in this analysis (for both volumetric and surface metric analyses)
- Should the option '-save1-p' have been used, then the output results can be thresholded similarly to the outputs from randomise
- Should the option '-logp' have been used, then the output results will be log(p) transformed. This usually helps with visualization.
  - For results thresholding with this option, see the FSL PALM User guide: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/PALM/Examples#Example_10:_Using_CIFTI_files
read_palm
}

write_surf_to_spec() {

  # Function usage (does not print to command line)
  # This (helper) function writes surfaces to a 
  # provided spec file.
  # 
  # Input arguments:
  # --atlas-dir: T2w image (anat)
  # --spec-file: corresponding T1w image

  # Parse options
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      --atlas-dir) shift; local atlas_dir=${1} ;;
      --spec-file)shift; local spec_file=${1} ;;
      -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; ;;
      *) break ;;
    esac
    shift
  done

  for h in L R; do
    # Get additional surfaces
    inf=$(ls ${atlas_dir}/*${h}.inflated*surf.gii)
    pial=$(ls ${atlas_dir}/*${h}.pial*surf.gii)
    v_inf=$(ls ${atlas_dir}/*${h}.very_inflated*surf.gii)
    white=$(ls ${atlas_dir}/*${h}.white*surf.gii)

    surfs=( ${inf} ${pial} ${v_inf} ${white} )

    if [[ ${h} = "L" ]]; then
      hemi="LEFT"
    elif [[ ${h} = "R" ]]; then
      hemi="RIGHT"
    fi

    for surf in ${surfs[@]}; do
      wb_command -add-to-spec-file ${spec_file} CORTEX_${hemi} ${surf}
    done
  done
}

scale_palette(){
  # 
  # Function that re-scales palette information for 
  # a cifti group statistics file. Many of the options
  # are hard-coded as the specific scenarios targeted are
  # few. Additionally, only values outside the specified 
  # thresholds are shown (to accomodate situations in which
  # log(p) values are shown - with the significance range 
  # being log(p) < inf). 
  # 
  # Usage: scale_palette --file <file> --sig <alpha> | --file <file> --min <float> --max <float>
  # 
  # file (cifti file): Input cifti group statistics file to be rescaled
  # max (float): Maximum value to be re-scaled (not inclusive)
  # min (float, optional): Minimum value to be re-scaled (not inclusive) [default: 0]

  # Set defaults
  local min=0
  local max=""

  # Parse options
  while [[ ${#} -gt 0 ]]; do
    case "${1}" in
      -f|--file) shift; local file=${1} ;;
      --min) shift; local min=${1} ;;
      --max) shift; local max=${1} ;;
      -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; Usage; ;;
      *) break ;;
    esac
    shift
  done

  if [[ -z ${file} ]] || [[ -z ${max} ]]; then
    echo "Required: file and max value"
  fi

  # Init additional variables
  local dir=$(dirname $(realpath ${file}))
  local filename=$(basename ${file})
  local name=${RANDOM}_${filename}

  # wb_command -cifti-palette ${file} MODE_AUTO_SCALE ${dir}/${name} -neg-user 0 0 -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE ${min} ${max}
  wb_command -cifti-palette ${file} MODE_AUTO_SCALE ${dir}/${name} -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE ${min} ${max}

  mv ${dir}/${name} ${file}
}

#
# Define Logging Function(s)
#==============================================================================

# Echoes status updates to the command line
echo_color(){
  msg='\033[0;'"${@}"'\033[0m'
  # echo -e ${msg} >> ${stdOut} 2>> ${stdErr}
  echo -e ${msg} 
}
echo_red(){
  echo_color '31m'"${@}"
}
echo_green(){
  echo_color '32m'"${@}"
}
echo_blue(){
  echo_color '36m'"${@}"
}

#
# Parse command line
#==============================================================================

if [[ ${#} -lt 1 ]]; then
  Usage >&2
  exit 1
fi

# Store command line input for logging
ORIG_COMMAND=${*}

# Set defaults
scripts_dir=$(dirname $(realpath ${0}))
DES_NORM=""
jobs=$(expr $(getconf _NPROCESSORS_ONLN) - 1) # N-1 number of cores - works on bash v3.0+
NAF2=0
convert_all=false
one_sample=false

# PALM runtime defaults
fdr=false 
fonly=false 
save1_p=false 
log_p=false 
twotail=false 
demean=false 
stat_cleanup=true
sig=0.05
method=bonf
precis=""

# LSF defaults
wall=100
mem=5000
queue=normal
resub=false

# Parse options
while [[ ${#} -gt 0 ]]; do
  case "${1}" in
    -i|-ics|--ica-maps) shift; ICA_MAPS=${1} ;;
    -des|--des-norm) DES_NORM="--des_norm" ;;
    -d|-design|--design) shift; dm=${1} ;;
    -c|-contrast|--t-contrast) shift; dc=${1} ;;
    -f|--f-contrast) shift; df=${1} ;;
    -n|-nperm|--permutations) shift; NPERM=${1} ;;
    --thr) NAF2=1 ;;
    -j|-jobs|--jobs) shift; jobs=${1} ;;
    -o|-out|--out-dir) shift; OUTPUT=${1} ;;
    -f|-files|--file-list) shift; file_list=${1} ;;
    -sL|--surf-list-L) shift; surf_list_L=${1} ;;
    -sR|--surf-list-R) shift; surf_list_R=${1} ;;
    -tsL|--template-surf-L) shift; template_surf_L=${1} ;;
    -tsR|--template-surf-R) shift; template_surf_R=${1} ;;
    --atlas-dir) shift; atlas_dir=${1} ;;
    --fdr) fdr=true ;;
    --f-only) fonly=true ;;
    --save1-p) save1_p=true ;;
    --log-p) log_p=true ;;
    --two-tail) twotail=true ;;
    --demean) demean=true ;;
    --convert-all) convert_all=true ;;
    --no-stats-cleanup) stat_cleanup=false ;;
    --precision) shift; precis=${1} ;;
    --sig) shift; sig=${1} ;;
    --method) shift; method=${1} ;;
    --mem|--memory) shift; mem=${1} ;;
    --wall) shift; wall=${1} ;;
    --resub) resub=true ;;
    -q|--queue) shift; queue=${1} ;;
    -h|-help|--help) Usage; ;;
    -*) echo_red "$(basename ${0}): Unrecognized option ${1}" >&2; Usage; ;;
    *) break ;;
  esac
  shift
done

#
# Dependency checks
#==============================================================================

if ! hash fsl_glm 2>/dev/null; then
  echo_red "FSL is not installed or added to the system path. Please check. Exiting..."
  exit 1
fi

if ! hash wb_command 2>/dev/null; then
  echo_red "Connectome workbench is not installed or added to the system path. Please check. Exiting..."
  exit 1
fi

if ! hash matlab 2>/dev/null; then
  if ! hash octave 2>/dev/null; then
    echo_red "Neither MATLAB nor Octave is installed or added to the system path. Please check. Exiting..."
    exit 1
  fi
fi

if ! hash palm 2>/dev/null; then
  echo_red "FSL's PALM is not added to the system path or configured correctly. Please check. Exiting..."
  exit 1
fi

if ! hash parallel 2>/dev/null; then
  echo_red "GNU parallel is not installed or added to the system path. Please check. Exiting..."
  exit 1
fi

#
# File Fidelity Checks and Option Validation
#==============================================================================

# Required Arguments
if [[ ! -f ${ICA_MAPS} ]] || [[ -z ${ICA_MAPS} ]]; then
  echo_red "Input Error: Required - ICA maps were not passed as an argument or do not exist. Please check. Exiting..."
  exit 1
else
  ICA_MAPS=$(realpath ${ICA_MAPS})
  ICA_MAPS_CIFTI=${ICA_MAPS}
fi

if [[ -z ${OUTPUT} ]]; then
  echo_red "Input Error: Required - Output directory was not passed as an argument. Please check. Exiting..."
  exit 1
# else
#   touch ${OUTPUT}
#   OUTPUT=$(realpath ${OUTPUT})
#   rm ${OUTPUT}
fi

if [[ ! -f ${file_list} ]] || [[ -z ${file_list} ]]; then
  echo_red "Input Error: Required - File list of subject CIFTI files were not passed as an argument or do not exist. Please check. Exiting..."
  exit 1
else
  file_list=$(realpath ${file_list})
fi

## Check for surface templates
if [[ ! -z ${atlas_dir} ]] && [[ -d ${atlas_dir} ]]; then
  atlas_dir=$(realpath ${atlas_dir})
elif [[ ! -z ${atlas_dir} ]] && [[ ! -d ${atlas_dir} ]]; then
  echo_red "Input Error: Surface atlas directory was specified, but it does not exist. Please check. Exiting..."
  exit 1
else
  if [[ ! -z ${template_surf_L} ]] && [[ -f ${template_surf_L} ]] && [[ ! -z ${template_surf_R} ]] && [[ -f ${template_surf_R} ]]; then
    template_surf_L=$(realpath ${template_surf_L})
    template_surf_R=$(realpath ${template_surf_R})
  elif [[ ! -z ${template_surf_L} ]] && [[ ! -f ${template_surf_L} ]] || [[ ! -z ${template_surf_R} ]] && [[ ! -f ${template_surf_R} ]]; then
    echo_red "Input Error: Required - Template surfaces were either not specified or do not exist. Please check. Exiting..."
  fi
fi

# Optional arguments
if [[ ! -z ${dm} ]] && [[ ! -f ${dm} ]]; then
  echo_red "Input Error: Design matrix was specified but does not exist. Please check. Exiting..."
  exit 1
elif [[ ! -z ${dm} ]]; then
  dm=$(realpath ${dm})
fi

if [[ ! -z ${dc} ]] && [[ ! -f ${dc} ]]; then
  echo_red "Input Error: Design contrast was specified but does not exist. Please check. Exiting..."
  exit 1
elif [[ ! -z ${dc} ]]; then
  dc=$(realpath ${dc})
fi

if [[ ! -z ${df} ]] && [[ ! -f ${df} ]]; then
  echo_red "Input Error: Design F-contrast was specified but does not exist. Please check. Exiting..."
  exit 1
elif [[ ! -z ${df} ]]; then
  df=$(realpath ${df})
fi

if [[ ${method,,} != "bonf" ]] && [[ ${method,,} != "sid" ]]; then
  echo_red "Stats correction error: Correction method should be either 'bonf' or 'sid'. Exiting..."
  exit 1
fi

if [ ! -z ${sig} ]; then
  if ! [[ "${sig}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
          echo_red "Significance threshold argument requires floats [0.000001 - 999999.0]"
          exit 1
  fi
fi

if [[ ! -z ${NPERM} ]]; then
 if ! [[ "${NPERM}" =~ ^[0-9]+$ ]]; then
          echo_red "Input Error: Number of permutations requires integers only [1-9999999]"
          exit 1
  fi
fi

if [[ ! -z ${precis} ]]; then
  if [[ ${precis,,} != "single" ]] || [[ ${precis,,} != "double" ]]; then
    echo_red "PALM Input Error: Invalid precision option - valid options include: 'single' or 'double'. Exiting..."
  fi
fi

if [[ ! -z ${jobs} ]]; then
 if ! [[ "${jobs}" =~ ^[0-9]+$ ]]; then
          echo_red "Input Error: Number of jobs requires integers only [1-99]"
          exit 1
  fi
fi

if [[ ! -z ${mem} ]]; then
 if ! [[ "${mem}" =~ ^[0-9]+$ ]]; then
          echo_red "LSF Error: The amount of memory (MB) requires integers only [1-999999]"
          exit 1
  fi
fi

if [[ ! -z ${wall} ]]; then
 if ! [[ "${wall}" =~ ^[0-9]+$ ]]; then
          echo_red "LSF Error: The amount of wall-time (hours) requires integers only [1-999999]"
          exit 1
  fi
fi

# if [[ -z ${queue} ]]; then
#   echo_red "LSF Error: No queue name was specified. Please check. Exiting..."
#   exit 1
# elif [[ ! -z ${queue} ]]; then
#   if [[ ${queue,,} = "normal" ]] || [[ ${queue,,} = "long" ]] || [[ ${queue,,} = "low" ]]; then
#     queue=${queue,,}
#   else
#     echo_red "LSF Error: Queue name specified is not in queue list. Submitting jobs to normal queue."
#     queue=normal
# fi

if [[ -z ${queue} ]]; then
  queue=normal
fi

if [[ ! -z ${surf_list_L} ]] && [[ ! -f ${surf_list_L} ]]; then
  echo_red "Input Error: Left subject surface list was specified but does not exist. Please check. Exiting..."
  exit 1
elif [[ ! -z ${surf_list_L} ]]; then
  surf_list_L=$(realpath ${surf_list_L})
fi

if [[ ! -z ${surf_list_R} ]] && [[ ! -f ${surf_list_R} ]]; then
  echo_red "Input Error: Right subject surface list was specified but does not exist. Please check. Exiting..."
  exit 1
elif [[ ! -z ${surf_list_R} ]]; then
  surf_list_R=$(realpath ${surf_list_R})
fi

if [[ ${save1_p} = "true" ]] && [[ ${log_p} = "true" ]]; then
  echo_red "Mutually exclusive arguements have been specified. Both '--save1-p' and '-log-p' cannot be used. Exiting... "
  exit 1
fi

#
# Dual Regression setup
#==============================================================================

cwd=$(pwd)
LOGDIR=${OUTPUT}/scripts+logs

if [[ ! -d ${OUTPUT} ]] && [[ ! -d ${LOGDIR} ]]; then
  mkdir -p ${OUTPUT}
  mkdir -p ${LOGDIR}
fi

OUTPUT=$(realpath ${OUTPUT})
echo "${0} ${ORIG_COMMAND}" > ${LOGDIR}/command

#
# CIFTI setup 1
#==============================================================================

mapfile -t files < ${file_list}

if [[ ! -z ${surf_list_L} ]] && [[ ! -z ${surf_list_R} ]]; then
  mapfile -t surf_L < ${surf_list_L}
  mapfile -t surf_R < ${surf_list_R}
fi

# Copy over the necessary files
# Design files
DESIGN=""
if [[ ! -z ${dm} ]]; then
  cp ${dm} ${OUTPUT}/design.mat
  dm=${OUTPUT}/design.mat
  DESIGN+="-d ${dm} "
fi

if [[ ! -z ${dc} ]]; then
  cp ${dc} ${OUTPUT}/design.con
  dc=${OUTPUT}/design.con
  DESIGN+="-t ${dc} "
fi

if [[ ! -z ${df} ]]; then
  cp ${df} ${OUTPUT}/design.fts
  df=${OUTPUT}/design.fts
  DESIGN+="-f ${df} "
fi

if [[ -z ${DESIGN} ]]; then
  one_sample=true
fi

# Surface templates
if [[ ! -z ${atlas_dir} ]]; then
  rm -rf ${OUTPUT}/surf.templates
  cp -r ${atlas_dir}/ ${OUTPUT}/surf.templates/
  atlas_dir=${OUTPUT}/surf.templates
  template_surf_L=$(ls ${atlas_dir}/*L*midthick*surf.gii)
  template_surf_R=$(ls ${atlas_dir}/*R*midthick*surf.gii)
elif [[ -z ${atlas_dir} ]]; then
  if [[ ! -z ${template_surf_L} ]] && [[ ! -z ${template_surf_R} ]]; then
    surf_L_base=$(basename ${template_surf_L}); cp ${template_surf_L} ${OUTPUT}/${surf_L_base}; template_surf_L=${OUTPUT}/${surf_L_base}
    surf_R_base=$(basename ${template_surf_R}); cp ${template_surf_R} ${OUTPUT}/${surf_R_base}; template_surf_R=${OUTPUT}/${surf_R_base}
  fi
fi

# Internally uncompress gifti midthickness files if octave is being used
if hash octave 2>/dev/null; then
  wb_command -gifti-convert BASE64_BINARY ${template_surf_L} ${template_surf_L}
  wb_command -gifti-convert BASE64_BINARY ${template_surf_R} ${template_surf_R}
fi

#
# CIFTI setup 2
#==============================================================================

dr_cii=( $(cd ${OUTPUT}; ls dr_stage2_ic*.dscalar.nii) )

if [[ ! -d ${OUTPUT}/subs.fake_nifti ]] && [[ ${#dr_cii[@]} -eq 0 ]]; then
  echo ""
  echo "Converting and separating CIFTI files"
  mkdir -p ${OUTPUT}/subs.fake_nifti

  if [[ ${#surf_L[@]} -gt 0 ]] && [[ ${#surf_R[@]} -gt 0 ]]; then
    mkdir -p ${OUTPUT}/subs.L.va
    mkdir -p ${OUTPUT}/subs.R.va
  fi

  # Convert IC maps from dscalar to (fake) niftis
  printf "wb_command -cifti-convert -to-nifti ${ICA_MAPS} ${OUTPUT}/ic_maps.nii.gz \n" > ${LOGDIR}/dr.ciftiA
  ICA_MAPS_CIFTI=${ICA_MAPS}
  ICA_MAPS=${OUTPUT}/ic_maps.nii.gz

  j=0
  merge_list_left=""
  merge_list_right=""
  for ((i = 0; i < ${#files[@]}; i++)); do
    jj=$(zeropad ${j} 5)
    printf "wb_command -cifti-convert -to-nifti ${files[${i}]} ${OUTPUT}/subs.fake_nifti/sub-${jj}.nii.gz \n" >> ${LOGDIR}/dr.ciftiA
    # Check if subject surface arrays are populated
    if [[ ${#surf_L[@]} -gt 0 ]] && [[ ${#surf_R[@]} -gt 0 ]]; then
      printf "wb_command -surface-vertex-areas ${surf_L[${i}]} ${OUTPUT}/subs.L.va/sub-${jj}.L.shape.gii \n" >> ${LOGDIR}/dr.ciftiA
      printf "wb_command -surface-vertex-areas ${surf_R[${i}]} ${OUTPUT}/subs.R.va/sub-${jj}.R.shape.gii \n" >> ${LOGDIR}/dr.ciftiA
      merge_list_left+="-metric ${OUTPUT}/subs.L.va/sub-${jj}.L.shape.gii "
      merge_list_right+="-metric ${OUTPUT}/subs.R.va/sub-${jj}.R.shape.gii "
    fi
    j=$(echo "${j} 1 + p" | dc -)
  done

  # convert and separate cifti files
  parallel -j ${jobs} < ${LOGDIR}/dr.ciftiA

  if [[ ${#surf_L[@]} -gt 0 ]] && [[ ${#surf_R[@]} -gt 0 ]]; then
    printf "wb_command -metric-merge ${OUTPUT}/midthickness_va.L.func.gii ${merge_list_left} \n" >> ${LOGDIR}/dr.ciftiB
    printf "wb_command -metric-merge ${OUTPUT}/midthickness_va.R.func.gii ${merge_list_right} \n" >> ${LOGDIR}/dr.ciftiB
    printf "wb_command -metric-reduce ${OUTPUT}/midthickness_va.L.func.gii MEAN ${OUTPUT}/mean_va.L.area.func.gii \n" >> ${LOGDIR}/dr.ciftiB
    printf "wb_command -metric-reduce ${OUTPUT}/midthickness_va.R.func.gii MEAN ${OUTPUT}/mean_va.R.area.func.gii \n" >> ${LOGDIR}/dr.ciftiB
    # Default number of jobs set to 2 to avoid race conditions
    parallel -j 2 < ${LOGDIR}/dr.ciftiB
    left_va=${OUTPUT}/mean_va.L.area.func.gii; right_va=${OUTPUT}/mean_va.R.area.func.gii
  fi

  # Intermediary cleanup
  rm -rf ${OUTPUT}/subs.L.va ${OUTPUT}/subs.R.va ${OUTPUT}/midthickness_va.L.func.gii ${OUTPUT}/midthickness_va.R.func.gii

else
  # Check to see if vertex area files have been created
  left_va=${OUTPUT}/mean_va.L.area.func.gii; right_va=${OUTPUT}/mean_va.R.area.func.gii
  if [[ ! -f ${left_va} ]] && [[ ! -f ${right_va} ]]; then
    # Set to empty strings if they do not exist -
    # as both variables are referenced later.
    left_va=""; right_va=""
  fi
fi

#
# Perform Dual Regression
#==============================================================================

if [[ ${#dr_cii[@]} -eq 0 ]]; then
  # NOTE: This section uses the exact same (highly similar) code to that in FSL's
  # dual_regression (executable) script.

  # INPUTS is an array rather than a string
  # Make fake_nifti array of files
  INPUTS=( $(cd ${OUTPUT}/subs.fake_nifti; ls $(pwd)/*.nii*) )

  # Create mask
  echo ""
  echo "Creating common mask"
  j=0
  for i in ${INPUTS[@]}; do
    echo "\${FSLDIR}/bin/fslmaths ${i} -Tstd -bin ${OUTPUT}/mask_$(${FSLDIR}/bin/zeropad ${j} 5) -odt char" >> ${LOGDIR}/drA
    j=`echo "${j} 1 + p" | dc -`
  done
  # ID_drA=`${FSLDIR}/bin/fsl_sub -T 10 -N mask_generation1 -l $LOGDIR -t ${LOGDIR}/drA`
  parallel -j ${jobs} < ${LOGDIR}/drA
cat <<EOF > ${LOGDIR}/drB
#!/bin/sh
\${FSLDIR}/bin/fslmerge -t ${OUTPUT}/maskALL \`${FSLDIR}/bin/imglob ${OUTPUT}/mask_*\`
\${FSLDIR}/bin/fslmaths ${OUTPUT}/maskALL -Tmin ${OUTPUT}/mask
\${FSLDIR}/bin/imrm ${OUTPUT}/mask_*
EOF
  chmod a+x ${LOGDIR}/drB
  # ID_drB=`${FSLDIR}/bin/fsl_sub -j ${i}D_drA -T 5 -N mask_generation2 -l $LOGDIR ${LOGDIR}/drB`
  ID_drB=`${FSLDIR}/bin/fsl_sub -T 5 -N mask_generation2 -l $LOGDIR ${LOGDIR}/drB`

  # Perform Dual Regression
  echo ""
  echo "Doing the dual regressions"
  j=0
  for i in ${INPUTS[@]}; do
    s=subject$(${FSLDIR}/bin/zeropad ${j} 5)
    echo "${FSLDIR}/bin/fsl_glm -i ${i} -d ${ICA_MAPS} -o ${OUTPUT}/dr_stage1_${s}.txt --demean -m ${OUTPUT}/mask ; \
          ${FSLDIR}/bin/fsl_glm -i ${i} -d ${OUTPUT}/dr_stage1_${s}.txt -o ${OUTPUT}/dr_stage2_${s} --out_z=${OUTPUT}/dr_stage2_${s}_Z --demean -m ${OUTPUT}/mask ${DES_NORM} ; \
          ${FSLDIR}/bin/fslsplit ${OUTPUT}/dr_stage2_${s} ${OUTPUT}/dr_stage2_${s}_ic" >> ${LOGDIR}/drC
    j=`echo "${j} 1 + p" | dc -`
  done
  # ID_drC=`${FSLDIR}/bin/fsl_sub -j ${i}D_drB -T 30 -N dual_regression -l $LOGDIR -t ${LOGDIR}/drC`
  parallel -j ${jobs} < ${LOGDIR}/drC

  if [ ${NAF2} -eq 1 ] ; then
     echo "Doing thresholded dual regression"
     echo "1" > ${OUTPUT}/tmp.txt
     j=0
     for i in ${INPUTS[@]}; do
        s=subject$(${FSLDIR}/bin/zeropad ${j} 5)
        echo "${FSLDIR}/bin/melodic -i ${OUTPUT}/dr_stage2_${s} --ICs=${OUTPUT}/dr_stage2_${s} --mix=${OUTPUT}/tmp.txt -o ${OUTPUT}/MM_${s} --Oall --report -v --mmthresh=0" >> ${LOGDIR}/drD1
        echo "${FSLDIR}/bin/fslmerge -t ${OUTPUT}/MM_${s}/stats/thresh2 \`${FSLDIR}/bin/imglob ${OUTPUT}/MM_${s}/stats/thresh_zstat?.* ${OUTPUT}/MM_${s}/stats/thresh_zstat??.* ${OUTPUT}/MM_${s}/stats/thresh_zstat???.*\` ; sleep 10 ; \
        ${FSLDIR}/bin/imrm \`${FSLDIR}/bin/imglob ${OUTPUT}/MM_${s}/stats/thresh_zstat*.*\` ; \
        cp ${OUTPUT}/MM_${s}/stats/thresh2.nii.gz ${OUTPUT}/MM_${s}/stats/thresh2_negative.nii.gz ; \
        cp ${OUTPUT}/MM_${s}/stats/thresh2.nii.gz ${OUTPUT}/MM_${s}/stats/thresh2_positive.nii.gz ; \
        ${FSLDIR}/bin/fslmaths ${OUTPUT}/MM_${s}/stats/thresh2_negative -uthr -2 ${OUTPUT}/MM_${s}/stats/thresh2_negative ; \
        ${FSLDIR}/bin/fslmaths ${OUTPUT}/MM_${s}/stats/thresh2_positive -thr 2 ${OUTPUT}/MM_${s}/stats/thresh2_positive ; \
        ${FSLDIR}/bin/fslmaths ${OUTPUT}/MM_${s}/stats/thresh2_negative -add ${OUTPUT}/MM_${s}/stats/thresh2_positive ${OUTPUT}/MM_${s}/stats/thresh2 ; \
              ${FSLDIR}/bin/imrm \`${FSLDIR}/bin/imglob ${OUTPUT}/MM_{s}/stats/thresh2_*.*\` ; \
        ${FSLDIR}/bin/fsl_glm -i ${i} -d ${OUTPUT}/MM_${s}/stats/thresh2 -o ${OUTPUT}/dr_stage4_${s}.txt --demean -m ${OUTPUT}/mask" >> ${LOGDIR}/drD2
        j=`echo "${j} 1 + p" | dc -`
     done
     # ID_drD1=`${FSLDIR}/bin/fsl_sub -j ${i}D_drC -N mixture_model -l $LOGDIR -t ${LOGDIR}/drD1`
     # ID_drD2=`${FSLDIR}/bin/fsl_sub -j ${i}D_drD1 -N thresholdedDR -l $LOGDIR -t ${LOGDIR}/drD2`
     parallel -j ${jobs} < ${LOGDIR}/drD1
     parallel -j ${jobs} < ${LOGDIR}/drD2
  fi

  # Sort maps
  echo ""
  echo "Sorting maps"

  j=0
  Nics=$(${FSLDIR}/bin/fslnvols ${ICA_MAPS})
  while [ ${j} -lt ${Nics} ] ; do
    jj=$(${FSLDIR}/bin/zeropad ${j} 4)

    echo "${FSLDIR}/bin/fslmerge -t ${OUTPUT}/dr_stage2_ic${jj} \`${FSLDIR}/bin/imglob ${OUTPUT}/dr_stage2_subject*_ic${jj}.*\` ; \
          ${FSLDIR}/bin/imrm \`${FSLDIR}/bin/imglob ${OUTPUT}/dr_stage2_subject*_ic${jj}.*\` " >> ${LOGDIR}/drE
    j=$(echo "${j} 1 + p" | dc -)
  done
  # ID_drE=`${FSLDIR}/bin/fsl_sub -j $ID_drC -T 60 -N randomise -l $LOGDIR -t ${LOGDIR}/drE`
  parallel -j ${jobs} < ${LOGDIR}/drE

  # remove core dump files
  core_dump=( $(ls ${cwd}/core.*) )
  if [[ ${#core_dump[@]} -gt 0 ]]; then
    rm ${core_dump[@]}
  fi
fi

#
# CIFTI setup 3
#==============================================================================

if [[ ${#dr_cii[@]} -eq 0 ]] && [[ ! -f ${OUTPUT}/ic_maps.dscalar.nii ]]; then
  echo ""
  echo "Converting dual regression stage2 IC outputs to CIFTI"

  dr_ic_nii=( $(cd ${OUTPUT}; ls $(pwd)/*.nii*) )

  for file in ${dr_ic_nii[@]}; do
    printf "wb_command -cifti-convert -from-nifti ${file} ${ICA_MAPS_CIFTI} $(remove_ext ${file}).dscalar.nii -reset-scalars\n" >> ${LOGDIR}/dr.ciftiC 
  done

  if [[ ${convert_all} = "true" ]]; then
    mm_subs=( $(cd ${OUTPUT}; ls $(pwd)/*MM_*/stats/*.nii*) )

    for file in ${mm_subs[@]}; do
      printf "wb_command -cifti-convert -from-nifti ${file} ${ICA_MAPS_CIFTI} $(remove_ext ${file}).dscalar.nii -reset-scalars\n" >> ${LOGDIR}/dr.ciftiC 
    done
  fi

  # Convert dual regression stage 2 outputs to cifti
  parallel -j ${jobs} < ${LOGDIR}/dr.ciftiC

  # Intermediate clean-up
  rm -rf ${dr_ic_nii[@]} ${OUTPUT}/mask.nii.gz ${OUTPUT}/maskALL.nii.gz ${mm_subs[@]} ${OUTPUT}/subs.fake_nifti &

  # Make separated CIFTI metric masks
  mkdir -p ${OUTPUT}/palm.mask
  wb_command -cifti-separate ${OUTPUT}/mask.dscalar.nii COLUMN -volume-all ${OUTPUT}/palm.mask/vol.mask.nii \
  -metric CORTEX_LEFT ${OUTPUT}/palm.mask/cort.L.mask.func.gii \
  -metric CORTEX_RIGHT ${OUTPUT}/palm.mask/cort.R.mask.func.gii

  # Perform internal uncompression if octave is being used
  if hash octave 2>/dev/null; then
    wb_command -gifti-convert BASE64_BINARY ${OUTPUT}/palm.mask/cort.L.mask.func.gii ${OUTPUT}/palm.mask/cort.L.mask.func.gii
    wb_command -gifti-convert BASE64_BINARY ${OUTPUT}/palm.mask/cort.R.mask.func.gii ${OUTPUT}/palm.mask/cort.R.mask.func.gii
  fi

  # Copy original IC map cifti file to output directory and create info text file
  cp ${ICA_MAPS_CIFTI} ${OUTPUT}/ic_maps.dscalar.nii
  wb_command -file-information ${OUTPUT}/ic_maps.dscalar.nii > ${OUTPUT}/ic_maps.dscalar.info.txt
fi

#
# Perform Permutation Analysis
#==============================================================================

# NOTE: 
# - This section requires that FSL's PALM be added to the system path
# - This section of code is based on the PALM CIFTI examples located here: 
#   https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/PALM/Examples#Example_10:_Using_CIFTI_files

echo ""
echo "Running PALM on CIFTI files with TFCE"

# Construct general PALM args
palm_cmds=""

if [[ ! -z ${DESIGN} ]]; then
  palm_cmds+="${DESIGN} "
fi

if [[ ${fonly} = "true" ]]; then
  palm_cmds+="-fonly "
fi

if [[ ! -z ${NPERM} ]]; then
  palm_cmds+="-n ${NPERM} "
fi

if [[ ! -z ${precis} ]]; then
  palm_cmds+="-precision ${precis} "
fi

if [[ ${fdr} = "true" ]]; then
  palm_cmds+="-fdr "
fi

if [[ ${save1_p} = "true" ]]; then
  palm_cmds+="-save1-p "
fi

if [[ ${log_p} = "true" ]]; then
  palm_cmds+="-logp "
fi

if [[ ${twotail} = "true" ]] && [[ ${one_sample} = "false" ]]; then
  palm_cmds+="-twotail "
fi

if [[ ${demean} = "true" ]]; then
  palm_cmds+="-demean "
fi

# log file check
if [[ -f ${LOGDIR}/dr.ciftiD ]]; then
  rm ${LOGDIR}/dr.ciftiD
fi

# Write commands for each IC map
Nics=$(wb_command -file-information ${ICA_MAPS_CIFTI} -only-number-of-maps)
j=0
while [ ${j} -lt ${Nics} ] ; do
  jj=$(${FSLDIR}/bin/zeropad ${j} 4)

  # Internally uncompress gifti files if octave is being used
  if hash octave 2>/dev/null; then
    uncompress_cmd="wb_command -gifti-convert BASE64_BINARY ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.L.func.gii ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.L.func.gii ; \
        wb_command -gifti-convert BASE64_BINARY ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.R.func.gii ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.R.func.gii"
  fi

  # Gzipped nifti support is not available in PALM - convert/separate into uncompressed nifti
  echo "mkdir -p ${OUTPUT}/dr_stage3_ic${jj}.palm/vol ; mkdir -p ${OUTPUT}/dr_stage3_ic${jj}.palm/cort.L ; mkdir -p ${OUTPUT}/dr_stage3_ic${jj}.palm/cort.R ; \
        wb_command -cifti-separate ${OUTPUT}/dr_stage2_ic${jj}.dscalar.nii COLUMN -volume-all ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.nii \
        -metric CORTEX_LEFT ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.L.func.gii \
        -metric CORTEX_RIGHT ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.R.func.gii ; \
        ${uncompress_cmd}" >> ${LOGDIR}/dr.ciftiD

  j=$(echo "${j} 1 + p" | dc -)
done

# Perform Permutation Analysis
parallel -j ${jobs} < ${LOGDIR}/dr.ciftiD

# Construct job submission commands
job_cmds=""

if [[ ! -z ${mem} ]]; then
  job_cmds+="-M ${mem} "
fi

if [[ ! -z ${wall} ]]; then
  job_cmds+="-W ${wall} "
fi

if [[ ! -z ${queue} ]]; then
  job_cmds+="-q ${queue} "
  # if [[ ${queue} = *"gpu"* ]]; then
  #   job_cmds+="-R \"rusage[gpu=1]\" "
  # fi
fi

if [[ ${resub} = "true" ]]; then
  job_cmds+="-r "
fi

# log file check
if [[ -f ${LOGDIR}/dr.PALM ]]; then
  rm ${LOGDIR}/dr.PALM
fi

# Submit jobs for each IC map PALM analysis
Nics=$(wb_command -file-information ${ICA_MAPS_CIFTI} -only-number-of-maps)
j=0
while [ ${j} -lt ${Nics} ] ; do
  jj=$(${FSLDIR}/bin/zeropad ${j} 4)

  # Base PALM commands
  PALM_CMD_vol="palm -i ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.nii -o ${OUTPUT}/dr_stage3_ic${jj}.palm/vol/vol -T -m ${OUTPUT}/palm.mask/vol.mask.nii ${palm_cmds}"
  PALM_CMD_surf_L="palm -i ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.L.func.gii -o ${OUTPUT}/dr_stage3_ic${jj}.palm/cort.L/cort.L -T -tfce2D -s ${template_surf_L} ${left_va} -m ${OUTPUT}/palm.mask/cort.L.mask.func.gii ${palm_cmds}"
  PALM_CMD_surf_R="palm -i ${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage2_ic${jj}.R.func.gii -o ${OUTPUT}/dr_stage3_ic${jj}.palm/cort.R/cort.R -T -tfce2D -s ${template_surf_R} ${right_va} -m ${OUTPUT}/palm.mask/cort.R.mask.func.gii ${palm_cmds}"

  # Check if PALM jobs need to be submitted
  dr_palm_cii=( $(cd ${OUTPUT}/dr_stage3_ic${jj}.palm; ls *tfce*.dscalar.nii) )
  if [[ ${#dr_palm_cii[@]} -eq 0 ]]; then
    # Log args
    o_log=${OUTPUT}/dr_stage3_ic${jj}.palm/LSF

    # Run each job for PALM in parallel - this is faster
    dr_palm_cii=""; dr_palm_cii=( $(cd ${OUTPUT}/dr_stage3_ic${jj}.palm; ls vol/*.nii) )
    if [[ ${#dr_palm_cii[@]} -eq 0 ]]; then
      bsub -N ${job_cmds} -o ${o_log}_PALM_vol.log -e ${o_log}_PALM_vol.err -J ic${jj}_PALM.V -K ${PALM_CMD_vol} &
      echo "bsub -N ${job_cmds} -o ${o_log}_PALM_vol.log -e ${o_log}_PALM_vol.err -J ic${jj}_PALM.V -K ${PALM_CMD_vol}" >> ${LOGDIR}/dr.PALM
    fi
    dr_palm_cii=""; dr_palm_cii=( $(cd ${OUTPUT}/dr_stage3_ic${jj}.palm; ls cort.L/*.gii) )
    if [[ ${#dr_palm_cii[@]} -eq 0 ]]; then
      bsub -N ${job_cmds} -o ${o_log}_PALM_surfL.log -e ${o_log}_PALM_surfL.err -J ic${jj}_PALM.L -K ${PALM_CMD_surf_L} &
      echo "bsub -N ${job_cmds} -o ${o_log}_PALM_surfL.log -e ${o_log}_PALM_surfL.err -J ic${jj}_PALM.L -K ${PALM_CMD_surf_L}" >> ${LOGDIR}/dr.PALM
    fi
    dr_palm_cii=""; dr_palm_cii=( $(cd ${OUTPUT}/dr_stage3_ic${jj}.palm; ls cort.R/*.gii) )
    if [[ ${#dr_palm_cii[@]} -eq 0 ]]; then
      bsub -N ${job_cmds} -o ${o_log}_PALM_surfR.log -e ${o_log}_PALM_surfR.err -J ic${jj}_PALM.R -K ${PALM_CMD_surf_R} &
      echo "bsub -N ${job_cmds} -o ${o_log}_PALM_surfR.log -e ${o_log}_PALM_surfR.err -J ic${jj}_PALM.R -K ${PALM_CMD_surf_R}" >> ${LOGDIR}/dr.PALM
    fi
  fi
  j=$(echo "${j} 1 + p" | dc -)
done

if [[ ! -f ${OUTPUT}/README.PALM.txt ]]; then
  # Write dual regression/PALM README file
  palm_vol_ex="palm -i <vol>.nii -o <out_dir> -T -m <mask>.nii ${palm_cmds}"
  palm_surf_l="palm -i <metric>.L.func.gii -o <out_dir> -T -tfce2D -s <left_template_surface> ${left_mean_vertex_area} -m <metric>.L.mask.func.gii ${palm_cmds}"
  palm_surf_r="palm -i <metric>.R.func.gii -o <out_dir> -T -tfce2D -s <right_template_surface> ${right_mean_vertex_area} -m <metric>.R.mask.func.gii ${palm_cmds}"

  # Method name for README/Log
  if [[ ${method} = "bonf" ]]; then
    met="Bonferroni"
  elif [[ ${method} = "sid" ]]; then
    met="Šidák"
  fi

  # Compute Statistics threshold
  #  - in the case of (1-p), log(p) or just regular p-values 
  if [[ ${save1_p} = "true" ]]; then
    max_thresh=$(${scripts_dir}/calc_thresh.py --alpha ${sig} --tests 3 --method ${method})
    max_thresh=$(python -c "print(1-${max_thresh})")
    min_thresh=0
    approach="(1-p)"
  elif [[ ${log_p} = "true" ]]; then
    max_thresh=$(${scripts_dir}/calc_thresh.py --alpha ${sig} --tests 3 --method ${method} --log)
    min_thresh=0
    approach="log(p)"
  else
    min_thresh=$(${scripts_dir}/calc_thresh.py --alpha ${sig} --tests 3 --method ${method})
    max_thresh=1
    approach="unmanipulated (regular) p-values"
  fi

  # Write README file
  readme_palm_cmds ${OUTPUT}/README.PALM.txt ${sig} ${approach} ${met} ${max_thresh} "${palm_vol_ex}; ${palm_surf_l}; ${palm_surf_r}"
fi

# Wait on PALM analyses
wait

configs=( $(ls ${OUTPUT}/dr_stage3_ic*.palm/*/*palm*config*) )

# Copy config to parent directory to save
for config in ${configs[@]}; do
  dir=$(dirname ${config})
  cp ${config} ${dir}/..
done

# Internally compress gifti midthickness files if octave was used
if hash octave 2>/dev/null; then
  wb_command -gifti-convert GZIP_BASE64_BINARY ${template_surf_L} ${template_surf_L}
  wb_command -gifti-convert GZIP_BASE64_BINARY ${template_surf_R} ${template_surf_R}
  wb_command -gifti-convert GZIP_BASE64_BINARY ${OUTPUT}/palm.mask/cort.L.mask.func.gii ${OUTPUT}/palm.mask/cort.L.mask.func.gii
  wb_command -gifti-convert GZIP_BASE64_BINARY ${OUTPUT}/palm.mask/cort.R.mask.func.gii ${OUTPUT}/palm.mask/cort.R.mask.func.gii
fi

#
# Gather output results and write specifications (spec) file
#==============================================================================

# log file check
if [[ -f ${LOGDIR}/dr.ciftiE ]]; then
  rm ${LOGDIR}/dr.ciftiE
fi

# Merge PALM results into single CIFTI dscalar
Nics=$(wb_command -file-information ${ICA_MAPS_CIFTI} -only-number-of-maps)
j=0
while [ ${j} -lt ${Nics} ] ; do
  jj=$(${FSLDIR}/bin/zeropad ${j} 4)

  # Make sorted array of TFCE results
  cort_L=( $(cd ${OUTPUT}/dr_stage3_ic${jj}.palm/cort.L; ls $(pwd)/*tfce*.gii | sort) )
  cort_R=( $(cd ${OUTPUT}/dr_stage3_ic${jj}.palm/cort.R; ls $(pwd)/*tfce*.gii | sort) )
  subcort=( $(cd ${OUTPUT}/dr_stage3_ic${jj}.palm/vol; ls $(pwd)/*tfce*.nii | sort) )

  # Write commands to internally compress gifti files if Octave was used
  if hash octave 2>/dev/null; then
    for (( i = 0; i < ${#cort_L[@]}; i++)); do
      echo "wb_command -gifti-convert GZIP_BASE64_BINARY ${cort_L[$i]} ${cort_L[$i]} ; \
            wb_command -gifti-convert GZIP_BASE64_BINARY ${cort_R[$i]} ${cort_R[$i]}" >> ${LOGDIR}/dr.ciftiE1
    done
  fi

  # Write commands to merge CIFTIs into dscalar 
  for ((i = 0; i < ${#subcort[@]}; i++)); do
    # Create output file name
    file=${OUTPUT}/dr_stage3_ic${jj}.palm/dr_stage3_ic${jj}
    f=${subcort[$i]}
    fname=$(basename ${f%.nii} | sed "s@vol_@@g")
    echo "wb_command -cifti-create-dense-from-template ${OUTPUT}/dr_stage2_ic${jj}.dscalar.nii ${file}_${fname}.dscalar.nii \
          -volume-all ${subcort[$i]} -metric CORTEX_LEFT ${cort_L[$i]} -metric CORTEX_RIGHT ${cort_R[$i]} ; \
          cd ${OUTPUT}/dr_stage3_ic${jj}.palm/palm.orig ; cp ${file}_${fname}.dscalar.nii . ; \
          cd ${cwd}" >> ${LOGDIR}/dr.ciftiE
    if [[ ! -d ${OUTPUT}/dr_stage3_ic${jj}.palm/palm.orig ]]; then
      mkdir -p ${OUTPUT}/dr_stage3_ic${jj}.palm/palm.orig
    fi
  done
  j=$(echo "${j} 1 + p" | dc -)
done

# Internally compress gifti files if Octave was used
if hash octave 2>/dev/null; then
  parallel -j ${jobs} < ${LOGDIR}/dr.ciftiE1
fi

# Merge CIFTIs into dscalar
parallel -j ${jobs} < ${LOGDIR}/dr.ciftiE

if [[ ${stat_cleanup} = "true" ]]; then
  palm_sub_dirs=()
  palm_sub_dirs+=( $(cd ${OUTPUT}; ls -d $(pwd)/dr_stage3_ic*.palm/vol*) )
  palm_sub_dirs+=( $(cd ${OUTPUT}; ls -d $(pwd)/dr_stage3_ic*.palm/cort.L*) )
  palm_sub_dirs+=( $(cd ${OUTPUT}; ls -d $(pwd)/dr_stage3_ic*.palm/cort.R*) )
  palm_sub_dirs+=( $(cd ${OUTPUT}; ls -d $(pwd)/dr_stage3_ic*.palm/*.gii) )
  palm_sub_dirs+=( $(cd ${OUTPUT}; ls -d $(pwd)/dr_stage3_ic*.palm/dr_stage2_ic*.nii) )

  rm -rf ${palm_sub_dirs[@]}
fi

# Create specifications (spec) file for wb_view
tstats=( $(cd ${OUTPUT}; ls $(pwd)/dr_stage3_ic*.palm/*tfce_tstat_c*.dscalar.nii | sort) )
uncps=( $(cd ${OUTPUT}; ls $(pwd)/dr_stage3_ic*.palm/*tfce*uncp*c*.dscalar.nii | sort) )
fwes=( $(cd ${OUTPUT}; ls $(pwd)/dr_stage3_ic*.palm/*tfce*fwep*c*.dscalar.nii | sort) )
fdrs=( $(cd ${OUTPUT}; ls $(pwd)/dr_stage3_ic*.palm/*tfce*fdrp*c*.dscalar.nii | sort) )

# Output spec files
# Add surfaces to spec files
if [[ ${#tstats[@]} -gt 0 ]]; then
  # This array is assumed to always exist
  tstat_spec=${OUTPUT}/tfce_tstat.spec
  wb_command -add-to-spec-file ${tstat_spec} CORTEX_LEFT ${template_surf_L}
  wb_command -add-to-spec-file ${tstat_spec} CORTEX_RIGHT ${template_surf_R}

  if [[ -d ${atlas_dir} ]]; then
    write_surf_to_spec --atlas-dir ${atlas_dir} --spec-file ${tstat_spec}
  fi
fi

if [[ ${#uncps[@]} -gt 0 ]]; then
  uncps_spec=${OUTPUT}/tfce_tstat_uncp.spec
  wb_command -add-to-spec-file ${uncps_spec} CORTEX_LEFT ${template_surf_L}
  wb_command -add-to-spec-file ${uncps_spec} CORTEX_RIGHT ${template_surf_R}

  if [[ -d ${atlas_dir} ]]; then
    write_surf_to_spec --atlas-dir ${atlas_dir} --spec-file ${uncps_spec}
  fi
fi

if [[ ${#fwes[@]} -gt 0 ]]; then
  fwes_spec=${OUTPUT}/tfce_tstat_fwep.spec
  wb_command -add-to-spec-file ${fwes_spec} CORTEX_LEFT ${template_surf_L}
  wb_command -add-to-spec-file ${fwes_spec} CORTEX_RIGHT ${template_surf_R}

  if [[ -d ${atlas_dir} ]]; then
    write_surf_to_spec --atlas-dir ${atlas_dir} --spec-file ${fwes_spec}
  fi
fi

if [[ ${#fdrs[@]} -gt 0 ]]; then
  fdrs_spec=${OUTPUT}/tfce_tstat_fdrp.spec
  wb_command -add-to-spec-file ${fdrs_spec} CORTEX_LEFT ${template_surf_L}
  wb_command -add-to-spec-file ${fdrs_spec} CORTEX_RIGHT ${template_surf_R}

  if [[ -d ${atlas_dir} ]]; then
    write_surf_to_spec --atlas-dir ${atlas_dir} --spec-file ${fdrs_spec}
  fi
fi

# Compute Statistics threshold
#  - in the case of (1-p), log(p) or just regular p-values 
if [[ ${save1_p} = "true" ]]; then
  max_thresh=$(${scripts_dir}/calc_thresh.py --alpha ${sig} --tests 3 --method ${method})
  max_thresh=$(python -c "print(1-${max_thresh})")
  # min_thresh=0
  min_thresh="-${max_thresh}"
elif [[ ${log_p} = "true" ]]; then
  max_thresh=$(${scripts_dir}/calc_thresh.py --alpha ${sig} --tests 3 --method ${method} --log)
  # min_thresh=0
  min_thresh="-${max_thresh}"
else
  min_thresh=$(${scripts_dir}/calc_thresh.py --alpha ${sig} --tests 3 --method ${method})
  max_thresh=1
fi

# Print info to screen
echo ""
echo "Computed Statistial Threshold"
echo ""
echo "Method: ${method}"
echo ""
echo "Corrected threshold: ${max_thresh}"
echo ""

# Copy MNI template (2mm) to output directory
if [[ -d ${atlas_dir} ]]; then
  cp ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${atlas_dir}/MNI152_T1_2mm.nii.gz
  vol_file=$(realpath ${atlas_dir}/MNI152_T1_2mm.nii.gz)
else
  cp ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz ${OUTPUT}/MNI152_T1_2mm.nii.gz
  vol_file=$(realpath ${OUTPUT}/MNI152_T1_2mm.nii.gz)
fi

# Write auxillary and statistal images to spec file
for ((i = 0; i < ${#tstats[@]}; i++)); do
  # All stats arrays are assumed to have equal length -
  # otherwise this does not work as expected
  wb_command -add-to-spec-file ${tstat_spec} OTHER ${tstats[$i]}
  wb_command -add-to-spec-file ${tstat_spec} OTHER ${OUTPUT}/ic_maps.dscalar.nii
  wb_command -add-to-spec-file ${tstat_spec} OTHER ${vol_file}
  scale_palette --file ${tstats[$i]} --min ${min_thresh} --max ${max_thresh}

  # Check if spec file exists - write stat images to them
  if [[ -f ${uncps_spec} ]]; then
    wb_command -add-to-spec-file ${uncps_spec} OTHER ${uncps[$i]} 
    wb_command -add-to-spec-file ${uncps_spec} OTHER ${OUTPUT}/ic_maps.dscalar.nii
    wb_command -add-to-spec-file ${uncps_spec} OTHER ${vol_file}
    scale_palette --file ${uncps[$i]} --min ${min_thresh} --max ${max_thresh}
  fi

  if [[ -f ${fwes_spec} ]]; then
    wb_command -add-to-spec-file ${fwes_spec} OTHER ${fwes[$i]}
    wb_command -add-to-spec-file ${fwes_spec} OTHER ${OUTPUT}/ic_maps.dscalar.nii
    wb_command -add-to-spec-file ${fwes_spec} OTHER ${vol_file}
    scale_palette --file ${fwes[$i]} --min ${min_thresh} --max ${max_thresh}
  fi

  if [[ -f ${fdrs_spec} ]]; then
    wb_command -add-to-spec-file ${fdrs_spec} OTHER ${fdrs[$i]}
    wb_command -add-to-spec-file ${fdrs_spec} OTHER ${OUTPUT}/ic_maps.dscalar.nii
    wb_command -add-to-spec-file ${fdrs_spec} OTHER ${vol_file}
    scale_palette --file ${fdrs[$i]} --min ${min_thresh} --max ${max_thresh}
  fi
done
