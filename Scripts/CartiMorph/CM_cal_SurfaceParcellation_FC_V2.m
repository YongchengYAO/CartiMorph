function [versSubReg_iC_FC, versSubReg_scB_FC, meshSubReg_iC_FC, meshSubReg_scB_FC] ...
    = CM_cal_SurfaceParcellation_FC_V2(...
    mesh_iC_FC, ...
    mesh_scB_FC, ...
    size_voxel, ...
    knee_side, ...
    cc_percentage, ...
    estPA)
% ==============================================================================
% FUNCTION:
%     Cartilage parcellation of FC.
%
% INPUT:
%     - mesh_iC_FC: interior cartilage surface for FC
%     - mesh_scB_FC: subchondral bone surface for FC
%     - size_voxel: voxel size
%     - knee_side: knee side, must be one of {"left", "right"}
%     - cc_percentage: [double], the paramter for definition of ccLFC & ccMFC
%     - estPA: [double], the estimated posterior-to-anterior direction
%              (this is the output of the function "cal_SurfaceParcellation_TC_V2")
%
% OUTPUT:
%     - versSubReg_iC_FC: [structure], vertices on the interior cartilage surface of FC
%     - versSubReg_scB_FC: [structure], vertices on the subchondral bone surface of FC
%     - meshSubReg_iC_FC: [structure], the interior cartilage surface of FC
%     - meshSubReg_scB_FC: [structure], the subchondral bone surface of FC
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 12-Jul-2023
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================


%% Orientation Correction
% ---------------------------------------------------------
% the estimated P-A direction should be the 2nd axis of the new coordinate system
% ---------------------------------------------------------
% interior cartilage surface of FC (original coordinate system)
faces_iC_FC = mesh_iC_FC.faces;
vers_iC_FC = mesh_iC_FC.vertices;

% the subchondral bone surface of FC (original coordinate system)
faces_scB_FC = mesh_scB_FC.faces;
vers_scB_FC = mesh_scB_FC.vertices;

% determine transformation matrix
vecDim3 = [0,0,1]; % assuming RAS+ orientation
vecPA = [estPA(1), estPA(2), 0];
vecPA = vecPA ./ norm(vecPA);
vecLR = cross(vecDim3, vecPA) ./ norm(cross(vecDim3, vecPA));
transMat(:, 1) = vecLR;
transMat(:, 2) = vecPA;
transMat(:, 3) = vecDim3;

% change of coordinate system
vers_iC_FC_t = transpose(transMat \ vers_iC_FC');
subs_iC_FC_t = round(vers_iC_FC_t ./ size_voxel);

vers_scB_FC_t = transpose(transMat \ vers_scB_FC');
subs_scB_FC_t = round(vers_scB_FC_t ./ size_voxel);
% ---------------------------------------------------------



%% Parcellate subchondral bone area of FC
% ---------------------------------------------------------
% Locate the intercondylar notch
% ---------------------------------------------------------
% (assuming the second dimension of image array is the P-A direction, i.e., y+ points to A)
% sagittal slice indices
subsLR_scB_FC_t = sort(unique(subs_scB_FC_t(:,1)), 'ascend');
numSag_t = length(subsLR_scB_FC_t);
% extract some (50%) center slices
subsLR_scB_FC_center_t = subsLR_scB_FC_t(round(numSag_t * 0.25):round(numSag_t * 0.75));
minSubAP_scB_FC_center_t = zeros(length(subsLR_scB_FC_center_t), 1);
for i = 1:length(subsLR_scB_FC_center_t)
    i_subLR_scB_FC_center_t = subsLR_scB_FC_center_t(i);
    minSubAP_scB_FC_center_t(i,1) = min(subs_scB_FC_t(subs_scB_FC_t(:,1)==i_subLR_scB_FC_center_t, 2));
end
subNotchAP_scB_FC_center_t = max(minSubAP_scB_FC_center_t);
candidate_t = sort(find(minSubAP_scB_FC_center_t==subNotchAP_scB_FC_center_t));
idx_t = candidate_t(ceil(length(candidate_t)/2));
subNotchLR_scB_FC_t = subsLR_scB_FC_center_t(idx_t);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the central lateral FC (cLFC)
% ---------------------------------------------------------
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
subs_scB_LFC_t = subs_scB_FC_t(subs_scB_FC_t(:,1)>=subNotchLR_scB_FC_t, :);
minSubAP_scB_LFC_t = min(subs_scB_LFC_t(:,2));
minSubAP_scB_cLFC_t = subNotchAP_scB_FC_center_t - round((subNotchAP_scB_FC_center_t - minSubAP_scB_LFC_t) * cc_percentage);
idxAP_scB_cLFC_t = subs_scB_LFC_t(:,2)<subNotchAP_scB_FC_center_t & subs_scB_LFC_t(:,2)>minSubAP_scB_cLFC_t;
subs_scB_cLFC_t = subs_scB_LFC_t(idxAP_scB_cLFC_t, :);

% extract faces
faces_scB_cLFC_t = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_cLFC_t);

% remove small components (MeshProcessingToolbox)
[~, components_scB_cLFC] = CartiMorphToolbox.segment_connected_components(faces_scB_cLFC_t, 'explicit');
faces_scB_cLFC_t = CartiMorphToolbox.cal_deleteSmallComponents(components_scB_cLFC, 50);
[vers_scB_cLFC_t, ~] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_cLFC_t);
subs_scB_cLFC_t = round(vers_scB_cLFC_t ./ size_voxel);

subs_partial_scB_pLFC_t = [];
subs_partial_scB_aLFC_t = [];
faces_smallCC_scB_LFC_t = CartiMorphToolbox.cal_deleteLargeComponents(components_scB_cLFC, 50);
if ~isempty(faces_smallCC_scB_LFC_t)
    [~, components_smallCC_scB_LFC] = CartiMorphToolbox.segment_connected_components(faces_smallCC_scB_LFC_t, 'explicit');
    for ii = 1:size(components_smallCC_scB_LFC,1)
        faces_smallCC_scB_LFC_t = cell2mat(components_smallCC_scB_LFC(ii, 1));
        [vers_smallCC_scB_LFC_t, ~] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_smallCC_scB_LFC_t);
        subs_centerSI_smallCC_scB_LFC_t = round(mean(vers_smallCC_scB_LFC_t(:,3)) ./ size_voxel(3));
        subs_centerAP_smallCC_scB_LFC_t = round(mean(vers_smallCC_scB_LFC_t(:,2)) ./ size_voxel(2));
        subs_centerSI_cLFC_t = round(mean(vers_scB_cLFC_t(:,3)) ./ size_voxel(3));
        subsRange_centerSI_sLFC_t = round((max(vers_scB_cLFC_t(:,3))-min(vers_scB_cLFC_t(:,3))) ./ size_voxel(3));
        if (subs_centerSI_smallCC_scB_LFC_t - subs_centerSI_cLFC_t) > subsRange_centerSI_sLFC_t
            % the small connected component if part of pLFC
            subs_partial_scB_pLFC_t = cat(1, subs_partial_scB_pLFC_t, round(vers_smallCC_scB_LFC_t ./ size_voxel));
        elseif abs(subs_centerAP_smallCC_scB_LFC_t - subNotchAP_scB_FC_center_t) <= 2
            % the small connected component if part of aLFC
            subs_partial_scB_aLFC_t = cat(1, subs_partial_scB_aLFC_t, round(vers_smallCC_scB_LFC_t ./ size_voxel));
        else
            % the small connected component if part of cLFC
            subs_scB_cLFC_t = cat(1, subs_scB_cLFC_t, round(vers_smallCC_scB_LFC_t ./ size_voxel));
        end
    end
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the central medial FC (cMFC)
% ---------------------------------------------------------
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
subs_scB_MFC_t = subs_scB_FC_t(subs_scB_FC_t(:,1)<subNotchLR_scB_FC_t, :);
minSubAP_scB_MFC_t = min(subs_scB_MFC_t(:,2));
minSubAP_scB_cMFC_t = subNotchAP_scB_FC_center_t - round((subNotchAP_scB_FC_center_t - minSubAP_scB_MFC_t) * cc_percentage);
idxAP_scB_cMFC_t = subs_scB_MFC_t(:,2)<subNotchAP_scB_FC_center_t & subs_scB_MFC_t(:,2)>minSubAP_scB_cMFC_t;
subs_scB_cMFC_t = subs_scB_MFC_t(idxAP_scB_cMFC_t, :);

% extract faces
faces_scB_cMFC_t = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_cMFC_t);

% remove small components from the non-interface mesh (MeshProcessingToolbox)
[~, components_scB_cMFC] = CartiMorphToolbox.segment_connected_components(faces_scB_cMFC_t, 'explicit');
faces_scB_cMFC_t = CartiMorphToolbox.cal_deleteSmallComponents(components_scB_cMFC, 50);
[vers_scB_cMFC_t, ~] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_cMFC_t);
subs_scB_cMFC_t = round(vers_scB_cMFC_t ./ size_voxel);

subs_partial_scB_pMFC_t = [];
subs_partial_scB_aMFC_t = [];
faces_smallCC_scB_MFC_t = CartiMorphToolbox.cal_deleteLargeComponents(components_scB_cMFC, 50);
if ~isempty(faces_smallCC_scB_MFC_t)
    [~, components_smallCC_scB_MFC] = CartiMorphToolbox.segment_connected_components(faces_smallCC_scB_MFC_t, 'explicit');
    for ii = 1:size(components_smallCC_scB_MFC,1)
        faces_smallCC_scB_MFC_t = cell2mat(components_smallCC_scB_MFC(ii, 1));
        [vers_smallCC_scB_MFC_t, ~] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_smallCC_scB_MFC_t);
        subs_centerSI_smallCC_scB_MFC_t = round(mean(vers_smallCC_scB_MFC_t(:,3)) ./ size_voxel(3));
        subs_centerAP_smallCC_scB_MFC_t = round(mean(vers_smallCC_scB_MFC_t(:,2)) ./ size_voxel(2));
        subs_centerSI_cMFC_t = round(mean(vers_scB_cMFC_t(:,3)) ./ size_voxel(3));
        subsRange_centerSI_sMFC_t = round((max(vers_scB_cMFC_t(:,3))-min(vers_scB_cMFC_t(:,3))) ./ size_voxel(3));
        if (subs_centerSI_smallCC_scB_MFC_t - subs_centerSI_cMFC_t) > subsRange_centerSI_sMFC_t
            % the small connected component if part of pMFC
            subs_partial_scB_pMFC_t = cat(1, subs_partial_scB_pMFC_t, round(vers_smallCC_scB_MFC_t ./ size_voxel));
        elseif abs(subs_centerAP_smallCC_scB_MFC_t - subNotchAP_scB_FC_center_t) <= 2
            % the small connected component if part of aMFC
            subs_partial_scB_aMFC_t = cat(1, subs_partial_scB_aMFC_t, round(vers_smallCC_scB_MFC_t ./ size_voxel));
        else
            % the small connected component if part of cMFC
            subs_scB_cMFC_t = cat(1, subs_scB_cMFC_t, round(vers_smallCC_scB_MFC_t ./ size_voxel));
        end
    end
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aLFC, pLFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ---------------------------------------------------------
% aLFC
maxSubAP_scB_LFC_t = max(subs_scB_LFC_t(:,2));
idx_scB_aLFC_t = subs_scB_LFC_t(:,2)<=maxSubAP_scB_LFC_t & subs_scB_LFC_t(:,2)>=subNotchAP_scB_FC_center_t;
subs_scB_aLFC_t = subs_scB_LFC_t(idx_scB_aLFC_t, :);
if exist("subs_partial_scB_aLFC", 'var')
    subs_scB_aLFC_t = cat(1, subs_scB_aLFC_t, subs_partial_scB_aLFC_t);
end
vers_scB_aLFC_t = subs_scB_aLFC_t .* size_voxel;

% pLFC
idx_scB_pLFC_t = subs_scB_LFC_t(:,2)<=minSubAP_scB_cLFC_t & subs_scB_LFC_t(:,2)>=minSubAP_scB_LFC_t;
subs_scB_pLFC_t = subs_scB_LFC_t(idx_scB_pLFC_t, :);
if exist("subs_partial_scB_pLFC", 'var')
    subs_scB_pLFC_t = cat(1, subs_scB_pLFC_t, subs_partial_scB_pLFC_t);
end
vers_scB_pLFC_t = subs_scB_pLFC_t .* size_voxel;
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aMFC, pMFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ---------------------------------------------------------
% aMFC
maxSubAP_scB_MFC_t = max(subs_scB_MFC_t(:,2));
idx_scB_aMFC_t = subs_scB_MFC_t(:,2)<=maxSubAP_scB_MFC_t & subs_scB_MFC_t(:,2)>=subNotchAP_scB_FC_center_t;
subs_scB_aMFC_t = subs_scB_MFC_t(idx_scB_aMFC_t, :);
if exist("subs_partial_scB_aMFC", 'var')
    subs_scB_aMFC_t = cat(1, subs_scB_aMFC_t, subs_partial_scB_aMFC_t);
end
vers_scB_aMFC_t = subs_scB_aMFC_t .* size_voxel;

% pMFC
idx_scB_pMFC_t = subs_scB_MFC_t(:,2)<=minSubAP_scB_cMFC_t & subs_scB_MFC_t(:,2)>=minSubAP_scB_MFC_t;
subs_scB_pMFC_t = subs_scB_MFC_t(idx_scB_pMFC_t, :);
if exist("subs_partial_scB_pMFC", 'var')
    subs_scB_pMFC_t = cat(1, subs_scB_pMFC_t, subs_partial_scB_pMFC_t);
end
vers_scB_pMFC_t = subs_scB_pMFC_t .* size_voxel;
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the ecLFC, ccLFC, and icLFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ecLFC: exterior part of cLFC
% ccLFC: central part of cLFC
% icLFC: interior part of cLFC
% ---------------------------------------------------------
subsAP_scB_cLFC_t = unique(subs_scB_cLFC_t(:,2));
subs_scB_ecLFC_t = [];
subs_scB_ccLFC_t = [];
subs_scB_icLFC_t = [];
for i = 1:length(subsAP_scB_cLFC_t)
    i_subAP_scB_cLFC_t = subsAP_scB_cLFC_t(i);
    i_subs_scB_cLFC_t = subs_scB_cLFC_t(subs_scB_cLFC_t(:,2)==i_subAP_scB_cLFC_t, :);
    i_maxSubLR_scB_cLFC_t = max(i_subs_scB_cLFC_t(:,1));
    i_minSubLR_scB_cLFC_t = min(i_subs_scB_cLFC_t(:,1));
    i_cutSubLR_scB_cLFC_f1_t = i_minSubLR_scB_cLFC_t + (i_maxSubLR_scB_cLFC_t - i_minSubLR_scB_cLFC_t) * 1/3;
    i_cutSubLR_scB_cLFC_f2_t = i_minSubLR_scB_cLFC_t + (i_maxSubLR_scB_cLFC_t - i_minSubLR_scB_cLFC_t) * 2/3;
    i_idx_scB_ecLFC_t = i_subs_scB_cLFC_t(:,1)<=i_maxSubLR_scB_cLFC_t & i_subs_scB_cLFC_t(:,1)>i_cutSubLR_scB_cLFC_f2_t;
    i_idx_scB_ccLFC_t = i_subs_scB_cLFC_t(:,1)<=i_cutSubLR_scB_cLFC_f2_t & i_subs_scB_cLFC_t(:,1)>=i_cutSubLR_scB_cLFC_f1_t;
    i_idx_scB_icLFC_t = i_subs_scB_cLFC_t(:,1)<i_cutSubLR_scB_cLFC_f1_t & i_subs_scB_cLFC_t(:,1)>=i_minSubLR_scB_cLFC_t;
    i_subs_scB_ecLFC_t = i_subs_scB_cLFC_t(i_idx_scB_ecLFC_t, :);
    i_subs_scB_ccLFC_t = i_subs_scB_cLFC_t(i_idx_scB_ccLFC_t, :);
    i_subs_scB_icLFC_t = i_subs_scB_cLFC_t(i_idx_scB_icLFC_t, :);
    subs_scB_ecLFC_t = cat(1, subs_scB_ecLFC_t, i_subs_scB_ecLFC_t);
    subs_scB_ccLFC_t = cat(1, subs_scB_ccLFC_t, i_subs_scB_ccLFC_t);
    subs_scB_icLFC_t = cat(1, subs_scB_icLFC_t, i_subs_scB_icLFC_t);
end
vers_scB_ecLFC_t = subs_scB_ecLFC_t .* size_voxel;
vers_scB_ccLFC_t = subs_scB_ccLFC_t .* size_voxel;
vers_scB_icLFC_t = subs_scB_icLFC_t .* size_voxel;
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the ecMFC, ccMFC, and icMFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ecMFC: exterior part of cMFC
% ccMFC: central part of cMFC
% icMFC: interior part of cMFC
% ---------------------------------------------------------
subsAP_scB_cMFC_t = unique(subs_scB_cMFC_t(:,2));
subs_scB_ecMFC_t = [];
subs_scB_ccMFC_t = [];
subs_scB_icMFC_t = [];
for i = 1:length(subsAP_scB_cMFC_t)
    i_subAP_scB_cMFC_t = subsAP_scB_cMFC_t(i);
    i_subs_scB_cMFC_t = subs_scB_cMFC_t(subs_scB_cMFC_t(:,2)==i_subAP_scB_cMFC_t, :);
    i_maxSubLR_scB_cMFC_t = max(i_subs_scB_cMFC_t(:,1));
    i_minSubLR_scB_cMFC_t = min(i_subs_scB_cMFC_t(:,1));
    i_cutSubLR_scB_cMFC_f1_t = i_minSubLR_scB_cMFC_t + (i_maxSubLR_scB_cMFC_t - i_minSubLR_scB_cMFC_t) * 1/3;
    i_cutSubLR_scB_cMFC_f2_t = i_minSubLR_scB_cMFC_t + (i_maxSubLR_scB_cMFC_t - i_minSubLR_scB_cMFC_t) * 2/3;
    i_idx_scB_icMFC_t = i_subs_scB_cMFC_t(:,1)<=i_maxSubLR_scB_cMFC_t & i_subs_scB_cMFC_t(:,1)>i_cutSubLR_scB_cMFC_f2_t;
    i_idx_scB_ccMFC_t = i_subs_scB_cMFC_t(:,1)<=i_cutSubLR_scB_cMFC_f2_t & i_subs_scB_cMFC_t(:,1)>=i_cutSubLR_scB_cMFC_f1_t;
    i_idx_scB_ecMFC_t = i_subs_scB_cMFC_t(:,1)<i_cutSubLR_scB_cMFC_f1_t & i_subs_scB_cMFC_t(:,1)>=i_minSubLR_scB_cMFC_t;
    i_subs_scB_icMFC_t = i_subs_scB_cMFC_t(i_idx_scB_icMFC_t, :);
    i_subs_scB_ccMFC_t = i_subs_scB_cMFC_t(i_idx_scB_ccMFC_t, :);
    i_subs_scB_ecMFC_t = i_subs_scB_cMFC_t(i_idx_scB_ecMFC_t, :);
    subs_scB_icMFC_t = cat(1, subs_scB_icMFC_t, i_subs_scB_icMFC_t);
    subs_scB_ccMFC_t = cat(1, subs_scB_ccMFC_t, i_subs_scB_ccMFC_t);
    subs_scB_ecMFC_t = cat(1, subs_scB_ecMFC_t, i_subs_scB_ecMFC_t);
end
vers_scB_ecMFC_t = subs_scB_ecMFC_t .* size_voxel;
vers_scB_ccMFC_t = subs_scB_ccMFC_t .* size_voxel;
vers_scB_icMFC_t = subs_scB_icMFC_t .* size_voxel;
% ---------------------------------------------------------



%% Parcellate FC
vers_iC_aLFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_aLFC_t, 'rows'), :);
vers_iC_pLFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_pLFC_t, 'rows'), :);
vers_iC_ecLFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_ecLFC_t, 'rows'), :);
vers_iC_ccLFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_ccLFC_t, 'rows'), :);
vers_iC_icLFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_icLFC_t, 'rows'), :);
vers_iC_aMFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_aMFC_t, 'rows'), :);
vers_iC_pMFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_pMFC_t, 'rows'), :);
vers_iC_ecMFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_ecMFC_t, 'rows'), :);
vers_iC_ccMFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_ccMFC_t, 'rows'), :);
vers_iC_icMFC_t = vers_iC_FC_t(ismember(subs_iC_FC_t, subs_scB_icMFC_t, 'rows'), :);
subs_iC_aLFC_t = round(vers_iC_aLFC_t ./ size_voxel);
subs_iC_pLFC_t = round(vers_iC_pLFC_t ./ size_voxel);
subs_iC_ecLFC_t = round(vers_iC_ecLFC_t ./ size_voxel);
subs_iC_ccLFC_t = round(vers_iC_ccLFC_t ./ size_voxel);
subs_iC_icLFC_t = round(vers_iC_icLFC_t ./ size_voxel);
subs_iC_aMFC_t = round(vers_iC_aMFC_t ./ size_voxel);
subs_iC_pMFC_t = round(vers_iC_pMFC_t ./ size_voxel);
subs_iC_ecMFC_t = round(vers_iC_ecMFC_t ./ size_voxel);
subs_iC_ccMFC_t = round(vers_iC_ccMFC_t ./ size_voxel);
subs_iC_icMFC_t = round(vers_iC_icMFC_t ./ size_voxel);



%% Extract faces of each subregion
% FC with recovered full-thickness cartilage loss
faces_scB_aLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_aLFC_t);
[Mesh_scB_aLFC.vertices, Mesh_scB_aLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_aLFC);
faces_scB_pLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_pLFC_t);
[Mesh_scB_pLFC.vertices, Mesh_scB_pLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_pLFC);
faces_scB_ecLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_ecLFC_t);
[Mesh_scB_ecLFC.vertices, Mesh_scB_ecLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_ecLFC);
faces_scB_ccLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_ccLFC_t);
[Mesh_scB_ccLFC.vertices, Mesh_scB_ccLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_ccLFC);
faces_scB_icLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_icLFC_t);
[Mesh_scB_icLFC.vertices, Mesh_scB_icLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_icLFC);
faces_scB_aMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_aMFC_t);
[Mesh_scB_aMFC.vertices, Mesh_scB_aMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_aMFC);
faces_scB_pMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_pMFC_t);
[Mesh_scB_pMFC.vertices, Mesh_scB_pMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_pMFC);
faces_scB_ecMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_ecMFC_t);
[Mesh_scB_ecMFC.vertices, Mesh_scB_ecMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_ecMFC);
faces_scB_ccMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_ccMFC_t);
[Mesh_scB_ccMFC.vertices, Mesh_scB_ccMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_ccMFC);
faces_scB_icMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_scB_FC, subs_scB_FC_t, subs_scB_icMFC_t);
[Mesh_scB_icMFC.vertices, Mesh_scB_icMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_scB_FC_t, faces_scB_icMFC);

% original FC
if ~isempty(subs_iC_aLFC_t)
    faces_iC_aLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_aLFC_t);
    [Mesh_iC_aLFC.vertices, Mesh_iC_aLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_aLFC);
else
    Mesh_iC_aLFC = [];
end

if ~isempty(subs_iC_pLFC_t)
    faces_iC_pLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_pLFC_t);
    [Mesh_iC_pLFC.vertices, Mesh_iC_pLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_pLFC);
else
    Mesh_iC_pLFC = [];
end

if ~isempty(subs_iC_ecLFC_t)
    faces_iC_ecLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_ecLFC_t);
    [Mesh_iC_ecLFC.vertices, Mesh_iC_ecLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_ecLFC);
else
    Mesh_iC_ecLFC = [];
end

if ~isempty(subs_iC_ccLFC_t)
    faces_iC_ccLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_ccLFC_t);
    [Mesh_iC_ccLFC.vertices, Mesh_iC_ccLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_ccLFC);
else
    Mesh_iC_ccLFC = [];
end

if ~isempty(subs_iC_icLFC_t)
    faces_iC_icLFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_icLFC_t);
    [Mesh_iC_icLFC.vertices, Mesh_iC_icLFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_icLFC);
else
    Mesh_iC_icLFC = [];
end

if ~isempty(subs_iC_aMFC_t)
    faces_iC_aMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_aMFC_t);
    [Mesh_iC_aMFC.vertices, Mesh_iC_aMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_aMFC);
else
    Mesh_iC_aMFC = [];
end

if ~isempty(subs_iC_pMFC_t)
    faces_iC_pMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_pMFC_t);
    [Mesh_iC_pMFC.vertices, Mesh_iC_pMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_pMFC);
else
    Mesh_iC_pMFC = [];
end

if ~isempty(subs_iC_ecMFC_t)
    faces_iC_ecMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_ecMFC_t);
    [Mesh_iC_ecMFC.vertices, Mesh_iC_ecMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_ecMFC);
else
    Mesh_iC_ecMFC = [];
end

if ~isempty(subs_iC_ccMFC_t)
    faces_iC_ccMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_ccMFC_t);
    [Mesh_iC_ccMFC.vertices, Mesh_iC_ccMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_ccMFC);
else
    Mesh_iC_ccMFC = [];
end

if ~isempty(subs_iC_icMFC_t)
    faces_iC_icMFC = CartiMorphToolbox.cal_extractFaces_OR(faces_iC_FC, subs_iC_FC_t, subs_iC_icMFC_t);
    [Mesh_iC_icMFC.vertices, Mesh_iC_icMFC.faces] = CartiMorphToolbox.remove_unreferenced_vertices(vers_iC_FC_t, faces_iC_icMFC);
else
    Mesh_iC_icMFC = [];
end


%% Change of coordinate system (back to the original image space)
vers_scB_aLFC = transpose(transMat * vers_scB_aLFC_t');
vers_scB_pLFC = transpose(transMat * vers_scB_pLFC_t');
vers_scB_ecLFC = transpose(transMat * vers_scB_ecLFC_t');
vers_scB_ccLFC = transpose(transMat * vers_scB_ccLFC_t');
vers_scB_icLFC = transpose(transMat * vers_scB_icLFC_t');
vers_scB_aMFC = transpose(transMat * vers_scB_aMFC_t');
vers_scB_pMFC = transpose(transMat * vers_scB_pMFC_t');
vers_scB_ecMFC = transpose(transMat * vers_scB_ecMFC_t');
vers_scB_ccMFC = transpose(transMat * vers_scB_ccMFC_t');
vers_scB_icMFC = transpose(transMat * vers_scB_icMFC_t');

Mesh_scB_aLFC.vertices = transpose(transMat * Mesh_scB_aLFC.vertices');
Mesh_scB_pLFC.vertices = transpose(transMat * Mesh_scB_pLFC.vertices');
Mesh_scB_ecLFC.vertices = transpose(transMat * Mesh_scB_ecLFC.vertices');
Mesh_scB_ccLFC.vertices = transpose(transMat * Mesh_scB_ccLFC.vertices');
Mesh_scB_icLFC.vertices = transpose(transMat * Mesh_scB_icLFC.vertices');
Mesh_scB_aMFC.vertices = transpose(transMat * Mesh_scB_aMFC.vertices');
Mesh_scB_pMFC.vertices = transpose(transMat * Mesh_scB_pMFC.vertices');
Mesh_scB_ecMFC.vertices = transpose(transMat * Mesh_scB_ecMFC.vertices');
Mesh_scB_ccMFC.vertices = transpose(transMat * Mesh_scB_ccMFC.vertices');
Mesh_scB_icMFC.vertices = transpose(transMat * Mesh_scB_icMFC.vertices');

vers_iC_aLFC = transpose(transMat * vers_iC_aLFC_t');
vers_iC_pLFC = transpose(transMat * vers_iC_pLFC_t');
vers_iC_ecLFC = transpose(transMat * vers_iC_ecLFC_t');
vers_iC_ccLFC = transpose(transMat * vers_iC_ccLFC_t');
vers_iC_icLFC = transpose(transMat * vers_iC_icLFC_t');
vers_iC_aMFC = transpose(transMat * vers_iC_aMFC_t');
vers_iC_pMFC = transpose(transMat * vers_iC_pMFC_t');
vers_iC_ecMFC = transpose(transMat * vers_iC_ecMFC_t');
vers_iC_ccMFC = transpose(transMat * vers_iC_ccMFC_t');
vers_iC_icMFC = transpose(transMat * vers_iC_icMFC_t');

Mesh_iC_aLFC.vertices = transpose(transMat * Mesh_iC_aLFC.vertices');
Mesh_iC_pLFC.vertices = transpose(transMat * Mesh_iC_pLFC.vertices');
Mesh_iC_ecLFC.vertices = transpose(transMat * Mesh_iC_ecLFC.vertices');
Mesh_iC_ccLFC.vertices = transpose(transMat * Mesh_iC_ccLFC.vertices');
Mesh_iC_icLFC.vertices = transpose(transMat * Mesh_iC_icLFC.vertices');
Mesh_iC_aMFC.vertices = transpose(transMat * Mesh_iC_aMFC.vertices');
Mesh_iC_pMFC.vertices = transpose(transMat * Mesh_iC_pMFC.vertices');
Mesh_iC_ecMFC.vertices = transpose(transMat * Mesh_iC_ecMFC.vertices');
Mesh_iC_ccMFC.vertices = transpose(transMat * Mesh_iC_ccMFC.vertices');
Mesh_iC_icMFC.vertices = transpose(transMat * Mesh_iC_icMFC.vertices');



%% Combine results
switch knee_side
    case "right"
        %% Vertices
        % FC with recovered full-thickness cartilage loss
        versSubReg_scB_FC.aLFC = vers_scB_aLFC;
        versSubReg_scB_FC.pLFC = vers_scB_pLFC;
        versSubReg_scB_FC.ecLFC = vers_scB_ecLFC;
        versSubReg_scB_FC.ccLFC = vers_scB_ccLFC;
        versSubReg_scB_FC.icLFC = vers_scB_icLFC;
        versSubReg_scB_FC.aMFC = vers_scB_aMFC;
        versSubReg_scB_FC.pMFC = vers_scB_pMFC;
        versSubReg_scB_FC.ecMFC = vers_scB_ecMFC;
        versSubReg_scB_FC.ccMFC = vers_scB_ccMFC;
        versSubReg_scB_FC.icMFC = vers_scB_icMFC;
        % original FC
        versSubReg_iC_FC.aLFC = vers_iC_aLFC;
        versSubReg_iC_FC.pLFC = vers_iC_pLFC;
        versSubReg_iC_FC.ecLFC = vers_iC_ecLFC;
        versSubReg_iC_FC.ccLFC = vers_iC_ccLFC;
        versSubReg_iC_FC.icLFC = vers_iC_icLFC;
        versSubReg_iC_FC.aMFC = vers_iC_aMFC;
        versSubReg_iC_FC.pMFC = vers_iC_pMFC;
        versSubReg_iC_FC.ecMFC = vers_iC_ecMFC;
        versSubReg_iC_FC.ccMFC = vers_iC_ccMFC;
        versSubReg_iC_FC.icMFC = vers_iC_icMFC;

        %% Mesh
        % FC with recovered full-thickness cartilage loss
        meshSubReg_scB_FC.aLFC = Mesh_scB_aLFC;
        meshSubReg_scB_FC.pLFC = Mesh_scB_pLFC;
        meshSubReg_scB_FC.ecLFC = Mesh_scB_ecLFC;
        meshSubReg_scB_FC.ccLFC = Mesh_scB_ccLFC;
        meshSubReg_scB_FC.icLFC = Mesh_scB_icLFC;
        meshSubReg_scB_FC.aMFC = Mesh_scB_aMFC;
        meshSubReg_scB_FC.pMFC = Mesh_scB_pMFC;
        meshSubReg_scB_FC.ecMFC = Mesh_scB_ecMFC;
        meshSubReg_scB_FC.ccMFC = Mesh_scB_ccMFC;
        meshSubReg_scB_FC.icMFC = Mesh_scB_icMFC;
        % original FC
        meshSubReg_iC_FC.aLFC = Mesh_iC_aLFC;
        meshSubReg_iC_FC.pLFC = Mesh_iC_pLFC;
        meshSubReg_iC_FC.ecLFC = Mesh_iC_ecLFC;
        meshSubReg_iC_FC.ccLFC = Mesh_iC_ccLFC;
        meshSubReg_iC_FC.icLFC = Mesh_iC_icLFC;
        meshSubReg_iC_FC.aMFC = Mesh_iC_aMFC;
        meshSubReg_iC_FC.pMFC = Mesh_iC_pMFC;
        meshSubReg_iC_FC.ecMFC = Mesh_iC_ecMFC;
        meshSubReg_iC_FC.ccMFC = Mesh_iC_ccMFC;
        meshSubReg_iC_FC.icMFC = Mesh_iC_icMFC;

    case "left"
        %% Vertices
        % FC with recovered full-thickness cartilage loss
        versSubReg_scB_FC.aLFC = vers_scB_aMFC;
        versSubReg_scB_FC.pLFC = vers_scB_pMFC;
        versSubReg_scB_FC.ecLFC = vers_scB_ecMFC;
        versSubReg_scB_FC.ccLFC = vers_scB_ccMFC;
        versSubReg_scB_FC.icLFC = vers_scB_icMFC;
        versSubReg_scB_FC.aMFC = vers_scB_aLFC;
        versSubReg_scB_FC.pMFC = vers_scB_pLFC;
        versSubReg_scB_FC.ecMFC = vers_scB_ecLFC;
        versSubReg_scB_FC.ccMFC = vers_scB_ccLFC;
        versSubReg_scB_FC.icMFC = vers_scB_icLFC;
        % original FC
        versSubReg_iC_FC.aLFC = vers_iC_aMFC;
        versSubReg_iC_FC.pLFC = vers_iC_pMFC;
        versSubReg_iC_FC.ecLFC = vers_iC_ecMFC;
        versSubReg_iC_FC.ccLFC = vers_iC_ccMFC;
        versSubReg_iC_FC.icLFC = vers_iC_icMFC;
        versSubReg_iC_FC.aMFC = vers_iC_aLFC;
        versSubReg_iC_FC.pMFC = vers_iC_pLFC;
        versSubReg_iC_FC.ecMFC = vers_iC_ecLFC;
        versSubReg_iC_FC.ccMFC = vers_iC_ccLFC;
        versSubReg_iC_FC.icMFC = vers_iC_icLFC;

        %% Mesh
        % FC with recovered full-thickness cartilage loss
        meshSubReg_scB_FC.aLFC = Mesh_scB_aMFC;
        meshSubReg_scB_FC.pLFC = Mesh_scB_pMFC;
        meshSubReg_scB_FC.ecLFC = Mesh_scB_ecMFC;
        meshSubReg_scB_FC.ccLFC = Mesh_scB_ccMFC;
        meshSubReg_scB_FC.icLFC = Mesh_scB_icMFC;
        meshSubReg_scB_FC.aMFC = Mesh_scB_aLFC;
        meshSubReg_scB_FC.pMFC = Mesh_scB_pLFC;
        meshSubReg_scB_FC.ecMFC = Mesh_scB_ecLFC;
        meshSubReg_scB_FC.ccMFC = Mesh_scB_ccLFC;
        meshSubReg_scB_FC.icMFC = Mesh_scB_icLFC;
        % original FC
        meshSubReg_iC_FC.aLFC = Mesh_iC_aMFC;
        meshSubReg_iC_FC.pLFC = Mesh_iC_pMFC;
        meshSubReg_iC_FC.ecLFC = Mesh_iC_ecMFC;
        meshSubReg_iC_FC.ccLFC = Mesh_iC_ccMFC;
        meshSubReg_iC_FC.icLFC = Mesh_iC_icMFC;
        meshSubReg_iC_FC.aMFC = Mesh_iC_aLFC;
        meshSubReg_iC_FC.pMFC = Mesh_iC_pLFC;
        meshSubReg_iC_FC.ecMFC = Mesh_iC_ecLFC;
        meshSubReg_iC_FC.ccMFC = Mesh_iC_ccLFC;
        meshSubReg_iC_FC.icMFC = Mesh_iC_icLFC;
end

end