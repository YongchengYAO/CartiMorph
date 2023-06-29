# CartiMorph

Code and documents will be available when our paper is published.

[!] I’ll update this repo by 30 June 2023. Stay tuned!

## Paper

**CartiMorph: a framework for automated knee articular cartilage morphometrics** (under review)

![paper-CartiMorph-bw](README.assets/paper-CartiMorph-bw.png)

## Quick Start

(in progress)

## Data

### Datasets and Data Split

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

### Preparing Data

To reproduce and validate our work, follow the steps to prepare data.

1. Download MR images from the OAI baseline dataset using the image paths in the [subject information table](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/OAIZIB_subject_info.xlsx), and convert `.dcm` to `.nii.gz` format with tools like [dcm2niix](https://github.com/rordenlab/dcm2niix)

2. Download segmentation masks in `.raw`/`.mhd` format from the OAI-ZIB dataset

3. Use our [script](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/raw2nii.py) (`raw2nii.py`) to convert `.raw`/`.mhd` files to `.nii.gz` files

   ```bash
   python raw2nii.py --path_raw /path/to/raw-mhd/folder --path_nii /path/to/nii/folder
   # or
   python raw2nii.py -i /path/to/raw-mhd/folder -o /path/to/nii/folder
   ```

4. Use our [script](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/copyAffineMat_img2seg.m) (`copyAffineMat_img2seg.m`) to modify the affine transformation matrix in the NIfTI header of the segmentation mask 

   - that’s because the affine matrix is corrupt in `.mhd` files

5. Use our [script](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/splitTC.m) (`splitTC.m`) to split the tibial cartilage into medial tibial cartilage (mTC) and lateral tibial cartilage (lTC)

   - you need to use the [subject information table](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/OAIZIB_subject_info.xlsx)

### CartiMorph Data Request

If you want to download the modified segmentation masks in `.nii.gz`, please follow the steps:

1. Register at [ZIB-Pubdata](https://pubdata.zib.de) for access to the “Manual Segmentations” dataset
2. Find my email address on the left sidebar of my [personal webpage](https://yongchengyao.github.io), and ask for data sharing via email.
   - Email title: [CartiMorph Data Request] + [your institution]
   - you should include your login email for ZIB-Pubdata in the request

   

   

   

   



## Methods

(in progress)







## Acknowledgement

- We thank the Osteoarthritis Initiative (OAI) for sharing MR images and non-image clinical data

- We thank the Computational Diagnosis and Therapy Planning Group of Zuse Institute Berlin (ZIB) for sharing the manual segmentation masks

  ```latex
  @article{ambellan2019automated,
    title={Automated segmentation of knee bone and cartilage combining statistical shape knowledge and convolutional neural networks: Data from the Osteoarthritis Initiative},
    author={Ambellan, Felix and Tack, Alexander and Ehlke, Moritz and Zachow, Stefan},
    journal={Medical image analysis},
    volume={52},
    pages={109--118},
    year={2019},
    publisher={Elsevier}
  }
  ```

  

