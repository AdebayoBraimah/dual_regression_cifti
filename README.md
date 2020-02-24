# dual_regression_cifti

Performs FSL's `dual_regression` for CIFTI files in addition to permutation based analyses (via FSL's PALM).

This script requires that `FSL`, connectome workbench (`wb_command`), and FSL's PALM be installed and added to the system path for this script to work correctly.

**Note**:
  * Intended to run on LSF platforms (i.e. jobs for PALM are submitted via `bsub` to run in parallel).
  * The bash version of `imglob` was used as the LSF platform did not have the proper fslpython configuration.

```

  Usage: dual_regression_cifti.sh -i <image> -o <out_dir> -f <list.txt> -tsL <left_surf_template> -tsR <right_surf_template>

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
                              N-1 the maximum number of cores available. [default: 11]
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

LSF specific arguements:

--mem, --memory               The amount of memory to be used when submitting jobs for PALM (in MB) [default: 5000]
--wall                        The amount of wall-time to be allocated to each job for PALM (in hours) [default: 100]
-q, --queue                   LSF queue name to submit jobs to (, look up queue names with the command 'bqueues') [default: normal]

----------------------------------------

-h,-help,--help     Prints usage and exits.

NOTE:
- Requires FSL v5.0.11+
- Requires Connectome Workbench v1.3.2+
- Requires FSL's PALM version alpha115+
- Requires GNU parallel to be installed and
  added to system path
- Default LSF arguements are unlikely to result 
  in all PALM jobs running to completion.

----------------------------------------

Adebayo B. Braimah - 2020 02 18 17:31:22

dual_regression_cifti.sh v0.0.1

----------------------------------------

  Usage: dual_regression_cifti.sh -i <image> -o <out_dir> -f <list.txt> -tsL <left_surf_template> -tsR <right_surf_template>
  ```
