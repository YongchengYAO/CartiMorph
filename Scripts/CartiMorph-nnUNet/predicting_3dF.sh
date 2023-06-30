source /home/yongcheng/local/anaconda3/etc/profile.d/conda.sh 
conda activate CartiMorphToolbox-nnUNet 
 
export MKL_NUM_THREADS=6 
export LD_LIBRARY_PATH="/home/yongcheng/local/anaconda3/envs/CartiMorphToolbox/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
 
export gpuIDs='0' 
export nnUNet_prediction_in='/home/yongcheng/Documents/CartiMorphToolbox/Models_training/nnUNet/nnUNet_raw_data_base/nnUNet_raw_data/Task106_linuxTest6/imgInference' 
export nnUNet_prediction_out='/home/yongcheng/Documents/CartiMorphToolbox/Models_training/nnUNet/nnUNet_prediction/Task106_linuxTest6/inference/3dF' 
export nnUNet_fold='all' 
export nnUNet_archi='3d_fullres' 
export nnUNet_taskName='Task106_linuxTest6' 
export nnUNet_plans_identifier='nnUNetPlans_pretrained_OAIZIB404-17May2023' 
 
export nnUNet_raw_data_base='/home/yongcheng/Documents/CartiMorphToolbox/Models_training/nnUNet/nnUNet_raw_data_base' 
export nnUNet_preprocessed='/home/yongcheng/Documents/CartiMorphToolbox/Models_training/nnUNet/nnUNet_preprocessed' 
export RESULTS_FOLDER='/home/yongcheng/Documents/CartiMorphToolbox/Models_training/nnUNet/nnUNet_trained_models/Task106_linuxTest6' 
 
CUDA_VISIBLE_DEVICES=$gpuIDs nnUNet_predict -i "$nnUNet_prediction_in" -o "$nnUNet_prediction_out" -f "$nnUNet_fold" -tr nnUNetTrainerV2 -m "$nnUNet_archi" -p "$nnUNet_plans_identifier" -t "$nnUNet_taskName" 2>&1 > /home/yongcheng/Documents/CartiMorphToolbox/Models_training/nnUNet/nnUNet_log/Task106_linuxTest6/inference_3dF_inferenceSet.log 
