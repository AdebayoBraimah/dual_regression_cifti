#!/usr/bin/env bash

# NOTE: LSF implementation of dual_regression_cifti.sh

################################# dr_cifti wrapper code #################################

# source binaries from home directory
source ~/.bash_profile

# unload auto-loaded modules
module unload fsl/5.0.11

# Load modules
module load fsl/6.0.3
module load octave/5.2.0
module load parallel/20140422     # Required for local compute node parallization of several jobs
module load palm/a117

# Directory variables
scripts_dir=$(dirname $(realpath ${0}))
hcp_dir=/scratch/brac4g/CAP/BIDS/derivatives/ciftify
atlas_dir=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.atlases/HCP_S1200_GroupAvg_v1

design_names=( sct_child_covs
  sct_parent_covs
  sct_teacher_covs 
  sct_child_parent_adhd_covs 
  sct_cci-2_parent_adhd_covs
  sct_cci-2_covs
  design_sct_no_covs
  sct_adhd_parent_no_covs
  sct_adhd_teacher_no_covs
  sct_child_no_covs
  sct_parent_no_covs
  sct_teacher_no_covs
  design_sct_covs
  sct_adhd_parent_covs
  sct_adhd_teacher_covs )

# i=0 # counter
# for design_name in ${design_names[@]}; do
loop_count=1; parallel_jobs=3
for (( i=4; i < ${#design_names[@]}; i++ )); do

  design_name=${design_names[$i]}

  echo ""
  echo "Processing design: ${design_name}"

  # Set counter variable
  ii=$(${FSLDIR}/bin/zeropad ${i} 2)

  # Create design directory variable
  design_dir=/scratch/brac4g/CAP/BIDS/scripts/designs/design_mat/${design_name}
  
  # Design directory
  design=${design_dir}/grp.design.mat
  contrast=${design_dir}/grp.design.con
  exc_list=${design_dir}/grp.design.exclude.txt
  inc_list=${design_dir}/grp.design.include.txt
  
  agg_dir=/scratch/brac4g/CAP/BIDS/derivatives/cifti.analysis/REST_agg.analysis
  
  out_dir_agg=${agg_dir}/seed-to-voxel.analysis.04_Sep_2020/${design_name}
  
  # Input variables
  echo ""
  echo "Performing Analysis"
  echo ""
  
  ic_map=/scratch/brac4g/CAP/BIDS/scripts/cifti_recon/cifti.ica/ROIs/ROIs.9/ROIs.9.dscalar.nii
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
  fi
  
  # files
  sub_list_agg=${agg_dir}/subs_list_preproc-agg.${design_name}.txt
  L_s_list=${agg_dir}/subs_surf_L_list.${design_name}.txt
  R_s_list=${agg_dir}/subs_surf_R_list.${design_name}.txt
  
  # output logs
  o_agg=${out_dir_agg}/LSF.log
  e_agg=${out_dir_agg}/LSF.err
  
  if [[ -f ${sub_list_agg} ]]; then
    rm ${sub_list_agg}
    rm ${L_s_list}
    rm ${R_s_list}
  fi
  
  # make subject file lists
  mapfile -t subs < ${inc_list}
  
  echo ""
  echo "Creating subject lists"
  echo ""
  
  for sub in ${subs[@]}; do
    cif_dt_agg=$(ls ${hcp_dir}/${sub}/MNINonLinear/Results/REST_agg/REST_agg_Atlas_s4.dtseries.nii)
    mid_L=$(ls ${hcp_dir}/${sub}/MNINonLinear/fsaverage_LR32k/*.L.midthickness.32k_fs_LR.surf.gii)
    mid_R=$(ls ${hcp_dir}/${sub}/MNINonLinear/fsaverage_LR32k/*.R.midthickness.32k_fs_LR.surf.gii)
  
    echo ${cif_dt_agg} >> ${sub_list_agg}
    echo ${mid_L} >> ${L_s_list}
    echo ${mid_R} >> ${R_s_list}
  done
  
  # Run 3 at a time to avoid excessive number of pending status jobs

  # if [[ ${i} -gt 3 ]]; then
  #   j=$(echo "${i} 1 - p" | dc -)
  #   jj=$(${FSLDIR}/bin/zeropad ${j} 2)
  #   job_wait="-w \"DR_agg.${jj}\""
  # else
  #   job_wait=""
  # fi

  if [[ ${loop_count} -eq 0 ]]; then
    job_wait="job_run"
  fi
  loop_count=$(python -c "print(${loop_count}+1)")
  if [[ ${loop_count} -ge $((${parallel_jobs}+1)) ]]; then
    j=$(echo "${i} 1 - p" | dc -)
    jj=$(${FSLDIR}/bin/zeropad ${j} 2)
    job_wait="-w \"DR_agg.${jj}\""
    loop_count=1
  elif [[ ${loop_count} -lt $((${parallel_jobs}+1)) ]]; then
    job_wait=${job_wait}
  fi
  
  # Perform dual regression
  echo ""
  echo "Performing dual regression of aggressively denoised data"
  echo ""
  bsub -N -o ${o_agg} -e ${e_agg} -q ${l_queue} -M ${l_mem} -W ${l_wall} -J DR_agg.${ii} ${job_wait} \
  ${scripts_dir}/dual_regression_cifti.sh --queue ${queue} --surf-list-L ${L_s_list} --surf-list-R ${R_s_list} \
  --ica-maps ${ic_map} --file-list ${sub_list_agg} --out-dir ${out_dir_agg} --atlas-dir ${atlas_dir} --jobs ${jobs} \
  --des-norm --design ${design} --t-contrast ${contrast} --permutations ${perm} --fdr --log-p --memory ${mem} --wall ${wall} \
  --sig 0.05 --method sid --resub --precision double # --no-stats-cleanup
  
  # Copy inclusion/exclusion files to scripts+log directory in output dual_regression_cifti directory
  bsub ${job_wait} -J cp.data.${ii} "sleep 30; cp ${exc_list} ${out_dir_agg}/scripts+logs; cp ${inc_list} ${out_dir_agg}/scripts+logs"

  # i=$(echo "${i} 1 + p" | dc -)
done
