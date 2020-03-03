#!/usr/bin/env bash

# NOTE: LSF implementation of dual_regression_cifti.sh
# 
# Test variables are commented out of code

################################# Test Code #################################

# Directory variables
scripts_dir=$(dirname $(realpath ${0}))
hcp_dir=/scratch/brac4g/CAP/BIDS/derivatives/ciftify
atlas_dir=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.atlases/HCP_S1200_GroupAvg_v1

agg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis
nonagg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_nonagg.analysis

# # test variables
# echo ""
# echo "Testing being performed"
# echo ""
# agg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis.test
# ic_map=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.ROIs/ROIs.cifti/attention_network.network.dscalar.nii
# perm=5

out_dir_agg=${agg_dir}/seed-to-voxel.analysis
out_dir_nonagg=${nonagg_dir}/seed-to-voxel.analysis

# Load modules
# module load fsl/6.0.0         # May or may not work reliably (contains library linker issues)
# module load fsl/6.0.0-2       # May contain library linker issues
module load dhcp/1.1.0-a        # This has wb_command installed
module load fsl/5.0.11          # Current version that works reliably
module load matlab/2017a        # This specific version as it is referenced in PALM LSF implementation
module load parallel/20140422   # Required for local compute node parallization of several jobs

# Define PALM directory path and add PALM to system path
PALMDIR=${scripts_dir}/palm-alpha116
export PATH=${PATH}:${PALMDIR}

# Input variables
echo ""
echo "Performing Analysis"
echo ""
ic_map=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.ica/ROIs/ROIs.3/ciftis/ROIs.dscalar.nii
jobs=10
perm=5000
# design=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/designs.18_Feb_2020/designs.mat
# contrast=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/designs.18_Feb_2020/contrast.con

mem=10000
wall=2000
# queue=normal
queue=long
# queue=gpu-nodes

# launch job
l_wall=2000
l_mem=16000
# l_queue=normal
l_queue=long

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

o_nonagg=${out_dir_agg}/LSF.log
e_nonagg=${out_dir_agg}/LSF.err

if [[ -f ${sub_list_agg} ]]; then
  rm ${sub_list_agg}
  rm ${sub_list_nonagg}
  rm ${L_s_list}
  rm ${R_s_list}
fi

# make subject file lists
tmp_subs=( $(cd ${hcp_dir}; ls -d sub-* | sed "s@sub-@@g") )

## Subs to exclude (QC-failures and/or no-info)
exclude=( 1515 1013 1039 1606 1618 )

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
bsub -N -o ${o_agg} -e ${e_agg} -q ${l_queue} -M ${l_mem} -W ${l_wall} -J DR_agg ${scripts_dir}/dual_regression_cifti.sh --queue ${queue} --surf-list-L ${L_s_list} --surf-list-R ${R_s_list} --ica-maps ${ic_map} --file-list ${sub_list_agg} --out-dir ${out_dir_agg} --atlas-dir ${atlas_dir} --jobs ${jobs} --des-norm --permutations ${perm} --thr --fdr --log-p --two-tail --memory ${mem} --wall ${wall} --convert-all --sig 0.05 --method sid --no-stats-cleanup
# echo ""
# echo "Performing dual regression of non-aggressively denoised data"
# echo ""
# bsub -N -o ${o_nonagg} -e ${e_nonagg} -q ${queue} -M ${mem} -W ${wall} -J DR_nag ${scripts_dir}/dual_regression_cifti.sh --queue ${queue} --surf-list-L ${L_s_list} --surf-list-R ${R_s_list} --ica-maps ${ic_map} --file-list ${sub_list_nonagg} --out-dir ${out_dir_nonagg} --atlas-dir ${atlas_dir} --jobs ${jobs} --des-norm --design ${design} --t-contrast ${contrast} --permutations ${perm} --thr --fdr --log-p --two-tail --memory ${mem} --wall ${wall} --convert-all --sig 0.05 --method sid 

################################# Test Code #################################

################################# Original Code #################################

# # Directory variables
# scripts_dir=$(dirname $(realpath ${0}))
# hcp_dir=/scratch/brac4g/CAP/BIDS/derivatives/ciftify
# atlas_dir=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.atlases/HCP_S1200_GroupAvg_v1

# agg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis
# nonagg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_nonagg.analysis

# out_dir_agg=${agg_dir}/seed-to-voxel.analysis
# out_dir_nonagg=${nonagg_dir}/seed-to-voxel.analysis

# # Load modules
# module load fsl/6.0.0           # May or may not work reliably
# module load dhcp/1.1.0-a        # This has wb_command installed
# module load matlab/2017a        # This specific version as it is referenced in PALM LSF implementation
# module load parallel/20140422   # Required for local compute node parallization of several jobs

# # Define PALM directory path and add PALM to system path
# PALMDIR=${scripts_dir}/palm-alpha116
# export PATH=${PATH}:${PALMDIR}

# # Input variables
# ic_map=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.ica/ROIs/ROIs.1/ciftis/selected_ROIs.dscalar.nii
# jobs=10
# perm=5000
# design=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/designs.18_Feb_2020/designs.mat
# contrast=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/designs.18_Feb_2020/contrast.con

# mem=32000
# wall=1000

# if [[ ! -d ${agg_dir} ]]; then
#   mkdir -p ${agg_dir}
#   mkdir -p ${nonagg_dir}
# fi

# # files
# sub_list_agg=${agg_dir}/../subs_list_preproc-agg.txt
# sub_list_nonagg=${agg_dir}/../subs_list_preproc-nonagg.txt
# L_s_list=${agg_dir}/../sub_surf_L_list.txt
# R_s_list=${agg_dir}/../sub_surf_R_list.txt

# if [[ -f ${sub_list_agg} ]]; then
#   rm ${sub_list_agg}
#   rm ${sub_list_nonagg}
#   rm ${L_s_list}
#   rm ${R_s_list}
# fi

# # make subject file lists
# tmp_subs=( $(cd ${hcp_dir}; ls -d sub-* | sed "s@sub-@@g") )

# ## Subs to exclude (QC-failures and/or no-info)
# exclude=( 1515 1013 1039 1606 1618 )

# for ex in ${exclude[@]}; do
#   tmp_subs=("${tmp_subs[@]/$ex}")
# done

# subs=( ${tmp_subs[@]} )

# echo ""
# echo "Creating subject lists"
# echo ""

# for sub in ${subs[@]}; do
#   cif_dt_agg=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/Results/REST_agg/REST_agg_Atlas_s4.dtseries.nii)
#   cif_dt_nonagg=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/Results/REST_nonagg/REST_nonagg_Atlas_s4.dtseries.nii)
#   mid_L=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/fsaverage_LR32k/*.L.midthickness.32k_fs_LR.surf.gii)
#   mid_R=$(ls ${hcp_dir}/sub-${sub}/MNINonLinear/fsaverage_LR32k/*.R.midthickness.32k_fs_LR.surf.gii)

#   echo ${cif_dt_agg} >> ${sub_list_agg}
#   echo ${cif_dt_nonagg} >> ${sub_list_nonagg}
#   echo ${mid_L} >> ${L_s_list}
#   echo ${mid_R} >> ${R_s_list}
# done

# # Perform dual regression
# echo ""
# echo "Performing dual regression of aggressively denoised data"
# echo ""
# ${scripts_dir}/dual_regression_cifti.sh --ica-maps ${ic_map} --file-list ${sub_list_agg} --out-dir ${out_dir_agg} --atlas-dir ${atlas_dir} --jobs ${jobs} --des-norm --design ${design} --t-contrast ${contrast} --permutations ${perm} --thr --fdr --save1-p --two-tail --memory ${mem} --wall ${wall} --convert-all
# echo ""
# echo "Performing dual regression of non-aggressively denoised data"
# echo ""
# ${scripts_dir}/dual_regression_cifti.sh --ica-maps ${ic_map} --file-list ${sub_list_nonagg} --out-dir ${out_dir_nonagg} --atlas-dir ${atlas_dir} --jobs ${jobs} --des-norm --design ${design} --t-contrast ${contrast} --permutations ${perm} --thr --fdr --save1-p --two-tail --memory ${mem} --wall ${wall} --convert-all

################################# Old(er) Code #################################

# Old code
# 
# # constants
# scripts_dir=$(dirname $(realpath ${0}))
# design=${scripts_dir}/design.mat
# contrast=${scripts_dir}/contrast.con

# # variables
# file_list=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis/sub.list.fake_nifti.txt
# # out_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis/dual_regression/networks_and_seeds/networks_and_seeds.fake_nifti
# out_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis/dual_regression/networks_and_seeds
# maps=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.ica/ROIs/ROIs.1/fake_nifti.ROIs.nii.gz

# ${scripts_dir}/dual_regression_cifti.sh ${maps} 1 ${design} ${contrast} 5000 --thr --jobs 10 ${out_dir} $(cat ${file_list})
