#!/usr/bin/env python

import os
import glob
import argparse
import numpy as np
import voxelmorph as vxm
import tensorflow as tf

# parse commandline args
parser = argparse.ArgumentParser()
parser.add_argument('--dir_targetImg', required=True, help='folder of the target images')
parser.add_argument('--file_TempSeg', required=True, help='the template segmentation')
parser.add_argument('--dir_warppedTempSeg', required=True, help='folder of the warpped template segmentation masks')
parser.add_argument('--dir_warppingField', required=True, help='folder of the warpping field')
parser.add_argument('--file_model', required=True, help='the template learning model')
parser.add_argument('-g', '--gpuIDs', help='GPU ID(s) - if not supplied, CPU is used')
parser.add_argument('--multichannel', action='store_true',
                    help='specify that data has multiple channels')
args = parser.parse_args()

# tensorflow device handling
device, nb_devices = vxm.tf.utils.setup_device(args.gpuIDs)

# load the template segmentation
add_feat_axis = not args.multichannel
TempSeg = vxm.py.utils.load_volfile(
    args.file_TempSeg, add_batch_axis=True, add_feat_axis=add_feat_axis, ret_affine=False)


for file_targetImg in glob.glob(os.path.join(args.dir_targetImg, "*.nii.gz")) + glob.glob(os.path.join(args.dir_targetImg, "*.nii")):
    # load the target image
    targetImg, targetAffine = vxm.py.utils.load_volfile(
        file_targetImg, add_batch_axis=True, add_feat_axis=add_feat_axis, ret_affine=True)

    inshape = targetImg.shape[1:-1]
    nb_feats = targetImg.shape[-1]

    with tf.device(device):
        # load model and predict
        config = dict(inshape=inshape)
        warppingField = vxm.networks.TemplateCreation.load(args.file_model, **config).register_tmp2img(targetImg)
        warppedTempSeg = vxm.networks.Transform(TempSeg.shape[1:-1],
                                       interp_method="nearest",
                                       nb_feats=TempSeg.shape[-1]).predict([TempSeg, warppingField])

    # save the wrapped atlas
    tmp, name_targetImg = os.path.split(file_targetImg)
    file_warppedTempSeg = os.path.join(args.dir_warppedTempSeg, name_targetImg)
    vxm.py.utils.save_volfile(warppedTempSeg.squeeze(), file_warppedTempSeg, targetAffine)

    # save the warpping field
    file_warppingField = os.path.join(args.dir_warppingField, name_targetImg)
    vxm.py.utils.save_volfile(warppingField.squeeze(), file_warppingField, targetAffine)
