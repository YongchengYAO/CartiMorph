function [versSubReg_iC_FC, versSubReg_scB_FC, meshSubReg_iC_FC, meshSubReg_scB_FC] ...
    = CM_cal_SurfaceParcellation_FC(...
    mesh_iC_FC, ...
    mesh_scB_FC, ...
    size_voxel, ...
    knee_side, ...
    cc_percentage)
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
%
% OUTPUT:
%     - versSubReg_iC_FC: [structure], vertices on the interior cartilage surface of FC
%     - versSubReg_scB_FC: [structure], vertices on the subchondral bone surface of FC
%     - meshSubReg_iC_FC: [structure], the interior cartilage surface of FC
%     - meshSubReg_scB_FC: [structure], the subchondral bone surface of FC
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 16-May-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================


% interior cartilage surface of FC
faces_iC_FC = mesh_iC_FC.faces;
vers_iC_FC = mesh_iC_FC.vertices;
subs_iC_FC = round(vers_iC_FC ./ size_voxel);

% the subchondral bone surface of FC
faces_scB_FC = mesh_scB_FC.faces;
vers_scB_FC = mesh_scB_FC.vertices;
subs_scB_FC = round(vers_scB_FC ./ size_voxel);



%% Parcellate subchondral bone area of FC
% ---------------------------------------------------------
% Locate the intercondylar notch
% ---------------------------------------------------------
% (assuming the second dimension of image array is the P-A direction, i.e., y+ points to A)
% sagittal slice indices
subsLR_scB_FC = sort(unique(subs_scB_FC(:,1)), 'ascend');
numSag = length(subsLR_scB_FC);
% extract some (50%) center slices
subsLR_scB_FC_center = subsLR_scB_FC(round(numSag * 0.25):round(numSag * 0.75));
minSubAP_scB_FC_center = zeros(length(subsLR_scB_FC_center), 1);
for i = 1:length(subsLR_scB_FC_center)
    i_subLR_scB_FC_center = subsLR_scB_FC_center(i);
    minSubAP_scB_FC_center(i,1) = min(subs_scB_FC(subs_scB_FC(:,1)==i_subLR_scB_FC_center, 2));
end
subNotchAP_scB_FC_center = max(minSubAP_scB_FC_center);
candidate = sort(find(minSubAP_scB_FC_center==subNotchAP_scB_FC_center));
idx = candidate(ceil(length(candidate)/2));
subNotchLR_scB_FC = subsLR_scB_FC_center(idx);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the central lateral FC (cLFC)
% ---------------------------------------------------------
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
subs_scB_LFC = subs_scB_FC(subs_scB_FC(:,1)>=subNotchLR_scB_FC, :);
minSubAP_scB_LFC = min(subs_scB_LFC(:,2));
minSubAP_scB_cLFC = subNotchAP_scB_FC_center - round((subNotchAP_scB_FC_center - minSubAP_scB_LFC) * cc_percentage);
idxAP_scB_cLFC = subs_scB_LFC(:,2)<subNotchAP_scB_FC_center & subs_scB_LFC(:,2)>minSubAP_scB_cLFC;
subs_scB_cLFC = subs_scB_LFC(idxAP_scB_cLFC, :);

% extract faces
faces_scB_cLFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_cLFC);

% remove small components (MeshProcessingToolbox)
[~, components_scB_cLFC] = MPT_segment_connected_components(faces_scB_cLFC, 'explicit');
faces_scB_cLFC = CM_cal_deleteSmallComponents(components_scB_cLFC, 50);
[vers_scB_cLFC, ~] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_cLFC);
subs_scB_cLFC = round(vers_scB_cLFC ./ size_voxel);

subs_partial_scB_pLFC = [];
subs_partial_scB_aLFC = [];
faces_smallCC_scB_LFC = CM_cal_deleteLargeComponents(components_scB_cLFC, 50);
if ~isempty(faces_smallCC_scB_LFC)
    [~, components_smallCC_scB_LFC] = MPT_segment_connected_components(faces_smallCC_scB_LFC, 'explicit');
    for ii = 1:size(components_smallCC_scB_LFC,1)
        faces_smallCC_scB_LFC = cell2mat(components_smallCC_scB_LFC(ii, 1));
        [vers_smallCC_scB_LFC, ~] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_smallCC_scB_LFC);
        subs_centerSI_smallCC_scB_LFC = round(mean(vers_smallCC_scB_LFC(:,3)) ./ size_voxel(3));
        subs_centerAP_smallCC_scB_LFC = round(mean(vers_smallCC_scB_LFC(:,2)) ./ size_voxel(2));
        subs_centerSI_cLFC = round(mean(vers_scB_cLFC(:,3)) ./ size_voxel(3));
        subsRange_centerSI_sLFC = round((max(vers_scB_cLFC(:,3))-min(vers_scB_cLFC(:,3))) ./ size_voxel(3));
        if (subs_centerSI_smallCC_scB_LFC - subs_centerSI_cLFC) > subsRange_centerSI_sLFC
            % the small connected component if part of pLFC
            subs_partial_scB_pLFC = cat(1, subs_partial_scB_pLFC, round(vers_smallCC_scB_LFC ./ size_voxel));
        elseif abs(subs_centerAP_smallCC_scB_LFC - subNotchAP_scB_FC_center) <= 2
            % the small connected component if part of aLFC
            subs_partial_scB_aLFC = cat(1, subs_partial_scB_aLFC, round(vers_smallCC_scB_LFC ./ size_voxel));
        else
            % the small connected component if part of cLFC
            subs_scB_cLFC = cat(1, subs_scB_cLFC, round(vers_smallCC_scB_LFC ./ size_voxel));
        end
    end
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the central medial FC (cMFC)
% ---------------------------------------------------------
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
subs_scB_MFC = subs_scB_FC(subs_scB_FC(:,1)<subNotchLR_scB_FC, :);
minSubAP_scB_MFC = min(subs_scB_MFC(:,2));
minSubAP_scB_cMFC = subNotchAP_scB_FC_center - round((subNotchAP_scB_FC_center - minSubAP_scB_MFC) * cc_percentage);
idxAP_scB_cMFC = subs_scB_MFC(:,2)<subNotchAP_scB_FC_center & subs_scB_MFC(:,2)>minSubAP_scB_cMFC;
subs_scB_cMFC = subs_scB_MFC(idxAP_scB_cMFC, :);

% extract faces
faces_scB_cMFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_cMFC);

% remove small components from the non-interface mesh (MeshProcessingToolbox)
[~, components_scB_cMFC] = MPT_segment_connected_components(faces_scB_cMFC, 'explicit');
faces_scB_cMFC = CM_cal_deleteSmallComponents(components_scB_cMFC, 50);
[vers_scB_cMFC, ~] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_cMFC);
subs_scB_cMFC = round(vers_scB_cMFC ./ size_voxel);

subs_partial_scB_pMFC = [];
subs_partial_scB_aMFC = [];
faces_smallCC_scB_MFC = CM_cal_deleteLargeComponents(components_scB_cMFC, 50);
if ~isempty(faces_smallCC_scB_MFC)
    [~, components_smallCC_scB_MFC] = MPT_segment_connected_components(faces_smallCC_scB_MFC, 'explicit');
    for ii = 1:size(components_smallCC_scB_MFC,1)
        faces_smallCC_scB_MFC = cell2mat(components_smallCC_scB_MFC(ii, 1));
        [vers_smallCC_scB_MFC, ~] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_smallCC_scB_MFC);
        subs_centerSI_smallCC_scB_MFC = round(mean(vers_smallCC_scB_MFC(:,3)) ./ size_voxel(3));
        subs_centerAP_smallCC_scB_MFC = round(mean(vers_smallCC_scB_MFC(:,2)) ./ size_voxel(2));
        subs_centerSI_cMFC = round(mean(vers_scB_cMFC(:,3)) ./ size_voxel(3));
        subsRange_centerSI_sMFC = round((max(vers_scB_cMFC(:,3))-min(vers_scB_cMFC(:,3))) ./ size_voxel(3));
        if (subs_centerSI_smallCC_scB_MFC - subs_centerSI_cMFC) > subsRange_centerSI_sMFC
            % the small connected component if part of pMFC
            subs_partial_scB_pMFC = cat(1, subs_partial_scB_pMFC, round(vers_smallCC_scB_MFC ./ size_voxel));
        elseif abs(subs_centerAP_smallCC_scB_MFC - subNotchAP_scB_FC_center) <= 2
            % the small connected component if part of aMFC
            subs_partial_scB_aMFC = cat(1, subs_partial_scB_aMFC, round(vers_smallCC_scB_MFC ./ size_voxel));
        else
            % the small connected component if part of cMFC
            subs_scB_cMFC = cat(1, subs_scB_cMFC, round(vers_smallCC_scB_MFC ./ size_voxel));
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
maxSubAP_scB_LFC = max(subs_scB_LFC(:,2));
idx_scB_aLFC = subs_scB_LFC(:,2)<=maxSubAP_scB_LFC & subs_scB_LFC(:,2)>=subNotchAP_scB_FC_center;
subs_scB_aLFC = subs_scB_LFC(idx_scB_aLFC, :);
if exist("subs_partial_scB_aLFC", 'var')
    subs_scB_aLFC = cat(1, subs_scB_aLFC, subs_partial_scB_aLFC);
end
vers_scB_aLFC = subs_scB_aLFC .* size_voxel;

% pLFC
idx_scB_pLFC = subs_scB_LFC(:,2)<=minSubAP_scB_cLFC & subs_scB_LFC(:,2)>=minSubAP_scB_LFC;
subs_scB_pLFC = subs_scB_LFC(idx_scB_pLFC, :);
if exist("subs_partial_scB_pLFC", 'var')
    subs_scB_pLFC = cat(1, subs_scB_pLFC, subs_partial_scB_pLFC);
end
vers_scB_pLFC = subs_scB_pLFC .* size_voxel;
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aMFC, pMFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ---------------------------------------------------------
% aMFC
maxSubAP_scB_MFC = max(subs_scB_MFC(:,2));
idx_scB_aMFC = subs_scB_MFC(:,2)<=maxSubAP_scB_MFC & subs_scB_MFC(:,2)>=subNotchAP_scB_FC_center;
subs_scB_aMFC = subs_scB_MFC(idx_scB_aMFC, :);
if exist("subs_partial_scB_aMFC", 'var')
    subs_scB_aMFC = cat(1, subs_scB_aMFC, subs_partial_scB_aMFC);
end
vers_scB_aMFC = subs_scB_aMFC .* size_voxel;

% pMFC
idx_scB_pMFC = subs_scB_MFC(:,2)<=minSubAP_scB_cMFC & subs_scB_MFC(:,2)>=minSubAP_scB_MFC;
subs_scB_pMFC = subs_scB_MFC(idx_scB_pMFC, :);
if exist("subs_partial_scB_pMFC", 'var')
    subs_scB_pMFC = cat(1, subs_scB_pMFC, subs_partial_scB_pMFC);
end
vers_scB_pMFC = subs_scB_pMFC .* size_voxel;
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the ecLFC, ccLFC, and icLFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ecLFC: exterior part of cLFC
% ccLFC: central part of cLFC
% icLFC: interior part of cLFC
% ---------------------------------------------------------
subsAP_scB_cLFC = unique(subs_scB_cLFC(:,2));
subs_scB_ecLFC = [];
subs_scB_ccLFC = [];
subs_scB_icLFC = [];
for i = 1:length(subsAP_scB_cLFC)
    i_subAP_scB_cLFC = subsAP_scB_cLFC(i);
    i_subs_scB_cLFC = subs_scB_cLFC(subs_scB_cLFC(:,2)==i_subAP_scB_cLFC, :);
    i_maxSubLR_scB_cLFC = max(i_subs_scB_cLFC(:,1));
    i_minSubLR_scB_cLFC = min(i_subs_scB_cLFC(:,1));
    i_cutSubLR_scB_cLFC_f1 = i_minSubLR_scB_cLFC + (i_maxSubLR_scB_cLFC - i_minSubLR_scB_cLFC) * 1/3;
    i_cutSubLR_scB_cLFC_f2 = i_minSubLR_scB_cLFC + (i_maxSubLR_scB_cLFC - i_minSubLR_scB_cLFC) * 2/3;
    i_idx_scB_ecLFC = i_subs_scB_cLFC(:,1)<=i_maxSubLR_scB_cLFC & i_subs_scB_cLFC(:,1)>i_cutSubLR_scB_cLFC_f2;
    i_idx_scB_ccLFC = i_subs_scB_cLFC(:,1)<=i_cutSubLR_scB_cLFC_f2 & i_subs_scB_cLFC(:,1)>=i_cutSubLR_scB_cLFC_f1;
    i_idx_scB_icLFC = i_subs_scB_cLFC(:,1)<i_cutSubLR_scB_cLFC_f1 & i_subs_scB_cLFC(:,1)>=i_minSubLR_scB_cLFC;
    i_subs_scB_ecLFC = i_subs_scB_cLFC(i_idx_scB_ecLFC, :);
    i_subs_scB_ccLFC = i_subs_scB_cLFC(i_idx_scB_ccLFC, :);
    i_subs_scB_icLFC = i_subs_scB_cLFC(i_idx_scB_icLFC, :);
    subs_scB_ecLFC = cat(1, subs_scB_ecLFC, i_subs_scB_ecLFC);
    subs_scB_ccLFC = cat(1, subs_scB_ccLFC, i_subs_scB_ccLFC);
    subs_scB_icLFC = cat(1, subs_scB_icLFC, i_subs_scB_icLFC);
end
vers_scB_ecLFC = subs_scB_ecLFC .* size_voxel;
vers_scB_ccLFC = subs_scB_ccLFC .* size_voxel;
vers_scB_icLFC = subs_scB_icLFC .* size_voxel;
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate the ecMFC, ccMFC, and icMFC
% (1. assuming the first dimension of image array is the L-R direction, i.e., x+ points to R)
% (2. assuming right knee)
% ecMFC: exterior part of cMFC
% ccMFC: central part of cMFC
% icMFC: interior part of cMFC
% ---------------------------------------------------------
subsAP_scB_cMFC = unique(subs_scB_cMFC(:,2));
subs_scB_ecMFC = [];
subs_scB_ccMFC = [];
subs_scB_icMFC = [];
for i = 1:length(subsAP_scB_cMFC)
    i_subAP_scB_cMFC = subsAP_scB_cMFC(i);
    i_subs_scB_cMFC = subs_scB_cMFC(subs_scB_cMFC(:,2)==i_subAP_scB_cMFC, :);
    i_maxSubLR_scB_cMFC = max(i_subs_scB_cMFC(:,1));
    i_minSubLR_scB_cMFC = min(i_subs_scB_cMFC(:,1));
    i_cutSubLR_scB_cMFC_f1 = i_minSubLR_scB_cMFC + (i_maxSubLR_scB_cMFC - i_minSubLR_scB_cMFC) * 1/3;
    i_cutSubLR_scB_cMFC_f2 = i_minSubLR_scB_cMFC + (i_maxSubLR_scB_cMFC - i_minSubLR_scB_cMFC) * 2/3;
    i_idx_scB_icMFC = i_subs_scB_cMFC(:,1)<=i_maxSubLR_scB_cMFC & i_subs_scB_cMFC(:,1)>i_cutSubLR_scB_cMFC_f2;
    i_idx_scB_ccMFC = i_subs_scB_cMFC(:,1)<=i_cutSubLR_scB_cMFC_f2 & i_subs_scB_cMFC(:,1)>=i_cutSubLR_scB_cMFC_f1;
    i_idx_scB_ecMFC = i_subs_scB_cMFC(:,1)<i_cutSubLR_scB_cMFC_f1 & i_subs_scB_cMFC(:,1)>=i_minSubLR_scB_cMFC;
    i_subs_scB_icMFC = i_subs_scB_cMFC(i_idx_scB_icMFC, :);
    i_subs_scB_ccMFC = i_subs_scB_cMFC(i_idx_scB_ccMFC, :);
    i_subs_scB_ecMFC = i_subs_scB_cMFC(i_idx_scB_ecMFC, :);
    subs_scB_icMFC = cat(1, subs_scB_icMFC, i_subs_scB_icMFC);
    subs_scB_ccMFC = cat(1, subs_scB_ccMFC, i_subs_scB_ccMFC);
    subs_scB_ecMFC = cat(1, subs_scB_ecMFC, i_subs_scB_ecMFC);
end
vers_scB_ecMFC = subs_scB_ecMFC .* size_voxel;
vers_scB_ccMFC = subs_scB_ccMFC .* size_voxel;
vers_scB_icMFC = subs_scB_icMFC .* size_voxel;
% ---------------------------------------------------------



%% Parcellate FC
vers_iC_aLFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_aLFC, 'rows'), :);
vers_iC_pLFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_pLFC, 'rows'), :);
vers_iC_ecLFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_ecLFC, 'rows'), :);
vers_iC_ccLFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_ccLFC, 'rows'), :);
vers_iC_icLFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_icLFC, 'rows'), :);
vers_iC_aMFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_aMFC, 'rows'), :);
vers_iC_pMFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_pMFC, 'rows'), :);
vers_iC_ecMFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_ecMFC, 'rows'), :);
vers_iC_ccMFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_ccMFC, 'rows'), :);
vers_iC_icMFC = vers_iC_FC(ismember(subs_iC_FC, subs_scB_icMFC, 'rows'), :);
subs_iC_aLFC = round(vers_iC_aLFC ./ size_voxel);
subs_iC_pLFC = round(vers_iC_pLFC ./ size_voxel);
subs_iC_ecLFC = round(vers_iC_ecLFC ./ size_voxel);
subs_iC_ccLFC = round(vers_iC_ccLFC ./ size_voxel);
subs_iC_icLFC = round(vers_iC_icLFC ./ size_voxel);
subs_iC_aMFC = round(vers_iC_aMFC ./ size_voxel);
subs_iC_pMFC = round(vers_iC_pMFC ./ size_voxel);
subs_iC_ecMFC = round(vers_iC_ecMFC ./ size_voxel);
subs_iC_ccMFC = round(vers_iC_ccMFC ./ size_voxel);
subs_iC_icMFC = round(vers_iC_icMFC ./ size_voxel);



%% Extract faces of each subregion
% FC with recovered full-thickness cartilage loss
faces_scB_aLFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_aLFC);
[Mesh_scB_aLFC.vertices, Mesh_scB_aLFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_aLFC);
faces_scB_pLFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_pLFC);
[Mesh_scB_pLFC.vertices, Mesh_scB_pLFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_pLFC);
faces_scB_ecLFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_ecLFC);
[Mesh_scB_ecLFC.vertices, Mesh_scB_ecLFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_ecLFC);
faces_scB_ccLFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_ccLFC);
[Mesh_scB_ccLFC.vertices, Mesh_scB_ccLFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_ccLFC);
faces_scB_icLFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_icLFC);
[Mesh_scB_icLFC.vertices, Mesh_scB_icLFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_icLFC);
faces_scB_aMFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_aMFC);
[Mesh_scB_aMFC.vertices, Mesh_scB_aMFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_aMFC);
faces_scB_pMFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_pMFC);
[Mesh_scB_pMFC.vertices, Mesh_scB_pMFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_pMFC);
faces_scB_ecMFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_ecMFC);
[Mesh_scB_ecMFC.vertices, Mesh_scB_ecMFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_ecMFC);
faces_scB_ccMFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_ccMFC);
[Mesh_scB_ccMFC.vertices, Mesh_scB_ccMFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_ccMFC);
faces_scB_icMFC = CM_cal_extractFaces_OR(faces_scB_FC, subs_scB_FC, subs_scB_icMFC);
[Mesh_scB_icMFC.vertices, Mesh_scB_icMFC.faces] = MPT_remove_unreferenced_vertices(vers_scB_FC, faces_scB_icMFC);

% original FC
if ~isempty(subs_iC_aLFC)
    faces_iC_aLFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_aLFC);
    [Mesh_iC_aLFC.vertices, Mesh_iC_aLFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_aLFC);
else
    Mesh_iC_aLFC = [];
end

if ~isempty(subs_iC_pLFC)
    faces_iC_pLFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_pLFC);
    [Mesh_iC_pLFC.vertices, Mesh_iC_pLFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_pLFC);
else
    Mesh_iC_pLFC = [];
end

if ~isempty(subs_iC_ecLFC)
    faces_iC_ecLFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_ecLFC);
    [Mesh_iC_ecLFC.vertices, Mesh_iC_ecLFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_ecLFC);
else
    Mesh_iC_ecLFC = [];
end

if ~isempty(subs_iC_ccLFC)
    faces_iC_ccLFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_ccLFC);
    [Mesh_iC_ccLFC.vertices, Mesh_iC_ccLFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_ccLFC);
else
    Mesh_iC_ccLFC = [];
end

if ~isempty(subs_iC_icLFC)
    faces_iC_icLFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_icLFC);
    [Mesh_iC_icLFC.vertices, Mesh_iC_icLFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_icLFC);
else
    Mesh_iC_icLFC = [];
end

if ~isempty(subs_iC_aMFC)
    faces_iC_aMFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_aMFC);
    [Mesh_iC_aMFC.vertices, Mesh_iC_aMFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_aMFC);
else
    Mesh_iC_aMFC = [];
end

if ~isempty(subs_iC_pMFC)
    faces_iC_pMFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_pMFC);
    [Mesh_iC_pMFC.vertices, Mesh_iC_pMFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_pMFC);
else
    Mesh_iC_pMFC = [];
end

if ~isempty(subs_iC_ecMFC)
    faces_iC_ecMFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_ecMFC);
    [Mesh_iC_ecMFC.vertices, Mesh_iC_ecMFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_ecMFC);
else
    Mesh_iC_ecMFC = [];
end

if ~isempty(subs_iC_ccMFC)
    faces_iC_ccMFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_ccMFC);
    [Mesh_iC_ccMFC.vertices, Mesh_iC_ccMFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_ccMFC);
else
    Mesh_iC_ccMFC = [];
end

if ~isempty(subs_iC_icMFC)
    faces_iC_icMFC = CM_cal_extractFaces_OR(faces_iC_FC, subs_iC_FC, subs_iC_icMFC);
    [Mesh_iC_icMFC.vertices, Mesh_iC_icMFC.faces] = MPT_remove_unreferenced_vertices(vers_iC_FC, faces_iC_icMFC);
else
    Mesh_iC_icMFC = [];
end


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