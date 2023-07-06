function atlas = CM_cal_VolumeParcellation_FC(mask_FC, kneeSide, cc_percentage, size_img)
% ==============================================================================
% FUNCTION:
%     Femoral cartilage parcellation for knee template.
%
% INPUT:
%     - mask_FC: segmentation mask of FC
%     - kneeSide: knee side, must be one of {"left", "right"}
%     - cc_percentage: the paramter for definition of ccLFC & ccMFC
%     - size_img: image size
%
% OUTPUT:
%     - atlas: the atlas of FC
%
% ROI code in the atlas:
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
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 23-Jun-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================


% voxel subscripts
[sub1_FC, sub2_FC, sub3_FC] = ind2sub(size_img, find(mask_FC));
subs_FC = [sub1_FC, sub2_FC, sub3_FC];


% ---------------------------------------------------------
% Locate the intercondylar notch
% ---------------------------------------------------------
% (assuming the second dimension of image array is the P-A direction, i.e., y+ points to A)
% sagittal slice indices
subsLR_FC = sort(unique(subs_FC(:,1)), 'ascend');
numSag = length(subsLR_FC);
% extract some (50%) center slices
subsLR_FC_center = subsLR_FC(round(numSag * 0.25):round(numSag * 0.75));
minSubAP_FC_center = zeros(length(subsLR_FC_center), 1);
for i = 1:length(subsLR_FC_center)
    i_subLR_FC_center = subsLR_FC_center(i);
    minSubAP_FC_center(i,1) = min(subs_FC(subs_FC(:,1)==i_subLR_FC_center, 2));
end
subNotchAP_FC_center = max(minSubAP_FC_center);
candidate = sort(find(minSubAP_FC_center==subNotchAP_FC_center));
idx = candidate(ceil(length(candidate)/2));
subNotchLR_FC = subsLR_FC_center(idx);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the central lateral FC (cLFC)
% ---------------------------------------------------------
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
subs_LFC = subs_FC(subs_FC(:,1)>=subNotchLR_FC, :);
minSubAP_LFC = min(subs_LFC(:,2));
minSubAP_cLFC = subNotchAP_FC_center - round((subNotchAP_FC_center - minSubAP_LFC) * cc_percentage);
idxAP_cLFC = subs_LFC(:,2)<subNotchAP_FC_center & subs_LFC(:,2)>minSubAP_cLFC;
subs_cLFC = subs_LFC(idxAP_cLFC, :);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the central medial FC (cMFC)
% ---------------------------------------------------------
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
subs_MFC = subs_FC(subs_FC(:,1)<subNotchLR_FC, :);
minSubAP_MFC = min(subs_MFC(:,2));
minSubAP_cMFC = subNotchAP_FC_center - round((subNotchAP_FC_center - minSubAP_MFC) * cc_percentage);
idxAP_cMFC = subs_MFC(:,2)<subNotchAP_FC_center & subs_MFC(:,2)>minSubAP_cMFC;
subs_cMFC = subs_MFC(idxAP_cMFC, :);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aLFC, pLFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ---------------------------------------------------------
% aLFC
maxSubAP_LFC = max(subs_LFC(:,2));
idx_aLFC = subs_LFC(:,2)<=maxSubAP_LFC & subs_LFC(:,2)>=subNotchAP_FC_center;
subs_aLFC = subs_LFC(idx_aLFC, :);

% pLFC
idx_pLFC = subs_LFC(:,2)<=minSubAP_cLFC & subs_LFC(:,2)>=minSubAP_LFC;
subs_pLFC = subs_LFC(idx_pLFC, :);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aMFC, pMFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ---------------------------------------------------------
% aMFC
maxSubAP_MFC = max(subs_MFC(:,2));
idx_aMFC = subs_MFC(:,2)<=maxSubAP_MFC & subs_MFC(:,2)>=subNotchAP_FC_center;
subs_aMFC = subs_MFC(idx_aMFC, :);

% pMFC
idx_pMFC = subs_MFC(:,2)<=minSubAP_cMFC & subs_MFC(:,2)>=minSubAP_MFC;
subs_pMFC = subs_MFC(idx_pMFC, :);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the ecLFC, ccLFC, and icLFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ecLFC: exterior part of cLFC
% ccLFC: central part of cLFC
% icLFC: interior part of cLFC
% ---------------------------------------------------------
subsAP_cLFC = unique(subs_cLFC(:,2));
subs_ecLFC = [];
subs_ccLFC = [];
subs_icLFC = [];
for i = 1:length(subsAP_cLFC)
    i_subAP_cLFC = subsAP_cLFC(i);
    i_subs_cLFC = subs_cLFC(subs_cLFC(:,2)==i_subAP_cLFC, :);
    i_maxSubLR_cLFC = max(i_subs_cLFC(:,1));
    i_minSubLR_cLFC = min(i_subs_cLFC(:,1));
    i_cutSubLR_cLFC_f1 = i_minSubLR_cLFC + (i_maxSubLR_cLFC - i_minSubLR_cLFC) * 1/3;
    i_cutSubLR_cLFC_f2 = i_minSubLR_cLFC + (i_maxSubLR_cLFC - i_minSubLR_cLFC) * 2/3;
    i_idx_ecLFC = i_subs_cLFC(:,1)<=i_maxSubLR_cLFC & i_subs_cLFC(:,1)>i_cutSubLR_cLFC_f2;
    i_idx_ccLFC = i_subs_cLFC(:,1)<=i_cutSubLR_cLFC_f2 & i_subs_cLFC(:,1)>=i_cutSubLR_cLFC_f1;
    i_idx_icLFC = i_subs_cLFC(:,1)<i_cutSubLR_cLFC_f1 & i_subs_cLFC(:,1)>=i_minSubLR_cLFC;
    i_subs_ecLFC = i_subs_cLFC(i_idx_ecLFC, :);
    i_subs_ccLFC = i_subs_cLFC(i_idx_ccLFC, :);
    i_subs_icLFC = i_subs_cLFC(i_idx_icLFC, :);
    subs_ecLFC = cat(1, subs_ecLFC, i_subs_ecLFC);
    subs_ccLFC = cat(1, subs_ccLFC, i_subs_ccLFC);
    subs_icLFC = cat(1, subs_icLFC, i_subs_icLFC);
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the ecMFC, ccMFC, and icMFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ecMFC: exterior part of cMFC
% ccMFC: central part of cMFC
% icMFC: interior part of cMFC
% ---------------------------------------------------------
subsAP_cMFC = unique(subs_cMFC(:,2));
subs_ecMFC = [];
subs_ccMFC = [];
subs_icMFC = [];
for i = 1:length(subsAP_cMFC)
    i_subAP_cMFC = subsAP_cMFC(i);
    i_subs_cMFC = subs_cMFC(subs_cMFC(:,2)==i_subAP_cMFC, :);
    i_maxSubLR_cMFC = max(i_subs_cMFC(:,1));
    i_minSubLR_cMFC = min(i_subs_cMFC(:,1));
    i_cutSubLR_cMFC_f1 = i_minSubLR_cMFC + (i_maxSubLR_cMFC - i_minSubLR_cMFC) * 1/3;
    i_cutSubLR_cMFC_f2 = i_minSubLR_cMFC + (i_maxSubLR_cMFC - i_minSubLR_cMFC) * 2/3;
    i_idx_icMFC = i_subs_cMFC(:,1)<=i_maxSubLR_cMFC & i_subs_cMFC(:,1)>i_cutSubLR_cMFC_f2;
    i_idx_ccMFC = i_subs_cMFC(:,1)<=i_cutSubLR_cMFC_f2 & i_subs_cMFC(:,1)>=i_cutSubLR_cMFC_f1;
    i_idx_ecMFC = i_subs_cMFC(:,1)<i_cutSubLR_cMFC_f1 & i_subs_cMFC(:,1)>=i_minSubLR_cMFC;
    i_subs_icMFC = i_subs_cMFC(i_idx_icMFC, :);
    i_subs_ccMFC = i_subs_cMFC(i_idx_ccMFC, :);
    i_subs_ecMFC = i_subs_cMFC(i_idx_ecMFC, :);
    subs_icMFC = cat(1, subs_icMFC, i_subs_icMFC);
    subs_ccMFC = cat(1, subs_ccMFC, i_subs_ccMFC);
    subs_ecMFC = cat(1, subs_ecMFC, i_subs_ecMFC);
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% Combine results
switch kneeSide
    case "right"
        subsSubReg_FC.aLFC = subs_aLFC;
        subsSubReg_FC.pLFC = subs_pLFC;
        subsSubReg_FC.ecLFC = subs_ecLFC;
        subsSubReg_FC.ccLFC = subs_ccLFC;
        subsSubReg_FC.icLFC = subs_icLFC;
        subsSubReg_FC.aMFC = subs_aMFC;
        subsSubReg_FC.pMFC = subs_pMFC;
        subsSubReg_FC.ecMFC = subs_ecMFC;
        subsSubReg_FC.ccMFC = subs_ccMFC;
        subsSubReg_FC.icMFC = subs_icMFC;
    case "left"
        subsSubReg_FC.aLFC = subs_aMFC;
        subsSubReg_FC.pLFC = subs_pMFC;
        subsSubReg_FC.ecLFC = subs_ecMFC;
        subsSubReg_FC.ccLFC = subs_ccMFC;
        subsSubReg_FC.icLFC = subs_icMFC;
        subsSubReg_FC.aMFC = subs_aLFC;
        subsSubReg_FC.pMFC = subs_pLFC;
        subsSubReg_FC.ecMFC = subs_ecLFC;
        subsSubReg_FC.ccMFC = subs_ccLFC;
        subsSubReg_FC.icMFC = subs_icLFC;
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% create atlas
atlas = zeros(size_img, 'uint8');
idx_aMFC = sub2ind(size_img, subsSubReg_FC.aMFC(:,1), subsSubReg_FC.aMFC(:,2), subsSubReg_FC.aMFC(:,3));
idx_ecMFC = sub2ind(size_img, subsSubReg_FC.ecMFC(:,1), subsSubReg_FC.ecMFC(:,2), subsSubReg_FC.ecMFC(:,3));
idx_ccMFC = sub2ind(size_img, subsSubReg_FC.ccMFC(:,1), subsSubReg_FC.ccMFC(:,2), subsSubReg_FC.ccMFC(:,3));
idx_icMFC = sub2ind(size_img, subsSubReg_FC.icMFC(:,1), subsSubReg_FC.icMFC(:,2), subsSubReg_FC.icMFC(:,3));
idx_pMFC = sub2ind(size_img, subsSubReg_FC.pMFC(:,1), subsSubReg_FC.pMFC(:,2), subsSubReg_FC.pMFC(:,3));
idx_aLFC = sub2ind(size_img, subsSubReg_FC.aLFC(:,1), subsSubReg_FC.aLFC(:,2), subsSubReg_FC.aLFC(:,3));
idx_ecLFC = sub2ind(size_img, subsSubReg_FC.ecLFC(:,1), subsSubReg_FC.ecLFC(:,2), subsSubReg_FC.ecLFC(:,3));
idx_ccLFC = sub2ind(size_img, subsSubReg_FC.ccLFC(:,1), subsSubReg_FC.ccLFC(:,2), subsSubReg_FC.ccLFC(:,3));
idx_icLFC = sub2ind(size_img, subsSubReg_FC.icLFC(:,1), subsSubReg_FC.icLFC(:,2), subsSubReg_FC.icLFC(:,3));
idx_pLFC = sub2ind(size_img, subsSubReg_FC.pLFC(:,1), subsSubReg_FC.pLFC(:,2), subsSubReg_FC.pLFC(:,3));
atlas(idx_aMFC) = 1;
atlas(idx_ecMFC) = 2;
atlas(idx_ccMFC) = 3;
atlas(idx_icMFC) = 4;
atlas(idx_pMFC) = 5;
atlas(idx_aLFC) = 6;
atlas(idx_ecLFC) = 7;
atlas(idx_ccLFC) = 8;
atlas(idx_icLFC) = 9;
atlas(idx_pLFC) = 10;
% ---------------------------------------------------------

end