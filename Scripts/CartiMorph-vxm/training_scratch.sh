# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 

# [Folder]
# path to the folder containing the pyhton script "train_tempLearnModel.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm' 
export dir_scripts='path/to/python/script/folder' 
# model folder
# e.g. dir_model='~/Documents/CartiMorph/Models_training/vxm/vxm_models'
export dir_model='path/to/model/folder' 

# [Data] 
# image list
export img_list='path/to/image/list/list_imagesTr.txt' 
# path of image folder
export img_prefix='path/to/image/folder/end/with/slash/' 
# add file extension if the image list does not have one
export img_suffix='' 

# [Training] - train from scratch
export imgLoss=mse 
export gpuIDs=0
export batch_size=1
# total training epoch
export epochs=1000
export steps_per_epoch=100

# [Logging] 
export log_file='path/to/log/file/training_scratch.log' 


if [ ! -d $dir_model ]; then
  # if the folder doesn't exist, create it
  mkdir -p $dir_model
  echo "Folder created: $dir_model"
else
  echo "Folder already exists: $dir_model"
fi

# set the voxel size of the learned template image
# - it is for better visualization
# - it does not affect model performance and algorithm accuracy
# - you may set it to the voxel size of the first image 

# modify the "--imgVoxelSize 1.0295     0.39976     0.39976" below
CUDA_VISIBLE_DEVICES=$gpuIDs "$dir_scripts"/train_tempLearnModel.py --enc 16  32  32  32 --dec 32  32  32  32  32  16  16 --image-loss "$imgLoss" --imgVoxelSize 1.0295     0.39976     0.39976 --img-list "$img_list" --img-prefix "$img_prefix" --img-suffix "$img_suffix" --model-dir "$dir_model" --batch-size "$batch_size" --epochs "$epochs" --steps-per-epoch "$steps_per_epoch"  2>&1 > "$log_file"
