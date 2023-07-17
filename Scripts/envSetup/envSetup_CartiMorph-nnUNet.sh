#!/usr/bin/env bash

Dir_current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Dir_parent="${Dir_current%/*}"

# create Conda environment
conda create -n CartiMorphToolbox-nnUNet -y

# activate Conda environment
eval "$(conda shell.bash hook)"
conda activate CartiMorphToolbox-nnUNet

# Python
conda install python=3.10 -y

# PyTorch
conda install pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia -y

# CartiMorph-nnUnet
python -m pip install CartiMorph-nnUnet