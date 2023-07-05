# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH"# template folder

# [Folder]
# path to the folder containing the pyhton script "inference_register.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm/regModel' 
export dir_scripts='path/to/python/script/folder'
# folder for inference image
export dir_img="path/to/inference/image/folder"
# ouput folder for the warped template image
export dir_warpedTemp="path/to/warped/template/image/folder"
# output folder for warping field
export dir_warpingField="path/to/warping/field/folder"

# GPU
export gpuIDs=0

# [Input]
# knee template
export img_template='path/to/template/image/file' 
# registration model
# e.g. path_model='~/Documents/CartiMorph/Models_training/vxm/vxm_models/regModel/MSE/1000.h5'
export path_model='path/to/model/file' 

# [Logging] 
export log_file='path/to/log/file/predicting_getField_MSE.log' 

s
if [ ! -d $dir_warpedTemp ]; then
  # if the folder doesn't exist, create it
  mkdir -p $dir_warpedTemp
  echo "Folder created: $dir_warpedTemp"
else
  echo "Folder already exists: $dir_warpedTemp"
fi

if [ ! -d $dir_warpingField ]; then
  # if the folder doesn't exist, create it
  mkdir -p $dir_warpingField
  echo "Folder created: $dir_warpingField"
else
  echo "Folder already exists: $dir_warpingField"
fi

# ====== registration =========================
for img in $dir_img/*.nii.gz 
do
    # [Input]
    # fixed image
    export img_kneeMRI="$dir_img/${img##*/}"

    # [Output]
    # warping field
    export img_warpingField="$dir_warpingField/${img##*/}"
    # the warped template
    export img_warpedTemp="$dir_warpedTemp/${img##*/}"

    # create knee template (save log file)
    "$dir_scripts"/inference_register.py --gpu "$gpuIDs" --moving "$img_template" --fixed "$img_kneeMRI" --model "$path_model" --moved "$img_warpedTemp" --warp "$img_warpingField" 2>&1 >> "$log_file"
done
# ====== registration =========================
