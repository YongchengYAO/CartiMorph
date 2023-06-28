% ==============================================================================
% <<< Caution <<< 
% (tested on Matlab 2021b (release 3))
% The build-in function "regionprops(BW,centroid)" returns (x,y) coordinates
% Other build-in functions in matlab may return (row, column) coordinates
% 
% *********** (x,y) coordinates & (row, column) coordinates *********** 
% - "x" is the horizontal coordinate and "y" is the vertical coordinate
% - "column" is the horizontal coordinate and "row" is the vertical coordinate
% - (x,y) is equal to (column, row)
% *********** (x,y) coordinates & (row, column) coordinates *********** 
% 
% e.g.
% Below will return wrong centroid coordinate:
%   > prop = regionprops(BW_2D,'Centroid');
%   > wrong_centroids = cat(1, prop.Centroid);
% 
% Below will return correct centroid coordinate:
%   > prop = regionprops(BW_2D,'Centroid');
%   > wrong_centroids = cat(1, prop.Centroid);
%   > correct_centroids(:,1) = wrong_centroids(:,2);
%   > correct_centroids(:,2) = wrong_centroids(:,1);
% 
% Related issue:
% https://www.mathworks.com/matlabcentral/answers/284040-reverse-input-image-coordinates#answer_221991
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 18-May-2022
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
% set paths
folder_in = "input/folder";
folder_out = "output/folder";

% file of subject info
path_subInfo = "path/to/subject-info-xlsx-file";
% =============================================================



%% Data-specific settings 
% ---------------------------
% knee side coding of OAI dataset
kneeCode_R = 1;
kneeCode_L = 2;

% file extension length
extType = '.nii.gz';

% label of TC
label_TC = 4;
newLabel_mTC = 4;
newLabel_lTC = 5;
% ---------------------------

% get subject list
list_sub = dir(fullfile(folder_in, append('*', extType)));
n_sub = size(list_sub, 1);

% get subject info table
table_subInfo = readtable(path_subInfo, ...
    FileType="spreadsheet", ...
    ReadVariableNames=true);
kneeSide = table_subInfo.KneeSide;


%% Split tibial cartilage into lateral and medial tibial cartilages
for i=1:n_sub
    i_subID = list_sub(i).name(1:end-length(extType));
    i_niiInfo = niftiinfo(fullfile(folder_in, list_sub(i).name));
    i_niiVol = niftiread(i_niiInfo);

    % remove isolated cluster 
    % (the label for subject 9269383 in the OAI-ZIB dataset has unexpected isolated cluster)
    i_mask = uint8(i_niiVol~=0);
    i_mask_clean = uint8(bwareaopen(i_mask, round(sum(i_mask(:))/10), 26));
    i_niiVol = i_niiVol .* i_mask_clean;

    % get knee side
    i_kneeSide = kneeSide(table_subInfo.SubjectID==str2double(i_subID), 1);

    % get orientation of image data array
    [dim_Right, dim_Anterior, dim_Superior] = cal_getOrientation_nifti(i_niiInfo.Transform.T);

    % gathering knee side and image orientation information
    if dim_Right>0
        code_invertDim = 1;
    else
        code_invertDim = -1;
    end

    switch i_kneeSide
        case kneeCode_R
            code_invertSide = 1;
        case kneeCode_L
            code_invertSide = -1;
        otherwise
            error("knee side in table %s is wrong", path_subInfo)
    end

    % remove isolated voxels (minmum cluster size is 10)
    i_maskTC = i_niiVol==label_TC;
    i_maskTC = uint8(bwareaopen(i_maskTC, 10, 26) .* i_maskTC); % assure no voxels are added

    % detect connected components in the TC mask
    cc_maskTC = bwconncomp(i_maskTC);
    if cc_maskTC.NumObjects==2
        idx_cc1 = cc_maskTC.PixelIdxList{1};
        idx_cc2 = cc_maskTC.PixelIdxList{2};
        prop_maskTC = regionprops(cc_maskTC,'Centroid');
        % change (x,y) coordinates to (row,column) coordinates
        centroids_xy = cat(1, prop_maskTC.Centroid);
        centroids(:, 1) = centroids_xy(:,2);
        centroids(:, 2) = centroids_xy(:,1);
        centroids(:, 3) = centroids_xy(:,3);
        centroid_cc1 = centroids(1, :);
        centroid_cc2 = centroids(2, :);
        if centroid_cc1(abs(dim_Right)) < centroid_cc2(abs(dim_Right))
            idx_maskTC_lower = idx_cc1;
            idx_maskTC_higher = idx_cc2;
        else
            idx_maskTC_lower = idx_cc2;
            idx_maskTC_higher = idx_cc1;
        end
        clear centroids
    elseif cc_maskTC.NumObjects>2
        num_cc = size(cc_maskTC.PixelIdxList, 2);
        size_cc = cell2mat(transpose(cellfun(@size, cc_maskTC.PixelIdxList, 'uni', false)));
        [~, sortIdx] = sort(size_cc(:,1), 'descend');
        prop_maskTC = regionprops(cc_maskTC,'Centroid');
        % change (x,y) coordinates to (row,column) coordinates
        centroids_xy = cat(1, prop_maskTC.Centroid);
        centroids(:, 1) = centroids_xy(:,2);
        centroids(:, 2) = centroids_xy(:,1);
        centroids(:, 3) = centroids_xy(:,3);
        centroid_cc1 = centroids(sortIdx(1), :);
        centroid_cc2 = centroids(sortIdx(2), :);
        ccID = transpose(1:num_cc);
        idx_other_cc = ccID(~ismember(ccID, [sortIdx(1);sortIdx(2)]));
        idx_cc1 = cc_maskTC.PixelIdxList{sortIdx(1)};
        idx_cc2 = cc_maskTC.PixelIdxList{sortIdx(2)};
        for ii = 1:size(idx_other_cc)
            ii_idx_cc = idx_other_cc(ii);
            ii_centroid = centroids(ii_idx_cc, :);
            if norm(ii_centroid-centroid_cc1) < norm(ii_centroid-centroid_cc2)
                idx_cc1 = cat(1, idx_cc1, cc_maskTC.PixelIdxList{ii_idx_cc});
            else
                idx_cc2 = cat(1, idx_cc2, cc_maskTC.PixelIdxList{ii_idx_cc});
            end
        end
        if centroid_cc1(abs(dim_Right)) < centroid_cc2(abs(dim_Right))
            idx_maskTC_lower = idx_cc1;
            idx_maskTC_higher = idx_cc2;
        else
            idx_maskTC_lower = idx_cc2;
            idx_maskTC_higher = idx_cc1;
        end
        clear centroids
    else 
        error('subject %s: the lTC and mTC are connected in the label', num2str(i_subID))
    end

    % assign new labels to mTC and lTC
    i_niiVol_out = i_niiVol;
    i_niiVol_out(i_niiVol_out==label_TC) = 0;
    i_maskTC_lower = zeros(size(i_maskTC), 'uint8');
    i_maskTC_higher = zeros(size(i_maskTC), 'uint8');
    code_minCoor4mTC = code_invertDim * code_invertSide;
    if code_minCoor4mTC > 0
        i_maskTC_lower(idx_maskTC_lower) = newLabel_mTC;
        i_maskTC_higher(idx_maskTC_higher) = newLabel_lTC;
    else
        i_maskTC_lower(idx_maskTC_lower) = newLabel_lTC;
        i_maskTC_higher(idx_maskTC_higher) = newLabel_mTC;
    end
    i_niiVol_out = i_niiVol_out + i_maskTC_lower + i_maskTC_higher;

    % save new mask
    if ~exist(folder_out, 'dir')
        mkdir(folder_out);
    end
    i_path_out = fullfile(folder_out, i_subID);
    i_niiInfo_new = i_niiInfo;
    i_niiInfo_new.Description = 'mask with corrected affine matrix and two TCs';
    i_niiInfo_new.Datatype = 'uint8';
    i_niiInfo_new.BitsPerPixel = 8;
    i_niiInfo_new.Filename = i_path_out;
    i_niiInfo_new.Filemoddate = datetime;
    i_niiInfo_new.Filesize = [];
    niftiwrite(i_niiVol_out, i_path_out, i_niiInfo_new, "Compressed", true);
end



function [dim_Right, dim_Anterior, dim_Superior] = cal_getOrientation_nifti(affineT)
% ==============================================================================
% FUNCTION:
%     Get NIfTI orientation. Find the anatomical orientation (R-L, A-P, S-L) of the image bases
%
% INPUT:
%     - affineT: (4,4), affine transformation matrix
%
% OUTPUT:
%     - dim_Right: dimension of image points to right
%     - dim_Anterior: dimension of image points to anterior
%     - dim_Superior: dimension of image points to superior
% 
% This function only works for NIfTI image
% Note, in NIfTI standard, real world bases correspond to {R, A, S} direction
% Note, real world bases and image bases are orthorgonal bases
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 06-Jul-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================


% ignore translation in affine transformation
mat = affineT(1:3, 1:3);

% "mat" is a linear transformation from "image space" to "real world space"
% [note, in NIfTI header, bases are rows in the matrix]
axis_i_real = mat(1, :);  % i axis in "image space" transformed to "real world space"
axis_j_real = mat(2, :);  % j axis in "image space" transformed to "real world space"
axis_k_real = mat(3, :);  % k axis in "image space" transformed to "real world space"

% define the orientation for real world bases -- the NIfTI standard RAS+
axis_R_real = [1,0,0];  % the [1,0,0] vector in "real space" point to Right
axis_A_real = [0,1,0];  % the [0,1,0] vector in "real space" point to Anterior
axis_S_real = [0,0,1];  % the [0,0,1] vector in "real space" point to Superior

% angle between transformed image bases and real world bases
angle_i_R = acosd(dot(axis_i_real, axis_R_real) / (norm(axis_R_real) * norm(axis_i_real)));
angle_i_A = acosd(dot(axis_i_real, axis_A_real) / (norm(axis_A_real) * norm(axis_i_real)));
angle_i_S = acosd(dot(axis_i_real, axis_S_real) / (norm(axis_S_real) * norm(axis_i_real)));

angle_j_R = acosd(dot(axis_j_real, axis_R_real) / (norm(axis_R_real) * norm(axis_j_real)));
angle_j_A = acosd(dot(axis_j_real, axis_A_real) / (norm(axis_A_real) * norm(axis_j_real)));
angle_j_S = acosd(dot(axis_j_real, axis_S_real) / (norm(axis_S_real) * norm(axis_j_real)));

angle_k_R = acosd(dot(axis_k_real, axis_R_real) / (norm(axis_R_real) * norm(axis_k_real)));
angle_k_A = acosd(dot(axis_k_real, axis_A_real) / (norm(axis_A_real) * norm(axis_k_real)));
angle_k_S = acosd(dot(axis_k_real, axis_S_real) / (norm(axis_S_real) * norm(axis_k_real)));

% convert angles to range [0,90] degree considering flipping
angles_i2RAS = [angle_i_R, angle_i_A, angle_i_S];
flip_i = angles_i2RAS > 90;
angles_i2RAS(flip_i) = 180 - angles_i2RAS(flip_i);

angles_j2RAS = [angle_j_R, angle_j_A, angle_j_S];
flip_j = angles_j2RAS > 90;
angles_j2RAS(flip_j) = 180 - angles_j2RAS(flip_j);

angles_k2RAS = [angle_k_R, angle_k_A, angle_k_S];
flip_K = angles_k2RAS > 90;
angles_k2RAS(flip_K) = 180 - angles_k2RAS(flip_K);

% find the approximate direction of transformed image bases
[~, direction_i] = min(angles_i2RAS);
if flip_i(direction_i)
    direction_i = direction_i .* -1;
end

fake_angles_j2RAS = angles_j2RAS;
fake_angles_j2RAS(abs(direction_i)) = 90;
[~, direction_j] = min(fake_angles_j2RAS);
if flip_j(direction_j)
    direction_j = direction_j .* -1;
end

fake_angles_k2RAS = angles_k2RAS;
fake_angles_k2RAS(abs(direction_i)) = 90;
fake_angles_k2RAS(abs(direction_j)) = 90;
[~, direction_k] = min(fake_angles_k2RAS);
if flip_K(direction_k)
    direction_k = direction_k .* -1;
end

% find the image dimension for Right, Anterior, and Superior directions
dim_Right = find([direction_i, direction_j, direction_k]==1);
if isempty(dim_Right)
    dim_Right = -1 * find([direction_i, direction_j, direction_k]==-1);
end

dim_Anterior = find([direction_i, direction_j, direction_k]==2);
if isempty(dim_Anterior)
    dim_Anterior = -1 * find([direction_i, direction_j, direction_k]==-2);
end

dim_Superior = find([direction_i, direction_j, direction_k]==3);
if isempty(dim_Superior)
    dim_Superior = -1 * find([direction_i, direction_j, direction_k]==-3);
end

end