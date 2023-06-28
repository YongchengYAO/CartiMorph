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

| Dataset   | Utility               | Size | KL Grade (KL0-4)  |
| --------- | --------------------- | ---- | ----------------- |
| dataset 1 | template construction | 103  | 103/0/0/0/0       |
| dataset 2 | model training        | 383  | 82/46/86/111/58   |
| dataset 3 | model testing         | 98   | 21/12/22/28/15    |
| dataset 4 | framework evaluation  | 481  | 103/58/108/139/73 |
| dataset 5 | FCL manual grading    | 79   | 2/1/7/22/47       |

### Preparing Data

To reproduce and validate our work, follow the steps to prepare data.

1. Download MR images from the OAI dataset using the image path list, and convert `.dcm` to `.nii.gz` format using tools like [dcm2niix](https://github.com/rordenlab/dcm2niix)

2. Download segmentation masks from the OAI-ZIB dataset

3. Use our script (`raw2nii.py`) to convert `.raw`/`.mhd` files to `.nii.gz` files

   ```bash
   python raw2nii.py --path_raw /path/to/raw-mhd/folder --path_nii /path/to/nii/2
   # or
   python raw2nii.py -i /path/to/raw-mhd/folder -o /path/to/nii/folder
   ```

4. Use our script (`copyAffineMat_img2seg.m`) to modify the affine transformation matrix in the NIfTI header of the segmentation mask converted from `.raw`/`.mhd` files

5. Use our script (`splitTC.m`) to split the tibial cartilage into medial tibial cartilage (mTC) and lateral tibial cartilage (lTC)

   - you need to use the subject information table

   

   



## Methods

(in progress)
