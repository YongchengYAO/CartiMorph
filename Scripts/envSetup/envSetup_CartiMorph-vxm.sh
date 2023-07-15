#!/usr/bin/env bash

Dir_current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Dir_parent="${Dir_current%/*}"

# create Conda environment
conda create -n CartiMorphToolbox-Vxm -y

# activate Conda environment
eval "$(conda shell.bash hook)"
conda activate CartiMorphToolbox-Vxm

# python
conda install python=3.10 -y

# TensorFlow
python -m pip install tensorflow==2.9

# VoxelMorph
python -m pip install chardet==5.1.0
python -m pip install simpleitk==2.1.1.2
python -m pip install keras==2.9.0
python -m pip install neurite==0.2
python -m pip install packaging==21.3
python -m pip install nibabel==3.2.2
python -m pip install numpy==1.23.2
python -m pip install CartiMorph-vxm
