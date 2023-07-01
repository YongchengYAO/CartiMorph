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

# 2d model prediction folder
# e.g. nnUNet_prediction_out_2d='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_prediction/Task106_test6/inference/2d' 
export nnUNet_prediction_out_2d='path/to/2d-model/prediction/folder'

# 3dCF model prediction folder
# e.g. nnUNet_prediction_out_3dCF='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_prediction/Task106_test6/inference/3dCF' 
export nnUNet_prediction_out_3dCF='path/to/3dCF-model/prediction/folder'

# 2d3dCF model prediction folder
# e.g. nnUNet_prediction_out_2d3dCF='~/Documents/CartiMorph/Models_training/nnUNet/nnUNet_prediction/Task106_test6/inference/2d3dCF' 
export nnUNet_prediction_out_2d3dCF='path/to/3dCF-model/prediction/folder'

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

# ----------------------------------------------
# set post-processing configuration for the ensembled model
# ----------------------------------------------
export nnUNet_model_ensemble="$RESULTS_FOLDER/nnUNet/ensembles"
export nnUNet_pp_2d3dCF="$nnUNet_model_ensemble/$nnUNet_taskName/ensemble_2d__nnUNetTrainerV2__nnUNetPlansv2.1--3d_cascade_fullres__nnUNetTrainerV2CascadeFullRes__nnUNetPlansv2.1/postprocessing.json"
# ----------------------------------------------

export nnUNet_plans_identifier='nnUNetPlansv2.1' 

# [Logging] 
export log_file_2d='path/to/log/file/predicting_2d.log' 
export log_file_3dCF='path/to/log/file/predicting_3dCF.log' 
export log_file_2d3dCF='path/to/log/file/predicting_2d3dCF.log' 


if [ ! -d $nnUNet_prediction_out_2d ]; then
  # if the folder doesn't exist, create it
  mkdir -p $nnUNet_prediction_out_2d
  echo "Folder created: $nnUNet_prediction_out_2d"
else
  echo "Folder already exists: $nnUNet_prediction_out_2d"
fi

if [ ! -d $nnUNet_prediction_out_3dCF ]; then
  # if the folder doesn't exist, create it
  mkdir -p $nnUNet_prediction_out_3dCF
  echo "Folder created: $nnUNet_prediction_out_3dCF"
else
  echo "Folder already exists: $nnUNet_prediction_out_3dCF"
fi

if [ ! -d $nnUNet_prediction_out_2d3dCF ]; then
  # if the folder doesn't exist, create it
  mkdir -p $nnUNet_prediction_out_2d3dCF
  echo "Folder created: $nnUNet_prediction_out_2d3dCF"
else
  echo "Folder already exists: $nnUNet_prediction_out_2d3dCF"
fi
 
# ----------------------------------------------
# Model ensemble: 2d and 3dCF
# ----------------------------------------------
# 2d model prediction
CUDA_VISIBLE_DEVICES=$gpuIDs CartiMorph_nnUNet_predict -i "$nnUNet_prediction_in" -o "$nnUNet_prediction_out_2d" -tr nnUNetTrainerV2 -m 2d -p "$nnUNet_plans_identifier" -t "$nnUNet_taskName" 2>&1 > "$log_file_2d" 

# 3dCF model prediction
CUDA_VISIBLE_DEVICES=$gpuIDs CartiMorph_nnUNet_predict -i "$nnUNet_prediction_in" -o "$nnUNet_prediction_out_3dCF" -ctr nnUNetTrainerV2CascadeFullRes -m 3d_cascade_fullres -p "$nnUNet_plans_identifier" -t "$nnUNet_taskName" 2>&1 > "$log_file_3dCF" 

# model ensembel
CUDA_VISIBLE_DEVICES=$gpuIDs CartiMorph_nnUNet_ensemble -f $nnUNet_prediction_out_2d $nnUNet_prediction_out_3dCF -o $nnUNet_prediction_out_2d3dCF -pp $nnUNet_pp_2d3dCF 2>&1 > "$log_file_2d3dCF" 
# ----------------------------------------------
