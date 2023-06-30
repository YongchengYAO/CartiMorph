from batchgenerators.utilities.file_and_folder_operations import * 
from CartiMorph_nnUNet.dataset_conversion.utils import generate_dataset_json 
from CartiMorph_nnUNet.paths import nnUNet_raw_data, preprocessing_output_dir 

# ================================================================
# "nnUNet_raw_data" is the folder of raw data you set with the command:
#   export nnUNet_raw_data_base='path/to/raw/data/folder/nnUNet_raw_data_base' 
# 
# arrange our training data like this:
# ├── [nnUNet_raw_data]
#     ├── [task_name]
#         ├── imagesTr
#         ├── imagesTs
#         ├── labelsTr
#         ├── labelsTs
# ----------------------------------------------------------------
# task name should be in the form of Task[xxx]_[task-name]
task_name='Task106_test6' 
target_base = join(nnUNet_raw_data, task_name) 
target_imagesTr = join(target_base, 'imagesTr') 
target_imagesTs = join(target_base, 'imagesTs') 
target_labelsTr = join(target_base, 'labelsTr') 
target_labelsTs = join(target_base, 'labelsTs') 
# ================================================================
 
generate_dataset_json(join(target_base, 'dataset.json'), target_imagesTr, target_imagesTs, ('D'), 
    labels={0: 'background', 1: 'femur', 2: 'femoral cartilage', 3: 'tibia', 4: 'medial tibial cartilage', 5: 'lateral tibial cartilage'}, 
    dataset_name=task_name) 
