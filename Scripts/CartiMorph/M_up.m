% =============================================================
% This script should be used in combination with "M_down.m"
%
% The script "M_down.m" will estimate some parameters which
%   are the inputs of this script.
% =============================================================

clear;
clc;

% =============================================================
% modify this part only
% =============================================================
% image preprocessing parameters
path_imgPreInfo = "path/to/imgPreInfo.mat";

% input folder
dir_warpedTempSeg_in = "path/to/warped/template/segmentation/input/folder";

% output folder
dir_warpedTempSeg_out = "path/to/warped/template/segmentation/output/folder";
% =============================================================


% list of cases
tmp = [dir(fullfile(dir_warpedTempSeg_in, "*.nii.gz"));...
    dir(fullfile(dir_warpedTempSeg_in, "*.nii"))];
list_case = {tmp.name}';
num_case = length(list_case);

% image preprocessing parameters
imgPreInfo = load(path_imgPreInfo);

for i=1:num_case
    % file name
    i_fileName_wExt = list_case{i};
    [~, tmp_fileName, tmp_ext] = fileparts(i_fileName_wExt);
    if strcmp(tmp_ext, ".gz")
        [~, i_fileName_woExt, ~] = fileparts(tmp_fileName);
        i_ext = ".nii.gz";
    else
        i_fileName_woExt = tmp_fileName;
        i_ext = ".nii";
    end

    % get cropping range
    i_idx = strcmp(vertcat(imgPreInfo.filename{:}), i_fileName_wExt);
    i_cropRange = imgPreInfo.cropRange(i_idx, :);
    i_cropRangeX = i_cropRange(1):i_cropRange(2);
    i_cropRangeY = i_cropRange(3):i_cropRange(4);
    i_cropRangeZ = i_cropRange(5):i_cropRange(6);

    % load the warped template segmentation
    i_warpedTempSeg_info = niftiinfo(fullfile(dir_warpedTempSeg_in, i_fileName_wExt));
    i_warpedTempSeg_data = niftiread(i_warpedTempSeg_info);

    % recover the downsampled image via zero-filling
    i_warpTempSeg_lowres = zeros(imgPreInfo.imageSize_downsampled(i_idx, :));
    i_warpTempSeg_lowres(i_cropRangeX, i_cropRangeY, i_cropRangeZ) = i_warpedTempSeg_data;

    % recover the full-resolution image via resampling
    i_imgSize_fullRes = imgPreInfo.imageSize_original(i_idx, :);
    i_warpTempSeg_fullres = CM_imgPreprocess_resample(i_warpTempSeg_lowres, i_imgSize_fullRes,...
        'nearest', class(i_warpTempSeg_lowres));

    % update voxel size
    voxelSize_in = i_warpedTempSeg_info.PixelDimensions;
    imgSize_in = i_warpedTempSeg_info.ImageSize;
    scale = imgSize_in ./ imgSize_out;
    voxelSize_out = voxelSize_in .* scale;

    % update the affine matrix
    i_affineMat_in = i_warpedTempSeg_info.Transform.T;
    i_affineMat_zeroFiling = [1,0,0, 1-i_cropRangeX(1);
        0,1,0,1-i_cropRangeY(1);
        0,0,1,1-i_cropRangeZ(1);
        0,0,0,1];
    i_affineMat_scaling = [scale(1),0,0,0;
        0,scale(2),0,0;
        0,0,scale(3),0;
        0,0,0,1];
    i_affineMat_out = transpose(transpose(i_affineMat_in) * (i_affineMat_zeroFiling * i_affineMat_scaling));

    % update header
    file_segmentation_out_woExt = fullfile(dir_warpedTempSeg_out, i_fileName_woExt);
    i_warpedTempSeg_info_out = i_warpedTempSeg_info;
    i_warpedTempSeg_info_out.Transform.T = i_affineMat_out;
    i_warpedTempSeg_info_out.Filename = file_segmentation_out_woExt;
    i_warpedTempSeg_info_out.Datatype = class(i_warpTempSeg_fullres);
    i_warpedTempSeg_info_out.ImageSize = size(i_warpTempSeg_fullres);
    i_warpedTempSeg_info_out.Filemoddate = datetime;
    i_warpedTempSeg_info_out.Filesize = [];
    i_warpedTempSeg_info_out.PixelDimensions = voxelSize_out;

    % save the warped template segmentation after zero-filling and resampling
    niftiwrite(i_warpTempSeg_fullres, i_warpedTempSeg_info_out.Filename, i_warpedTempSeg_info_out, 'Compressed', true);

end
