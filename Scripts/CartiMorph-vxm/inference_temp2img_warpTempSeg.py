#!/usr/bin/env python

"""
<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
Warp the template segmentation mask to the target image space.
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
import glob
import argparse
import numpy as np
import voxelmorph as vxm
import tensorflow as tf

# parse commandline args
parser = argparse.ArgumentParser()
parser.add_argument('--dir_targetImg', required=True, help='folder of the target images')
parser.add_argument('--file_TempSeg', required=True, help='the template segmentation')
parser.add_argument('--dir_warpedTempSeg', required=True, help='folder of the warped template segmentation masks')
parser.add_argument('--dir_warpingField', required=True, help='folder of the warping field')
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
        warpingField = vxm.networks.TemplateCreation.load(args.file_model, **config).register_tmp2img(targetImg)
        warpedTempSeg = vxm.networks.Transform(TempSeg.shape[1:-1],
                                       interp_method="nearest",
                                       nb_feats=TempSeg.shape[-1]).predict([TempSeg, warpingField])

    # save the wrapped atlas
    tmp, name_targetImg = os.path.split(file_targetImg)
    file_warpedTempSeg = os.path.join(args.dir_warpedTempSeg, name_targetImg)
    vxm.py.utils.save_volfile(warpedTempSeg.squeeze(), file_warpedTempSeg, targetAffine)

    # save the warping field
    file_warpingField = os.path.join(args.dir_warpingField, name_targetImg)
    vxm.py.utils.save_volfile(warpingField.squeeze(), file_warpingField, targetAffine)
