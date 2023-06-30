# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 

# path to template image 
# e.g. file_targetTemp="~/Documents/CartiMorph/Models_training/vxm/vxm_data/template/template.nii.gz" 
export file_targetTemp="path/to/template/template.nii.gz" 

# folder of training images
export dir_sourceImgs="path/to/training/images" 

# folder of the segmentation masks of training images
export dir_sourceLabels="path/to/training/segmentations" 

# folder of the output segmentation masks warpped to the template image space
export dir_warppedLabels="path/to/warpped/segmentations" 

# trained model
export file_model='path/to/model/xxxxxx.h5' 

# path to the folder containing the pyhton script "inference_getTempSeg.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm' 
export dir_scripts='path/to/python/script/folder' 
export gpuIDs=0


# ====== registration ========================= 
for img in $dir_sourceImgs/*.nii.gz 
do 
    export file_sourceImg="$dir_sourceImgs/${img##*/}" 
    export file_sourceLabel="$dir_sourceLabels/${img##*/}" 
    export file_warppedLabel="$dir_warppedLabels/${img##*/}" 
    "$dir_scripts"/inference_img2temp_warpLabel.py --file_targetTemp "$file_targetTemp" --file_sourceImg "$file_sourceImg" --file_sourceLabel "$file_sourceLabel" --file_warppedLabel "$file_warppedLabel" --file_model "$file_model" --gpuIDs "$gpuIDs" 
done 
# ====== registration ========================= 
