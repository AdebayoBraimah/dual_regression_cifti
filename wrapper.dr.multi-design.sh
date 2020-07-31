#!/usr/bin/env bash

# NOTE: LSF implementation of dual_regression_cifti.sh

################################# Test Code #################################

# Directory variables
scripts_dir=$(dirname $(realpath ${0}))
hcp_dir=/scratch/brac4g/CAP/BIDS/derivatives/ciftify
atlas_dir=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.atlases/HCP_S1200_GroupAvg_v1
design_name=sct_cci-2_parent_adhd_covs
design_dir=/scratch/brac4g/CAP/BIDS/scripts/designs/design_mat/${design_name}

# Design directory
design=${design_dir}/grp.design.mat
contrast=${design_dir}/grp.design.con
exc_list=${design_dir}/grp.design.exclude.txt
inc_list=${design_dir}/grp.design.include.txt

agg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis
nonagg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_nonagg.analysis

out_dir_agg=${agg_dir}/seed-to-voxel.analysis.03_Aug_2020/${design_name}
out_dir_nonagg=${nonagg_dir}/seed-to-voxel.analysis.03_Aug_2020/${design_name}

# source binaries from home directory
source ~/.bash_profile

# unload auto-loaded modules
module unload fsl/5.0.11

# Load modules
module load fsl/6.0.3
module load octave/5.2.0
module load parallel/20140422     # Required for local compute node parallization of several jobs
module load palm/a117

# Input variables
echo ""
echo "Performing Analysis"
echo ""

ic_map=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.ica/ROIs/ROIs.5/ROIs.5.dscalar.nii
jobs=10
perm=5000

# PALM job sub reqs
mem=10000
wall=2000
queue=normal
# queue=long

# launch job
l_wall=2000
l_mem=16000
l_queue=normal
# l_queue=long

if [[ ! -d ${agg_dir} ]]; then
  mkdir -p ${agg_dir}
  mkdir -p ${nonagg_dir}
fi

# files
sub_list_agg=${agg_dir}/../subs_list_preproc-agg.txt
sub_list_nonagg=${nonagg_dir}/../subs_list_preproc-nonagg.txt
L_s_list=${agg_dir}/../sub_surf_L_list.txt
R_s_list=${agg_dir}/../sub_surf_R_list.txt

# output logs
o_agg=${out_dir_agg}/LSF.log
e_agg=${out_dir_agg}/LSF.err

o_nonagg=${out_dir_nonagg}/LSF.log
e_nonagg=${out_dir_nonagg}/LSF.err

if [[ -f ${sub_list_agg} ]]; then
  rm ${sub_list_agg}
  rm ${sub_list_nonagg}
  rm ${L_s_list}
  rm ${R_s_list}
fi

# make subject file lists
tmp_subs=( $(cd ${hcp_dir}; ls -d sub-* | sed "s@sub-@@g") )

# Subs to exclude (QC-failures and/or no-info)
mapfile -t exclude < ${exc_list}

for ex in ${exclude[@]}; do
  tmp_subs=("${tmp_subs[@]/$ex}")
done

subs=( ${tmp_subs[@]} )

echo ""
echo "Creating subject lists"
echo ""

for sub in ${subs[@]}; do
  cif_dt_agg=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/Results/REST_agg/REST_agg_Atlas_s4.dtseries.nii)
  cif_dt_nonagg=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/Results/REST_nonagg/REST_nonagg_Atlas_s4.dtseries.nii)
  mid_L=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/fsaverage_LR32k/*.L.midthickness.32k_fs_LR.surf.gii)
  mid_R=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/fsaverage_LR32k/*.R.midthickness.32k_fs_LR.surf.gii)

  echo ${cif_dt_agg} >> ${sub_list_agg}
  echo ${cif_dt_nonagg} >> ${sub_list_nonagg}
  echo ${mid_L} >> ${L_s_list}
  echo ${mid_R} >> ${R_s_list}
done

# Run only one to avoid excessive number of pending status jobs

# Perform dual regression
echo ""
echo "Performing dual regression of aggressively denoised data"
echo ""
bsub -N -o ${o_agg} -e ${e_agg} -q ${l_queue} -M ${l_mem} -W ${l_wall} -J DR_agg ${scripts_dir}/dual_regression_cifti.sh --queue ${queue} --surf-list-L ${L_s_list} --surf-list-R ${R_s_list} --ica-maps ${ic_map} --file-list ${sub_list_agg} --out-dir ${out_dir_agg} --atlas-dir ${atlas_dir} --jobs ${jobs} --des-norm --design ${design} --t-contrast ${contrast} --permutations ${perm} --thr --fdr --log-p --memory ${mem} --wall ${wall} --convert-all --sig 0.05 --method sid --resub --precision double --no-stats-cleanup

sleep 30

# Copy inclusion/exclusion files to scripts+log directory in output dual_regression_cifti directory
cp ${exc_list} ${out_dir_agg}/scripts+logs
cp ${inc_list} ${out_dir_agg}/scripts+logs

# echo ""
# echo "Performing dual regression of non-aggressively denoised data"
# echo ""
# bsub -N -o ${o_nonagg} -e ${e_nonagg} -q ${queue} -M ${mem} -W ${wall} -J DR_nag ${scripts_dir}/dual_regression_cifti.sh --queue ${queue} --surf-list-L ${L_s_list} --surf-list-R ${R_s_list} --ica-maps ${ic_map} --file-list ${sub_list_nonagg} --out-dir ${out_dir_nonagg} --atlas-dir ${atlas_dir} --jobs ${jobs} --des-norm --design ${design} --t-contrast ${contrast} --permutations ${perm} --thr --fdr --log-p --two-tail --memory ${mem} --wall ${wall} --convert-all --sig 0.05 --method sid 
