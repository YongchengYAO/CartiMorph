% ==============================================================================
% Function:
%     Atlas construction for the CLAIR-Knee-103R template
%     (1) surface atlas
%     (2) volume atlas
%
% ROI code in the volume atlas:
%     1: aMFC
%     2: ecMFC
%     3: ccMFC
%     4: icMFC
%     5: pMFC
%     6: aLFC
%     7: ecLFC
%     8: ccLFC
%     9: icLFC
%     10: pLFC
%     11: aMTC
%     12: eMTC
%     13: pMTC
%     14: iMTC
%     15: cMTC
%     16: aLTC
%     17: eLTC
%     18: pLTC
%     19: iLTC
%     20: cLTC
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 06-Jul-2023
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ==============================================================================

clear;
clc;


% =============================================================
% modify this part only
% =============================================================
% input: template segmentation mask with the following labels
%        - 1: Femur
%        - 2: Femoral Cartilage (FC)
%        - 3: Tibia
%        - 4: Medial Tibial Cartilage (mTC)
%        - 5: Lateral Tibial Cartilage (lTC)
% file_segmentation = 'path/to/template/segmentation/CLAIR-Knee-103R_segmentation_64x128x128.nii.gz';
% 
% % output: atlas
% file_atlas = 'path/to/atlas/CLAIR-Knee-103R_atlas_64x128x128.nii.gz';
% =============================================================


% knee side
kneeSide = 'right';
% the paramter for definition of ccLFC & ccMFC
cc_percentage = 0.6;

% read segmentation mask
seg_info = niftiinfo(file_segmentation);
seg_data = niftiread(seg_info);
size_voxel = seg_info.PixelDimensions;
size_img = seg_info.ImageSize;

% atlas (FC)
mask_FC = uint8(seg_data==2);
atlas_FC = CM_cal_VolumeParcellation_FC(mask_FC, kneeSide, cc_percentage, size_img);
% atlas (TC)
mask_mTC = uint8(seg_data==4);
mask_lTC = uint8(seg_data==5);
atlas_TC = CM_cal_VolumeParcellation_TC(mask_mTC, mask_lTC, kneeSide, size_voxel, size_img);
% combine FC and TC atlas
atlas = atlas_FC + atlas_TC;

% remove file extension
[folder, tmp_fileName, tmp_ext] = fileparts(file_atlas);
if strcmp(tmp_ext, ".gz")
    [~, fileName_woExt, ~] = fileparts(tmp_fileName);
else
    fileName_woExt = tmp_fileName;
end
file_atlas_woExt = fullfile(folder, fileName_woExt);

% save atlas
atlas_info = seg_info;
atlas_info.Filemoddate = datetime;
atlas_info.Filename = file_atlas_woExt;
atlas_info.Datatype = class(atlas);
atlas_info.Description = 'atlas for the CLAIR-Knee-103R template';
atlas_info.Filesize = [];
niftiwrite(atlas, atlas_info.Filename, atlas_info, 'Compressed',true);
