# e.g. ~/Documents/anaconda3/etc/profile.d/conda.sh 
source /path/to/anaconda3/etc/profile.d/conda.sh 

conda activate CartiMorphToolbox-Vxm 

# e.g. LD_LIBRARY_PATH="~/Documents/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
export LD_LIBRARY_PATH="path/to/anaconda3/envs/CartiMorphToolbox-Vxm/lib/python3.10/site-packages/nvidia/cublas/lib:$LD_LIBRARY_PATH" 
 
# [Folders] 
# path to the folder containing the pyhton script "train_tempLearnModel.py"
# e.g. dir_scripts='~/Documents/CartiMorph/Scripts/CartiMorph-vxm' 
export dir_scripts='path/to/python/script/folder' 
# e.g. dir_model='~/Documents/CartiMorph/Models_training/vxm/vxm_models'
export dir_model='path/to/model/folder' 

# [Data] 
# image list
export img_list='path/to/image/list/list_imagesTr.txt' 
# path of image folder
export img_prefix='path/to/image/folder/end/with/slash/' 
# add file extension if the image list does not have one
export img_suffix='' 

# [Training] - continue training
export imgLoss=mse 
export gpuIDs=0
export batch_size=1
# total training epoch
export epochs=500 
export steps_per_epoch=103

# [Logging] 
export log_file='path/to/log/file/training_continue.log' 
 
# [Model]
# set the path to the last model for continue training
export lastModel='path/to/the/last/model/000100.h5' 
# last epoch
export lastEpoch=100 
# last template image
export lastTemplate='path/to/the/last/template/template_epoch000100.nii.gz' 


# set the voxel size of the learned template image
# - it is for better visualization
# - it does not affect model performance and algorithm accuracy
# - you may set it to the voxel size of the first image 

# [option 1]
# modify the "--imgVoxelSize 1.0295 0.39976 0.39976" below
CUDA_VISIBLE_DEVICES=$gpuIDs "$dir_scripts"/train_tempLearnModel.py --imgVoxelSize 1.0295 0.39976 0.39976 --enc 16  32  32  32 --dec 32  32  32  32  32  16  16 --image-loss "$imgLoss" --img-list "$img_list" --img-prefix "$img_prefix" --img-suffix "$img_suffix" --init-template "$lastTemplate" --model-dir "$dir_model" --batch-size "$batch_size"  --epochs "$epochs" --steps-per-epoch "$steps_per_epoch" --load-weights "$lastModel" --initial-epoch "$lastEpoch" 2>&1 > "$log_file"

# [option 2]
# use this command instead if you want to freeze the learned template and only train the registration module/subnetwork
# (we add the argument "--freezeTemp")
# CUDA_VISIBLE_DEVICES=$gpuIDs "$dir_scripts"/train_tempLearnModel.py --imgVoxelSize 1.0295 0.39976 0.39976 --freezeTemp --enc 16  32  32  32 --dec 32  32  32  32  32  16  16 --image-loss "$imgLoss" --img-list "$img_list" --img-prefix "$img_prefix" --img-suffix "$img_suffix" --init-template "$lastTemplate" --model-dir "$dir_model" --batch-size "$batch_size"  --epochs "$epochs" --steps-per-epoch "$steps_per_epoch" --load-weights "$lastModel" --initial-epoch "$lastEpoch" 2>&1 > "$log_file"
