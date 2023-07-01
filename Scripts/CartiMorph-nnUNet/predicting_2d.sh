# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-nnUNet 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-nnUNet/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-nnUNet/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 

# (optional)
# export MKL_NUM_THREADS=6 

# inference image folder
# e.g. nnUNet_prediction_in='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_raw_data_base/nnUNet_raw_data/Task106_test6/imgInference' 
export nnUNet_prediction_in='path/to/inference/image/folder' 

# model prediction folder
# e.g. nnUNet_prediction_out='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_prediction/Task106_test6/inference/2d' 
export nnUNet_prediction_out='path/to/model/prediction/folder'

# task name should be in the form of Task[xxx]_[task-name]
export nnUNet_taskName='Task106_test6' 

# select GPU
export gpuIDs='0' 
 
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
export log_file='path/to/log/file/predicting_2d.log' 

export nnUNet_archi='2d' 
export nnUNet_plans_identifier='nnUNetPlansv2.1' 


if [ ! -d $nnUNet_prediction_out ]; then
  # if the folder doesn't exist, create it
  mkdir -p $nnUNet_prediction_out
  echo "Folder created: $nnUNet_prediction_out"
else
  echo "Folder already exists: $nnUNet_prediction_out"
fi

# ----------------------------------------------
# Have you train the model in the 5-fold validation setting?
# ----------------------------------------------
# no
export nnUNet_fold='all' 
CUDA_VISIBLE_DEVICES=$gpuIDs CartiMorph_nnUNet_predict -i "$nnUNet_prediction_in" -o "$nnUNet_prediction_out" -f "$nnUNet_fold" -tr nnUNetTrainerV2 -m "$nnUNet_archi" -p "$nnUNet_plans_identifier" -t "$nnUNet_taskName" 2>&1 > "$log_file"  

# yes
# CUDA_VISIBLE_DEVICES=$gpuIDs CartiMorph_nnUNet_predict -i "$nnUNet_prediction_in" -o "$nnUNet_prediction_out" -tr nnUNetTrainerV2 -m "$nnUNet_archi" -p "$nnUNet_plans_identifier" -t "$nnUNet_taskName" 2>&1 > "$log_file" 
# ----------------------------------------------
