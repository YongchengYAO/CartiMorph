# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-nnUNet 

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

# 3-digit task ID
export taskID = 106

# [Logging] 
export log_file='path/to/log/file/planning_preprocessing.log' 
 
CartiMorph_nnUNet_plan_and_preprocess -t "$taskID" --verify_dataset_integrity 2>&1 > "$log_file"

# temporary bug-fix (https://github.com/MIC-DKFZ/nnUNet/issues/291)
# e.g. ~/Documents/CartiMorph//Models_training/nnUNet/nnUNet_preprocessed/Task106_test6/nnUNetData_plans_v2.1_stage1/*.npy 
rm path/to/nnUNet_preprocessed/Task[xxx]_[task-name]/nnUNetData_plans_v2.1_stage1/*.npy 
