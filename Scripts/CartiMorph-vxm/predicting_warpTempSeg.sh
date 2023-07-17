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

# output folder for the warped template segmentation masks
# e.g. dir_warpedTempSeg='~/Documents/CartiMorph/Models_training/vxm/vxm_inference/temp2img_warpedTempSeg' 
export dir_warpedTempSeg='path/to/warped/template/segmentation' 

# output folder for the deformation fields
# e.g. dir_warpingField='~/Documents/CartiMorph/Models_training/vxm/vxm_inference/temp2img_warpingField'
export dir_warpingField='path/to/deformation/fields' 

# set the path to the trained model
# e.g. file_model='~/Documents/CartiMorph/Models_training/vxm/vxm_models/bestModel.h5' 
export file_model='path/to/the/trained/model/bestModel.h5' 

export gpuIDs='0' 

# [Logging] 
export log_file='path/to/log/file/predicting_warpTempSeg.log' 


"$dir_scripts"/inference_temp2img_warpTempSeg.py --dir_targetImg "$dir_targetImg" --file_TempSeg "$file_TempSeg" --dir_warpedTempSeg "$dir_warpedTempSeg" --dir_warpingField "$dir_warpingField" --file_model "$file_model" --gpuIDs "$gpuIDs" >> "$log_file" 2>&1
