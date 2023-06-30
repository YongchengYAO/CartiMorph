function CM_imgStandardisation(dir_in, dir_out, imgSize_out, flag_img)
% ==============================================================================
% FUNCTION:
%     Convert all NIfTI files to RAS+ orientation in a folder.
%
% INPUT:
%     - dir_in: [char], input folder
%     - dir_out: [char], output folder
%     - imgSize_out: output image size
%     - flag_img: [logical], is the input data images?
%
% OUTPUT:
%     no output variable
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 25-May-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================


% make folder
if ~isfolder(dir_out)
    mkdir(dir_out)
end

% subject list
dict_sub = [dir(fullfile(dir_in, "*.nii.gz")); dir(fullfile(dir_in, "*.nii"))];
n_sub = size(dict_sub, 1);

for i=1:n_sub
    % nifti file name
    i_nifti = dict_sub(i).name;
    [~, tmp_name, tmp_ext] = fileparts(i_nifti);
    if strcmp(tmp_ext, '.gz')
        [~, i_fileName, ~] = fileparts(tmp_name);
        i_fileName = char(i_fileName);
    else
        i_fileName = char(tmp_name);
    end
    if flag_img
        if strcmp(i_fileName(end-4:end), "_0000")
            i_fileName_out = i_fileName;
        else
            i_fileName_out = strcat(i_fileName, "_0000");
        end
    else
        i_fileName_out = i_fileName;
    end
    % nifti info
    i_nifti_info = niftiinfo(fullfile(dir_in, i_nifti));
    % data array
    i_nifti_data = double(niftiread(i_nifti_info));
    % affine transformation matrix
    affineMat = i_nifti_info.Transform.T;

    % get image orientation
    [dim_Right, dim_Anterior, dim_Superior] = CM_nifti_getOrientation(affineMat);

    % convert data array to RAS+
    i_nifti_data_RASplus = permute(i_nifti_data, abs([dim_Right, dim_Anterior, dim_Superior]));
    if dim_Right<0
        i_nifti_data_RASplus = flip(i_nifti_data_RASplus, 1);
    end
    if dim_Anterior<0
        i_nifti_data_RASplus = flip(i_nifti_data_RASplus, 2);
    end
    if dim_Superior<0
        i_nifti_data_RASplus = flip(i_nifti_data_RASplus, 3);
    end

    % update the affine transformation matrix
    i_affineMat_RASplus = cat(1, affineMat(abs(dim_Right),:), ...
        affineMat(abs(dim_Anterior),:), ...
        affineMat(abs(dim_Superior),:), ...
        affineMat(4,:));
    if dim_Right<0
        i_affineMat_RASplus(1,:) = -1 .* i_affineMat_RASplus(1,:);
    end
    if dim_Anterior<0
        i_affineMat_RASplus(2,:) = -1 .* i_affineMat_RASplus(2,:);
    end
    if dim_Superior<0
        i_affineMat_RASplus(3,:) = -1 .* i_affineMat_RASplus(3,:);
    end

    % update image size
    i_imgSize = i_nifti_info.ImageSize;
    i_imgSize_RASplus = [i_imgSize(abs(dim_Right)), i_imgSize(abs(dim_Anterior)), i_imgSize(abs(dim_Superior))];

    % update voxel size
    i_voxSize = i_nifti_info.PixelDimensions;
    i_voxSize_RASplus = [i_voxSize(abs(dim_Right)), i_voxSize(abs(dim_Anterior)), i_voxSize(abs(dim_Superior))];

    % resample
    i_scale = i_imgSize_RASplus ./ imgSize_out;
    i_voxSize_out = i_voxSize_RASplus .* i_scale;
    if flag_img
        i_nifti_data_out = CM_imgPreprocess_resample(i_nifti_data_RASplus, imgSize_out,...
            'linear', 'double');
    else
        i_nifti_data_out = CM_imgPreprocess_resample(i_nifti_data_RASplus, imgSize_out,...
            'nearest', 'double');
    end

    % update the affine matrix
    tmp_affineMat0 = [i_scale(1),0,0,0;
        0,i_scale(2),0,0;
        0,0,i_scale(3),0;
        0,0,0,1];
    i_affineMat_out = transpose(transpose(i_affineMat_RASplus) * tmp_affineMat0);
    i_affineObj_out = i_nifti_info.Transform;
    i_affineObj_out.T = i_affineMat_out;

    % normalize image intensity
    if flag_img
        intensity_min = min(i_nifti_data_out(:));
        intensity_max = max(i_nifti_data_out(:));
        i_nifti_data_out = (i_nifti_data_out - intensity_min)/(intensity_max - intensity_min);
    end

    % update nifti info
    i_nifti_info_out = i_nifti_info;
    i_nifti_info_out.Transform = i_affineObj_out; % affine transformation matrix (important)
    i_nifti_info_out.Filename = fullfile(dir_out, i_fileName_out); % filename (important)
    i_nifti_info_out.ImageSize = imgSize_out; % image size (important)
    i_nifti_info_out.PixelDimensions = i_voxSize_out; % voxel size (important)
    i_nifti_info_out.Datatype = class(i_nifti_data_out);
    i_nifti_info_out.MultiplicativeScaling = 1;
    i_nifti_info_out.FileModDate = regexprep(char(datetime), ' ', '_');
    i_nifti_info_out.FileSize = [];

    % save image
    niftiwrite(i_nifti_data_out, i_nifti_info_out.Filename, i_nifti_info_out, 'Compressed',true);
end
end