# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH"# template folder

# [Folders]
# path to the folder containing the pyhton script "inference_warping.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm/regModel' 
export dir_scripts='path/to/python/script/folder'
# folder for warping field
export dir_warpingField="path/to/warping/field/folder"
# folder for warped template segmentations -- the output
export dir_warpedSeg="path/to/warped/template/segmentation/folder"

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
for warpField in $dir_warpingField/*.nii.gz 
do
    # [Input]
    # warping field
    export warpingField_name="${warpField##*/}"

    # [Output]
    # warped template segmentation
    export img_warpedTempSeg="$dir_warpedSeg/${warpingField_name}"

    # warp atlas
    "$dir_scripts"/inference_warping.py --gpu "$gpuIDs" --moving "$tempSeg" --warp "$warpField" --moved "$img_warpedTempSeg" --interp "$method_interp" 2>&1 >> "$log_file"
done
# ====== registration =========================
