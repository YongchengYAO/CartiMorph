# CartiMorph

[Python: 3.10] [Matlab: 2022b]

Code and documents will be available when our paper is published.

[!] I’ll update this repo by 30 June 2023. Stay tuned!



## 1. Publication

**CartiMorph: a framework for automated knee articular cartilage morphometrics** (under review)

- a method for automated cartilage thickness mapping that is robust to cartilage lesions
- a method for automated full-thicknes cartilage loss (FCL) estimation
- a rule-based cartilage parcellation method that is robust ot FCL

![paper-CartiMorph-bw](README.assets/paper-CartiMorph-bw.png)

| Notation                                     | Meaning                                                     |
| -------------------------------------------- | ----------------------------------------------------------- |
| $I_i$                                        | MR image                                                    |
| $S_i$                                        | Segmentation mask                                           |
| $S_i^l$                                      | Manual segmentation label                                   |
| $I^t$                                        | Template image                                              |
| $S^t$                                        | Template segmentation mask                                  |
| $\mathcal{F}_{\theta_s}$                     | Segmentation model                                          |
| $\mathcal{G}_{\theta_t}$                     | Template learning model – essentially a registration model  |
| $\mathcal{G}_{\theta_u}$                     | Registration model                                          |
| $\mathcal{M}_{down, \theta_i}(\cdot, \cdot)$ | Dowsample function consisting of cropping and resampling    |
| $\mathcal{M}_{up}(\cdot, \cdot)$             | Upsample function consisting of resampling and zero-filling |



## 2. Data

### 2.1 Datasets and Data Split

MR images: [Osteoarthritis Initiative (OAI) dataset](https://nda.nih.gov/oai/)

Cartilage and bone segmentation masks: [OAI-ZIB dataset](https://pubdata.zib.de)

- 507 segmentations for DESS MRIs from the OAI database
- segmentation masks for the femur (ROI1), femoral cartilage (ROI2), tibia (ROI3), and tibial cartilage (ROI4)
- file format: `.raw` and `.mhd`

Data split in our study: 

| Dataset                                                      | Utility               | Size | KL Grade (KL0-4)  |
| ------------------------------------------------------------ | --------------------- | ---- | ----------------- |
| [dataset 1](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/CartiMorph_dataset1.xlsx) | template construction | 103  | 103/0/0/0/0       |
| [dataset 2](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/CartiMorph_dataset2.xlsx) | model training        | 383  | 82/46/86/111/58   |
| [dataset 3](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/CartiMorph_dataset3.xlsx) | model testing         | 98   | 21/12/22/28/15    |
| [dataset 4](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/CartiMorph_dataset4.xlsx) | framework evaluation  | 481  | 103/58/108/139/73 |
| [dataset 5](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/CartiMorph_dataset5.xlsx) | FCL manual grading    | 79   | 2/1/7/22/47       |

### 2.2 Preparing Data

To reproduce and validate our work, follow the steps to prepare data.

1. Download MR images from the OAI baseline dataset using the image paths in the [subject information table](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/OAIZIB_subject_info.xlsx), and convert `.dcm` to `.nii.gz` format with tools like [dcm2niix](https://github.com/rordenlab/dcm2niix)

2. Download segmentation masks in `.raw`/`.mhd` format from the OAI-ZIB dataset

3. Use our script ([`raw2nii.py`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/raw2nii.py)) to convert `.raw`/`.mhd` files to `.nii.gz` files

   ```bash
   python raw2nii.py --path_raw /path/to/raw-mhd/folder --path_nii /path/to/nii/folder
   # or
   python raw2nii.py -i /path/to/raw-mhd/folder -o /path/to/nii/folder
   ```

4. Use our script ([`copyAffineMat_img2seg.m`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/copyAffineMat_img2seg.m)) to modify the affine transformation matrix in the NIfTI header of the segmentation mask 

   - that’s because the affine matrix is corrupt in `.mhd` files

5. Use our script ([`splitTC.m`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/splitTC.m)) to split the tibial cartilage into medial tibial cartilage (mTC) and lateral tibial cartilage (lTC)

   - you need to use the [subject information table](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/OAIZIB_subject_info.xlsx)

### 2.3 CartiMorph Data Request

If you want to download the modified segmentation masks in `.nii.gz`, please follow the steps:

1. Register at [ZIB-Pubdata](https://pubdata.zib.de) for access to the “Manual Segmentations” dataset

2. Find my email address on the left sidebar of my [personal webpage](https://yongchengyao.github.io), and ask for data sharing via email.

   - Email title: [CartiMorph Data Request] + [your institution]

   - you should include your login email for ZIB-Pubdata in the request

     

## 3. Methods

### 3.1 Image Standardisation

By implementing an image standardization scheme, the proposed framework is capable of processing images of different orientations and sizes. This involves reorienting all images to the RAS+ direction, where the first, second, and third dimensions of the image array correspond to the left-right, posterior-anterior, and inferior-superior directions, respectively.

Use our script ([`imgStandardisation.m`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph/imgStandardisation.m)) to standardise images and segmentation labels before model training and other algorithms. Use the processed images in the remaining experiments.



### 3.2 Knee Template Learning

**Model Training:**

1. Setup a Conda environment using our script ([`envSetup_CartiMorph-vxm.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/envSetup/envSetup_CartiMorph-vxm.sh)) – it will create an virtual environment `CartiMorphToolbox-Vxm` and install [`CartiMorph-vxm`](https://github.com/YongchengYAO/CartiMorph-vxm)

2. Prepare training data using the [image list](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/CartiMorph_dataset1.xlsx) and our script ([`prepareData4Reg.m`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph/prepareData4Reg.m))

3. Train a model to learn a representative template image

   - [`training_scratch.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph-vxm/training_scratch.sh): train a model from scratch
   - [`training_continue.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph-vxm/training_continue.sh): continue training

4. Construct the segmentation mask for the learning template image

   1. Warp manual segmentation labels of training images to the template image space with our script ([`predicting_getTempSeg.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph-vxm/predicting_getTempSeg.sh))
   2. Construct template segmentation with out script ([`constructTempSeg.m`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph/constructTempSeg.m))

   

### 3.3 Cartilage & Bone Segmentation

**Model Training:**

1. Setup a Conda environment using our script ([`envSetup_CartiMorph-nnUNet.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/envSetup/envSetup_CartiMorph-nnUNet.sh)) – it will create an virtual environment `CartiMorphToolbox-nnUNet` and install [`CartiMorph-nnUNet`](https://github.com/YongchengYAO/CartiMorph-nnUNet)
2. Image preprocessing
   1. modify [`generate_dataset_json.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph-nnUNet/generate_dataset_json.sh) and [`generate_dataset_json.py`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph-nnUNet/generate_dataset_json.py), then run `generate_dataset_json.sh`
   2. preprocess data uisng our script ([`planning_preprocessing.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph-nnUNet/planning_preprocessing.sh))
3. Train the model with our script ([`training_3dF.sh`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/CartiMorph-nnUNet/training_3dF.sh))



### 3.4 Template-to-image Registration

**Model Training:**



### 3.5 Cartilage Morphometrics

We adopt the mathematical notations as those used in the paper.

**Surface Closing:**     $ \mathcal{O}_c(\cdot | \cdot)$     [script]

**Surface Dilation:**     $\mathcal{O}_d^{n_d}(\cdot | \cdot)$    [script]

**Surface Erosion:**     $\mathcal{O}_e^{n_e}(\cdot)$    [script]

**Restricted Surface Dilation:**     $ \mathcal{O}_{rd}(\cdot | \cdot, \cdot)$     [script]

**Surface Hole Filling:**     $\mathcal{O}_{sf}(\cdot , \cdot)$      [script]





## Acknowledgement

- We thank the Osteoarthritis Initiative (OAI) for sharing MR images and non-image clinical data –  [Osteoarthritis Initiative (OAI) dataset](https://nda.nih.gov/oai/)
- We thank the Computational Diagnosis and Therapy Planning Group of Zuse Institute Berlin (ZIB) for sharing the manual segmentation masks –  [OAI-ZIB dataset](https://pubdata.zib.de)

- Our work is partially based on [nnUNet](https://github.com/MIC-DKFZ/nnUNet)
- Our work is partially based on [VoxelMorph](https://github.com/voxelmorph/voxelmorph)

