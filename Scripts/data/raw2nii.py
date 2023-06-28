# -----------------------------------------------------------
# Image Orientation Issues
# -----------------------------------------------------------
# (NIfTI standard) RAS+:      |    (SimpleITK standard) LPS+:
# x axis points to Right      |     x axis points to Left
# y axis points to Anterior   |     y axis points to Posterior
# z axis points to Superior   |     z axis points to Superior
#
# The following direction represents RAS+ in SimpleITK's language:
#     tuple([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 1.0])
#
# When saving to NIfTI file, SimpleITK.WriteImage will handle the differences in these two standards, e.g.
#     [1] After reading a NIfTI image, <SimpleITK image>.GetDirection will return:
#         tuple([-1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, 1.0]) -- the RAS+ in SimpleITK's language
#     [2] If you save the <SimpleITK image> from [1] to NIfTI file, the diagonal entries in the affine matrix
#         are positive numbers (and equal to voxel size if no rotation transformation) -- the RAS+ in NIfTI's language
#
# Some important faces:
# [1] The SimpleITK.WriteImage will set orientation to RAS+ when the output format is NIfTI
# [2] <SimpleITK image>.SetDirection will not re-slice the data array, only the affine matrix will be modified
# -----------------------------------------------------------


import argparse
import os
import glob
import SimpleITK as sitk

# Create argument parser
parser = argparse.ArgumentParser(description='Convert .raw/.mhd to .nii files')
parser.add_argument('--path_raw', '-i', type=str, help='Path to .raw/.mhd directory')
parser.add_argument('--path_nii', '-o', type=str, help='Path to .nii directory')

# Parse arguments
args = parser.parse_args()

# Check if directories exist
if not os.path.isdir(args.path_raw):
    raise ValueError(f"Path to .raw/.mhd directory '{args.path_raw}' does not exist")
if not os.path.isdir(args.path_nii):
    os.makedirs(args.path_nii)

# Get list of raw files
List_mhd = glob.glob(os.path.join(args.path_raw, '*.mhd'))

# Convert .raw/.mhd to .nii
for i_path_mhd in List_mhd:
    i_subID = os.path.splitext(os.path.splitext(os.path.basename(i_path_mhd))[0])[0]
    i_img = sitk.ReadImage(i_path_mhd)
    # save to .nii.gz
    i_path_nii = os.path.join(args.path_nii, f'{i_subID}.nii.gz')
    sitk.WriteImage(i_img, i_path_nii)