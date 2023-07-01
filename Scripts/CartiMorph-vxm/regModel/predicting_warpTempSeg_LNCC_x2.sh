# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH"# template folder

# [Folders]
# path to the folder containing the pyhton script "inference_warpping.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm/regModel' 
export dir_scripts='path/to/python/script/folder'
# folder for warping field
export dir_warppingField="path/to/warpping/field/folder"
# folder for warpped template segmentations -- the output
export dir_warppedSeg="path/to/warpped/template/segmentation/folder"

# GPU usage
export gpuIDs=0

# [Input]
# path to template segmentation
export tempSeg='path/to/template/segmentation'

# interpretation method (linear/nearest)
export method_interp="nearest"

# [Logging] 
export log_file='path/to/log/file/predicting_warpTempSeg_LNCC_x2.log' 


# ====== registration =========================
for warpField in $dir_warppingField/*.nii.gz 
do
    # [Input]
    # warping field
    export warppingField_name="${warpField##*/}"

    # [Output]
    # warped template segmentation
    export img_warppedTempSeg="$dir_warppedSeg/${warppingField_name}"

    # warp atlas
    "$dir_scripts"/inference_warpping.py --gpu "$gpuIDs" --moving "$tempSeg" --warp "$warpField" --moved "$img_warppedTempSeg" --interp "$method_interp" 2>&1 >> "$log_file"
done
# ====== registration =========================
