# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-nnUNet 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-nnUNet/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-nnUNet/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
 
# ----------------------------------------------
# modify this section to fit in your case
# ----------------------------------------------
export nnUNet_taskName='Task106_test6' 
export nnUNet_taskID='106' 
# ----------------------------------------------

export gpuIDs='0' 
export nnUNet_trainer='nnUNetTrainerV2' 
export epoch=500 
export nnUNet_architecture='3d_fullres' 
export nnUNet_fold='all' 

# ----------------------------------------------
# set paths for CartiMorph-nnUNet, a work based on nnUNet
# FYI: https://github.com/MIC-DKFZ/nnUNet/blob/nnunetv1/documentation/setting_up_paths.md
# ----------------------------------------------
# raw data folder -- required by nnUNet
# e.g. nnUNet_raw_data_base='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_raw_data_base' 
export nnUNet_raw_data_base='path/to/raw/data/folder/nnUNet_raw_data_base' 

# preprocessed data folder -- required by nnUNet
# e.g. nnUNet_preprocessed='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_preprocessed' 
export nnUNet_preprocessed='path/to/preprocessed/data/folder/nnUNet_preprocessed' 

# result folder -- required by nnUNet
# e.g. RESULTS_FOLDER='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_trained_models' 
export RESULTS_FOLDER='path/to/result/folder/nnUNet_trained_models' 
# ----------------------------------------------

# [Logging] 
export log_file='path/to/log/file/training_3dF.log' 
 
CUDA_VISIBLE_DEVICES=$gpuIDs CartiMorph_nnUNet_train $nnUNet_architecture $nnUNet_trainer $nnUNet_taskID $nnUNet_fold --epoch $epoch 2>&1 > "$log_file" 
