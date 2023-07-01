# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH"

# [Folder]
# path to the folder containing the pyhton script "train_img2imgRegModel.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm/regModel' 
export dir_scripts='path/to/python/script/folder'
# model folder
# e.g. dir_model='~/Documents/CartiMorph/Models_training/vxm/vxm_models/regModel/LNCC_x2'
export dir_model='path/to/model/folder' 

# [Data] 
# image list
export img_list='path/to/image/list/list_imagesTr.txt' 
# path of image folder
export img_prefix='path/to/image/folder/end/with/slash/' 
# add file extension if the image list does not have one
export img_suffix='' 

# [Training]
# GPU usage
export gpuIDs=0
# batch size
export batch_size=1
# epochs
export epochs=1000
# steps per epoch
export steps_per_epoch=100
# loss function
export imageLoss="ncc"

# [Logging] 
export log_file='path/to/log/file/training_img2img_LNCC_x2.log' 


if [ ! -d $dir_model ]; then
  # if the folder doesn't exist, create it
  mkdir -p $dir_model
  echo "Folder created: $dir_model"
else
  echo "Folder already exists: $dir_model"
fi

# [training]
# -----------------------------------------------
# baseline model:
#  "--enc 16 32 32 32" -- default
#  "--dec 32 32 32 32 32 16 16" -- default
# -----------------------------------------------
# we train a model with double channels here
"$dir_scripts"/train_img2imgRegModel.py --gpu "$gpuIDs" --image-loss "$imageLoss" --enc 32 64 64 64 --dec 64 64 64 64 64 32 32 --img-list "$img_list" --img-prefix "$img_prefix" --img-suffix "$img_suffix" --model-dir "$dir_model" --batch-size "$batch_size"  --epochs "$epochs" --steps-per-epoch "$steps_per_epoch" 2>&1 > "$log_file"
# -----------------------------------------------
