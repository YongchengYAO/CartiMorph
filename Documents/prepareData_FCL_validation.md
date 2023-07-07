# Data for FCL Validation

The page will guide you through the steps to find matching cases that form [dataset 5](https://github.com/YongchengYAO/CartiMorph/blob/main/Dataset/OAIZIB/CartiMorph_dataset5.xlsx) and retrieve metrics calculated from Chondrometrics in the POMA study.

1. Download the `OAICompleteData_SAS` from the [OAI dataset](https://nda.nih.gov/oai/)

2. Convert the following `.sas7bdat` files to `.xlsx` using our script ([`sas2xlsx.py`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/sas2xlsx.py)):

   - `mri00.sas7bdat`: knee side 
   - `kxr_sq_bu00.sas7bdat`: KL grade
   - `enrollees.sas7bdat`: gender
   - `allclinical00.sas7bdat`: BMI
   - `subjectchar00.sas7bdat`: age
   - `kmri_poma_tkr_chondrometrics.sas7bdat`: metrics from Chondrometrics

   e.g. 

   ```python
   python sas2xlsx.py --sas mri00.sas7bdat --xlsx mri00.xlsx
   python sas2xlsx.py --sas kxr_sq_bu00.sas7bdat --xlsx kxr_sq_bu00.xlsx
   python sas2xlsx.py --sas enrollees.sas7bdat --xlsx enrollees.xlsx
   python sas2xlsx.py --sas allclinical00.sas7bdat --xlsx allclinical00.xlsx
   python sas2xlsx.py --sas subjectchar00.sas7bdat --xlsx subjectchar00.xlsx 
   python sas2xlsx.py --sas kmri_poma_tkr_chondrometrics.sas7bdat --xlsx kmri_poma_tkr_chondrometrics.xlsx   
   ```

3. Retrieve metrics from Chondrometrics using our script ([`prepareData_FCL_validation.m`](https://github.com/YongchengYAO/CartiMorph/blob/main/Scripts/data/prepareData_FCL_validation.m))



## Processed Data

Data can be found [here](https://github.com/YongchengYAO/CartiMorph/blob/main/Experiment/FCL_validation/Chondrometrics).



[<<< Back to the main document](https://github.com/YongchengYAO/CartiMorph/tree/main)



