#!/usr/bin/env python

"""
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
Warp the segmentation masks to the template image space.
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

Model inference is implemented in 
CartiMorph-vxm (https://github.com/YongchengYAO/CartiMorph-vxm), a work based on 
VoxelMorph (https://github.com/voxelmorph/voxelmorph)

If you use this code, please cite the following:

    Yongcheng Yao, Junru Zhong, Liping Zhang, Sheheryar Khan, Weitian Chen.
    "CartiMorph: a framework for automated knee articular cartilage morphometrics."
    Medical Image Analysis

Copyright 2023 Yongcheng Yao

-----------------------------------------------------------------------------------
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in 
compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or 
implied. See the License for the specific language governing permissions and limitations under 
the License.
-----------------------------------------------------------------------------------
"""

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