# Prepare Non-Image Data

The page will guide you through the steps to collect and merge non-image data for each MR image used in our study. Finally, you can construct a [subject information table](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/OAIZIB_subject_info.xlsx) which contains the following fields:

- `SubjectID`: a unique ID for each subject 
- `Path`: the path of MR image in the OAI dataset (baseline cohort)
- `MRBarCode`: a unique ID for each MR image, used to find corresponding no-image data
- `KneeSide`: knee side (1 for right, 2 for left)
- `KLGrade`: Kellgren-Lawrence grade
- `Gender`: gender of the subject (1 for male, 2 for female)
- `Age`: age of the subject
- `BMI`: Body Mass Index of the subject



## Raw Non-Image Data from OAI

1. Download the `OAICompleteData_SAS` from the [OAI dataset](https://pubdata.zib.de)

2. Convert the following `.sas7bdat` files to `.xlsx` using our script ([`sas2xlsx.py`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/sas2xlsx.py)):

   - `mri00.sas7bdat`: knee side 
   - `kxr_sq_bu00.sas7bdat`: KL grade
   - `enrollees.sas7bdat`: gender
   - `allclinical00.sas7bdat`: BMI
   - `subjectchar00.sas7bdat`: age

   e.g. 

   ```python
   python sas2xlsx.py --sas mri00.sas7bdat --xlsx mri00.xlsx
   python sas2xlsx.py --sas kxr_sq_bu00.sas7bdat --xlsx kxr_sq_bu00.xlsx
   python sas2xlsx.py --sas enrollees.sas7bdat --xlsx enrollees.xlsx
   python sas2xlsx.py --sas allclinical00.sas7bdat --xlsx allclinical00.xlsx
   python sas2xlsx.py --sas subjectchar00.sas7bdat --xlsx subjectchar00.xlsx 
   ```

3. construct the subject information table with our script ([`prepareNonImageData.m`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/prepareNonImageData.m))



## Processed Data

Data can be found [here](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/subject_info_source).



