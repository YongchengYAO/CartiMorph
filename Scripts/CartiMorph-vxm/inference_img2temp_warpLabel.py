#!/usr/bin/env python

import os
import argparse
import numpy as np
import voxelmorph as vxm
import tensorflow as tf

# parse commandline args
parser = argparse.ArgumentParser()
parser.add_argument('--file_targetTemp', required=True, help='target template')
parser.add_argument('--file_sourceImg', required=True, help='source image')
parser.add_argument('--file_sourceLabel', required=True, help='the segmentation label of the source image')
parser.add_argument('--file_warpedLabel', required=True, help='the warped segmentation label')
parser.add_argument('--file_model', required=True, help='the template learning model')
parser.add_argument('-g', '--gpuIDs', help='GPU ID(s) - if not supplied, CPU is used')
parser.add_argument('--multichannel', action='store_true',
                    help='specify that data has multiple channels')
args = parser.parse_args()

# tensorflow device handling
device, nb_devices = vxm.tf.utils.setup_device(args.gpuIDs)

# load the target template, source image, and source segmentation
add_feat_axis = not args.multichannel
targetTemp, targetAffine = vxm.py.utils.load_volfile(
    args.file_targetTemp, add_batch_axis=True, add_feat_axis=add_feat_axis, ret_affine=True)
sourceImg = vxm.py.utils.load_volfile(
    args.file_sourceImg, add_batch_axis=True, add_feat_axis=add_feat_axis, ret_affine=False)
sourceLabel = vxm.py.utils.load_volfile(
    args.file_sourceLabel, add_batch_axis=True, add_feat_axis=add_feat_axis, ret_affine=False)

inshape = sourceImg.shape[1:-1]
nb_feats = sourceImg.shape[-1]

with tf.device(device):
    # load model and predict
    config = dict(inshape=inshape)
    warpingField = vxm.networks.TemplateCreation.load(args.file_model, **config).register_img2tmp(sourceImg)
    warpedLabel = vxm.networks.Transform(sourceLabel.shape[1:-1],
                                   interp_method="nearest",
                                   nb_feats=sourceLabel.shape[-1]).predict([sourceLabel, warpingField])

# save the wrapped segmentation
vxm.py.utils.save_volfile(warpedLabel.squeeze(), args.file_warpedLabel, targetAffine)