#!/usr/bin/env python

"""
Example script to train (unconditional) template creation.

If you use this code, please cite the following:

    Learning Conditional Deformable Templates with Convolutional Networks
    Adrian V. Dalca, Marianne Rakic, John Guttag, Mert R. Sabuncu
    NeurIPS 2019. https://arxiv.org/abs/1908.02738

Copyright 2020 Adrian V. Dalca

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in 
compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or 
implied. See the License for the specific language governing permissions and limitations under 
the License.
"""

import os
import argparse
import shutil
import tensorflow as tf
import keras
from keras.optimizers import Adam # keras==2.9.0
import CartiMorph_vxm as vxm

# model saving step
save_model_per_epoch = 50

# confirm visible GPUs
from tensorflow.python.client import device_lib
print(device_lib.list_local_devices())

# disable eager execution
tf.compat.v1.disable_eager_execution()

# compatibility setting
tf.compat.v1.experimental.output_all_intermediates(True)

# parse the commandline
parser = argparse.ArgumentParser()

# data organization parameters
parser.add_argument('--img-list', required=True, help='line-seperated list of training files')
parser.add_argument('--img-prefix', help='optional input image file prefix')
parser.add_argument('--img-suffix', help='optional input image file suffix')
parser.add_argument('--init-template', help='initial template image')
parser.add_argument('--model-dir', default='models',
                    help='model output directory (default: models)')
parser.add_argument('--multichannel', action='store_true',
                    help='specify that data has multiple channels')
parser.add_argument('--imgVoxelSize', required=True, help='image voxel size', nargs='+')

# training parameters
parser.add_argument('--gpu', default='0', help='GPU ID numbers (default: 0)')
parser.add_argument('--batch-size', type=int, default=1, help='batch size (default: 1)')
parser.add_argument('--epochs', type=int, default=1500,
                    help='number of training epochs (default: 1500)')
parser.add_argument('--steps-per-epoch', type=int, default=100,
                    help='frequency of model saves (default: 100)')
parser.add_argument('--load-weights', help='optional weights file to initialize with')
parser.add_argument('--initial-epoch', type=int, default=0,
                    help='initial epoch number (default: 0)')
parser.add_argument('--lr', type=float, default=1e-4, help='learning rate (default: 1e-4)')

# network architecture parameters
parser.add_argument('--enc', type=int, nargs='+',
                    help='list of unet encoder filters (default: 16 32 32 32)')
parser.add_argument('--dec', type=int, nargs='+',
                    help='list of unet decorder filters (default: 32 32 32 32 32 16 16)')

# loss hyperparameters
parser.add_argument('--image-loss', default='mse',
                    help='image reconstruction loss - can be mse or ncc (default: mse)')
parser.add_argument('--image-loss-weight', type=float, default=0.5,
                    help='relative weight of transformed atlas loss (default: 1.0)')
parser.add_argument('--mean-loss-weight', type=float, default=1.0,
                    help='weight of mean stream loss (default: 1.0)')
parser.add_argument('--grad-loss-weight', type=float, default=0.01,
                    help='weight of gradient loss (lamba) (default: 0.01)')

args = parser.parse_args()

# load and prepare training data
train_files = vxm.py.utils.read_file_list(args.img_list, prefix=args.img_prefix,
                                          suffix=args.img_suffix)
assert len(train_files) > 0, 'Could not find any training data.'

# prepare model folder
model_dir = args.model_dir
os.makedirs(model_dir, exist_ok=True)

# no need to append an extra feature axis if data is multichannel
add_feat_axis = not args.multichannel

# fake affine matrix for the template image (subject to RAS+ orientation)
template_affine = [[args.imgVoxelSize[0], 0, 0, 0],
                   [0, args.imgVoxelSize[1], 0, 0],
                   [0, 0, args.imgVoxelSize[2], 0],
                   [0,0,0,1]]

# prepare the initial weights for the template
if args.init_template:
    # load template from file
    template = vxm.py.utils.load_volfile(args.init_template,
                                         add_batch_axis=True, add_feat_axis=add_feat_axis)
else:
    # generate rough atlas by averaging inputs
    navgs = len(train_files)
    print('Creating starting template by averaging first %d scans.' % navgs)
    template = 0
    for scan in train_files[:navgs]:
        template += vxm.py.utils.load_volfile(scan, add_batch_axis=True,
                                              add_feat_axis=add_feat_axis)
    template = template / navgs
    # save average input atlas for the record
    vxm.py.utils.save_volfile(template.squeeze(), os.path.join(model_dir, 'init_template.nii.gz'), template_affine)

# get template shape (might differ from image input shape)
template_shape = template.shape[1:-1]
nfeats = template.shape[-1]

# # unet architecture
enc_nf = args.enc if args.enc else [16, 32, 32, 32]
dec_nf = args.dec if args.dec else [32, 32, 32, 32, 32, 16, 16]

# configure generator
generator = vxm.generators.template_creation(
    train_files, bidir=True, batch_size=args.batch_size, add_feat_axis=add_feat_axis)

# prepare model checkpoint save path
save_filename = os.path.join(model_dir, '{epoch:06d}.h5')

# build model
model = vxm.networks.TemplateCreation(
    template_shape,
    nb_unet_features=[enc_nf, dec_nf],
    atlas_feats=nfeats,
    src_feats=nfeats
)

# set initial template weights
model.set_atlas(template)

# load initial weights (if provided)
if args.load_weights:
    model.load_weights(args.load_weights, by_name=True)

# prepare image loss
if args.image_loss == 'ncc':
    image_loss_func = vxm.losses.NCC().loss
elif args.image_loss == 'mse':
    image_loss_func = vxm.losses.MSE().loss
else:
    raise ValueError('Image loss should be "mse" or "ncc", but found "%s"' % args.image_loss)

# make sure the warped target is compared to the generated atlas and not the input atlas
neg_loss_func = lambda _, y_pred: image_loss_func(model.references.atlas_tensor, y_pred)

losses = [image_loss_func, neg_loss_func,
          vxm.losses.MSE().loss, vxm.losses.Grad('l2', loss_mult=2).loss]
weights = [args.image_loss_weight, 1 - args.image_loss_weight,
           args.mean_loss_weight, args.grad_loss_weight]

# (added by YC) single-gpu training
save_callback = keras.callbacks.ModelCheckpoint(save_filename, period=save_model_per_epoch)

model.compile(optimizer=Adam(learning_rate=args.lr), loss=losses, loss_weights=weights)

# save starting weights
model.save(save_filename.format(epoch=args.initial_epoch))

# model training
# (added by YC Yao) model training
if len(range(args.initial_epoch, args.epochs-save_model_per_epoch+1, save_model_per_epoch)):
    for epoch in range(args.initial_epoch, args.epochs-save_model_per_epoch+1, save_model_per_epoch):
        model.fit_generator(generator,
                            initial_epoch=epoch,
                            epochs=epoch+save_model_per_epoch,
                            callbacks=[save_callback],
                            steps_per_epoch=args.steps_per_epoch,
                            verbose=1
                            )
        vxm.py.utils.save_volfile(model.get_atlas(), os.path.join(model_dir, 'template_epoch'+str(epoch+save_model_per_epoch).zfill(6)+'.nii.gz'), template_affine)
    if epoch+save_model_per_epoch < args.epochs:
        save_callback_final = keras.callbacks.ModelCheckpoint(save_filename, period=args.epochs-epoch-save_model_per_epoch)
        model.fit_generator(generator,
                            initial_epoch=epoch+save_model_per_epoch,
                            epochs=args.epochs,
                            callbacks=[save_callback_final],
                            steps_per_epoch=args.steps_per_epoch,
                            verbose=1
                            )
        vxm.py.utils.save_volfile(model.get_atlas(), os.path.join(model_dir, 'template_epoch'+str(args.epochs).zfill(6)+'.nii.gz'), template_affine)
else:
    save_callback_final = keras.callbacks.ModelCheckpoint(save_filename, period=args.epochs-args.initial_epoch)
    model.fit_generator(generator,
                        initial_epoch=args.initial_epoch,
                        epochs=args.epochs,
                        callbacks=[save_callback_final],
                        steps_per_epoch=args.steps_per_epoch,
                        verbose=1
                        )
    vxm.py.utils.save_volfile(model.get_atlas(), os.path.join(model_dir, 'template_epoch'+str(args.epochs).zfill(6)+'.nii.gz'), template_affine)

