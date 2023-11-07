#!/usr/bin/env bash

Dir_current="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
Dir_parent="${Dir_current%/*}"

# remove old Conda environment: CartiMorphToolbox-Vxm 
conda remove --name CartiMorphToolbox-Vxm --all -y 

# create Conda environment
conda create -n CartiMorphToolbox-Vxm -y

# activate Conda environment
eval "$(conda shell.bash hook)"
conda activate CartiMorphToolbox-Vxm

# Nvidia libraries
conda install -c conda-forge cudatoolkit=11.8.0 -y
python -m pip install nvidia-cudnn-cu11==8.6.0.163
mkdir -p $CONDA_PREFIX/etc/conda/activate.d 
echo "CUDNN_PATH=$(dirname $(python -c "import nvidia.cudnn;print(nvidia.cudnn.__file__)"))" >> $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh 
echo "export LD_LIBRARY_PATH=$CONDA_PREFIX/lib/:$CUDNN_PATH/lib:$LD_LIBRARY_PATH" >> $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh 
source $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh

# Python
conda install python=3.10 -y

# TensorFlow
python -m pip install tensorflow==2.12

# CartiMorph-vxm
python -m pip install protobuf==3.20.0 
python -m pip install chardet==5.1.0
python -m pip install simpleitk==2.1.1.2
python -m pip install keras==2.9.0
python -m pip install neurite==0.2
python -m pip install packaging==21.3
python -m pip install nibabel==3.2.2
python -m pip install numpy==1.23.2
python -m pip install CartiMorph-vxm