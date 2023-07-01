# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 
 
# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
 
# path to the folder containing the pyhton script "inference_temp2img_warpTempSeg.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm' 
export dir_scripts='path/to/python/script/folder' 

# path to the target image folder
# e.g. dir_targetImg='~/Documents/CartiMorph/Models_training/vxm/vxm_data/imagesInference' 
export dir_targetImg='path/to/target/image/folder' 

# path to the template segmentation mask
# e.g. file_TempSeg='~/Documents/CartiMorph/Models_training/vxm/vxm_data/template/templateSeg.nii.gz' 
export file_TempSeg='path/to/template/segmentation/file' 

# output folder for the warpped template segmentation masks
# e.g. dir_warppedTempSeg='~/Documents/CartiMorph/Models_training/vxm/vxm_inference/temp2img_warppedTempSeg' 
export dir_warppedTempSeg='path/to/warpped/template/segmentation' 

# output folder for the deformation fields
# e.g. dir_warppingField='~/Documents/CartiMorph/Models_training/vxm/vxm_inference/temp2img_warppingField'
export dir_warppingField='path/to/deformation/fields' 

# set the path to the trained model
# e.g. file_model='~/Documents/CartiMorph/Models_training/vxm/vxm_models/bestModel.h5' 
export file_model='path/to/the/trained/model/bestModel.h5' 

export gpuIDs='0' 

# [Logging] 
export log_file='path/to/log/file/predicting_warpTempSeg.log' 


"$dir_scripts"/inference_temp2img_warpTempSeg.py --dir_targetImg "$dir_targetImg" --file_TempSeg "$file_TempSeg" --dir_warppedTempSeg "$dir_warppedTempSeg" --dir_warppingField "$dir_warppingField" --file_model "$file_model" --gpuIDs "$gpuIDs" 2>&1 > "$log_file"
