#!/usr/bin/env python
# 
# -*- coding: utf-8 -*-
# title           : calc_thresh.py
# description     : [description]
# author          : Adebayo B. Braimah
# e-mail          : adebayo.braimah@cchmc.org
# date            : 2020 02 21 16:23:41
# version         : 0.0.1
# usage           : calc_thresh.py [-h,--help]
# notes           : [notes]
# python_version  : 3.7.3
#==============================================================================

# Import modules/pacakges
from __future__ import division
import math
import argparse

# Define functions
def thresh_bonf(alpha, N, log=False):
  '''
  Computes Bonferroni-corrected significance statistical threshold for some arbitrary alpha
  given some multiplicity of statistical tests performed. Additionally, the -log(p) can be
  computed (which makes small changes in the p-value appear large - which is excellent for
  the visualization of small effects).

  Arguments:
    alpha (float): Threshold (commonly 0.05)
    N (int): Number of statistical tests performed to correct for
    log (boolean): Whether to return the corrected -log(p) or not

  Returns:
    thresh (float): Bonferroni-corrected statistical threshold
  '''

  if not log:
    thresh = (alpha / N)
  if log:
    thresh = -(math.log((alpha) / N, 10))

  return thresh


def thresh_sidak(alpha, N, log=False):
  '''
  Computes Sidak-corrected significance statistical threshold for some arbitrary alpha
  given some multiplicity of statistical tests performed. Additionally, the -log(p) can be
  computed (which makes small changes in the p-value appear large - which is excellent for
  the visualization of small effects).

  Arguments:
    alpha (float): Threshold (commonly 0.05)
    N (int): Number of statistical tests performed to correct for
    log (boolean): Whether to return the corrected -log(p) or not

  Returns:
    thresh (float): Sidak-corrected statistical threshold
  '''

  if not log:
    thresh = (1 - (1 - alpha) ** (1 / N))
  if log:
    thresh = -(math.log((1 - (1 - alpha) ** (1 / N)), 10))

  return thresh

# Define main function
if __name__ == "__main__":
  # Argument parser
  parser = argparse.ArgumentParser(
      description='Computes corrected statistical significance threshold(s) for some arbitrary value of alpha for some number of multiple tests performed.'
                  'Please see these sources for additional details:'
                  'http://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/PALM(2f)Examples.html')

  # Parse arguments
  # Required arguments
  reqoptions = parser.add_argument_group('Required Argument(s)')
  reqoptions.add_argument('-a','--alpha',
                          type=float,
                          dest="alpha",
                          metavar="THR",
                          required=True,
                          help="Significance threshold to be corrected.")
  reqoptions.add_argument('-t', '--tests',
                          type=int,
                          dest="num",
                          metavar="TESTS",
                          required=True,
                          help="Number of statistical tests performed.")
  reqoptions.add_argument('-l', '--log',
                          dest="log",
                          required=False,
                          default=False,
                          action="store_true",
                          help="Computes the corrected -log(p) value. This is excellent for visualization as this makes small changes in p appear large.")
  reqoptions.add_argument('-m', '--method',
                          type=str,
                          metavar="METHOD",
                          dest="method",
                          required=True,
                          default="bonf",
                          help="Method used to compute the corrected p-value threshold. Valid options include 'bonf' for Bonferroni correction and 'sid' for Sidak correction.")

  args = parser.parse_args()

  # Print help message in the case of no arguments
  try:
    args = parser.parse_args()
  except SystemExit as err:
    if err.code == 2:
      parser.print_help()

  # Compute threshold
  if args.method.lower() == 'bonf':
    thresh = thresh_bonf(alpha=args.alpha,N=args.num,log=args.log)
    print(thresh)
  elif args.method.lower() == 'sid':
    thresh = thresh_sidak(alpha=args.alpha,N=args.num,log=args.log)
    print(thresh)
  else:
    print("")
    print("Invalid method selection. Please see the help menu.")    
