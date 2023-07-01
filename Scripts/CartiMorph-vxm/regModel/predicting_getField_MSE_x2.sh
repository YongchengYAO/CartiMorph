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
# ouput folder for the warpped template image
export dir_warppedTemp="path/to/warpped/template/image/folder"
# output folder for warping field
export dir_warppingField="path/to/warpping/field/folder"

# GPU
export gpuIDs=0

# [Input]
# knee template
export img_template='path/to/template/image/file' 
# registration model
# e.g. path_model='~/Documents/CartiMorph/Models_training/vxm/vxm_models/regModel/MSE_x2/1000.h5'
export path_model='path/to/model/file' 

# [Logging] 
export log_file='path/to/log/file/predicting_getField_MSE_x2.log' 


if [ ! -d $dir_warppedTemp ]; then
  # if the folder doesn't exist, create it
  mkdir -p $dir_warppedTemp
  echo "Folder created: $dir_warppedTemp"
else
  echo "Folder already exists: $dir_warppedTemp"
fi

if [ ! -d $dir_warppingField ]; then
  # if the folder doesn't exist, create it
  mkdir -p $dir_warppingField
  echo "Folder created: $dir_warppingField"
else
  echo "Folder already exists: $dir_warppingField"
fi

# ====== registration =========================
for img in $dir_img/*.nii.gz 
do
    # [Input]
    # fixed image
    export img_kneeMRI="$dir_img/${img##*/}"

    # [Output]
    # warping field
    export img_warppingField="$dir_warppingField/${img##*/}"
    # the warped template
    export img_warppedTemp="$dir_warppedTemp/${img##*/}"

    # create knee template (save log file)
    "$dir_scripts"/inference_register.py --gpu "$gpuIDs" --moving "$img_template" --fixed "$img_kneeMRI" --model "$path_model" --moved "$img_warppedTemp" --warp "$img_warppingField" 2>&1 >> "$log_file"
done
# ====== registration =========================
