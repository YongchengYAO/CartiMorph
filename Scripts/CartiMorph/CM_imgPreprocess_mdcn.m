function imgPreInfo = CM_imgPreprocess_mdcn(dir_seg_in, dir_img_in, dir_seg_out, dir_img_out,...
    imgSize_out, kneeSizeInfo, padding)
% -----------------------------------------------
% m: mask
% d: downsample
% c: crop
% n: normalize
% -----------------------------------------------

% get list of images
tmp = [dir(fullfile(dir_seg_in, "*.nii.gz"));dir(fullfile(dir_seg_in, "*.nii"))];
filenames_ext_cell = {tmp.name}';
numCase = length(filenames_ext_cell);

% record the cropping range
cropRange = zeros(numCase, 6);

% log image info
fileNames = cell([numCase, 1]);
imageSize_original = zeros([numCase, 3]);
imageSize_downsampled = zeros([numCase, 3]);
downFactor = zeros([numCase, 3]);

% (without parallel computing)
for i=1:numCase
    i_fileName_wExt = filenames_ext_cell{i};
    [~, tmp_fileName, tmp_ext] = fileparts(i_fileName_wExt);
    if strcmp(tmp_ext, '.gz')
        [~, i_fileName_woExt, ~] = fileparts(tmp_fileName);
        i_fileExt = ".nii.gz";
    elseif strcmp(tmp_ext, '.nii')
        i_fileName_woExt = tmp_fileName;
        i_fileExt = ".nii";
    else
        error("File Error: wrong file extension. We only support .nii and .nii.gz");
    end

    % read NIfTI files
    i_fileName = strcat(i_fileName_woExt, i_fileExt);
    fileNames{i} = i_fileName;
    i_segPath = fullfile(dir_seg_in, i_fileName);
    i_imgPath = fullfile(dir_img_in, strcat(i_fileName_woExt, "_0000", i_fileExt));
    i_segInfo = niftiinfo(i_segPath);
    i_imgInfo = niftiinfo(i_imgPath);
    i_segVol = niftiread(i_segInfo);
    i_imgVol = double(niftiread(i_imgInfo));

    % get the original voxel size
    i_voxSize = i_imgInfo.PixelDimensions;

    % get the original knee joint center and size
    i_idx = strcmp(kneeSizeInfo.filename, i_fileName);
    i_joint_center = kneeSizeInfo.center(i_idx, :);
    i_joint_size = kneeSizeInfo.size(i_idx, :);


    % ===============================================================
    % [1] mask image
    % ===============================================================
    i_mask = double(i_segVol>0);
    tmp = bwareaopen(i_mask, 10, 26);  % conn=26
    i_mask = double(imfill(tmp, 6, 'holes'));  % conn=6
    i_imgVol_m = i_imgVol .* i_mask;
    i_imgSize = size(i_imgVol_m);
    % log the original image size
    imageSize_original(i, :) = i_imgSize;
    % ===============================================================


    % ===============================================================
    % [2] determine the downsampling factor
    %     - i_downFactor>1: downsample
    %     - i_downFactor<1: upsample
    % ===============================================================
    % adjust padding automatically
    tmp_dROI_size = i_joint_size + 2 * padding;
    while any(tmp_dROI_size>i_imgSize)
        padding = padding - 1;
        tmp_dROI_size = i_joint_size + 2 * padding;
    end
    i_dROI_size = tmp_dROI_size;
    i_tmpDownFactor = max(i_dROI_size ./ imgSize_out);
    %                 if i_tmpDownFactor <=1 % disable upsample
    %                     i_tmpDownFactor = 1;
    %                 end
    i_imgSize_d = round(i_imgSize ./ i_tmpDownFactor);
    i_downFactor = i_imgSize ./ i_imgSize_d;
    i_voxSize_out = i_voxSize .* i_downFactor;
    % log the downsampling factor
    downFactor(i, :) = i_downFactor;
    % ===============================================================


    % ===============================================================
    % [3] downsample image and segmantation mask
    % ===============================================================
    i_imgVol_md = CM_imgPreprocess_resample(i_imgVol_m, i_imgSize_d, 'linear', 'double');
    i_segVol_md = CM_imgPreprocess_resample(i_segVol, i_imgSize_d, 'nearest', 'uint8');
    i_joint_center_d = round(i_joint_center ./ i_downFactor);
    % log the downsampled image size
    imageSize_downsampled(i, :) = i_imgSize_d;
    % prepare for updating the affine matrix
    tmp_affineMat0 = [i_downFactor(1),0,0,0;
        0,i_downFactor(2),0,0;
        0,0,i_downFactor(3),0;
        0,0,0,1];
    % ===============================================================


    % ===============================================================
    % [4]crop image and segmentation mask
    % ===============================================================
    % estiamte the cropping box
    x_boxLen = imgSize_out(1);
    y_boxLen = imgSize_out(2);
    z_boxLen = imgSize_out(3);
    x_cropRange = (i_joint_center_d(1)-floor(x_boxLen/2)):(i_joint_center_d(1)+ceil(x_boxLen/2)-1);
    y_cropRange = (i_joint_center_d(2)-floor(y_boxLen/2)):(i_joint_center_d(2)+ceil(y_boxLen/2)-1);
    z_cropRange = (i_joint_center_d(3)-floor(z_boxLen/2)):(i_joint_center_d(3)+ceil(z_boxLen/2)-1);

    % shift the cropping box if necessary
    if min(x_cropRange) <= 0
        x_cropRange = x_cropRange + abs(min(x_cropRange)) + 1;
    end
    if min(y_cropRange) <= 0
        y_cropRange = y_cropRange + abs(min(y_cropRange)) + 1;
    end
    if min(z_cropRange) <= 0
        z_cropRange = z_cropRange + abs(min(z_cropRange)) + 1;
    end
    if max(x_cropRange) > i_imgSize_d(1)
        x_cropRange = x_cropRange - (max(x_cropRange) - i_imgSize_d(1));
    end
    if max(y_cropRange) > i_imgSize_d(2)
        y_cropRange = y_cropRange - (max(y_cropRange) - i_imgSize_d(2));
    end
    if max(z_cropRange) > i_imgSize_d(3)
        z_cropRange = z_cropRange - (max(z_cropRange) - i_imgSize_d(3));
    end

    % crop MR image and label
    i_imgVol_mdc = i_imgVol_md(x_cropRange, y_cropRange, z_cropRange);
    i_segVol_mdc = i_segVol_md(x_cropRange, y_cropRange, z_cropRange);

    % update affine transformation matrix (important)
    i_affine_obj_out = i_imgInfo.Transform;
    i_affineMat = i_imgInfo.Transform.T;
    tmp_affineMat1 = [1,0,0, x_cropRange(1)-1;
        0,1,0,y_cropRange(1)-1;
        0,0,1,z_cropRange(1)-1;
        0,0,0,1];
    i_affineMat_out = transpose(transpose(i_affineMat) * (tmp_affineMat0 * tmp_affineMat1));
    i_affine_obj_out.T = i_affineMat_out;
    % ===============================================================


    % ===============================================================
    % [4] normalized image intensity
    % ===============================================================
    i_imgIntensity_min = min(i_imgVol_mdc(:));
    i_imgIntensity_max = max(i_imgVol_mdc(:));
    i_imgVol_mdcn = (i_imgVol_mdc - i_imgIntensity_min) ./ (i_imgIntensity_max - i_imgIntensity_min);
    % ===============================================================


    % ===============================================================
    % save files
    % ===============================================================
    % change NIfTI header info for the cropped image
    i_imgInfo_out = i_imgInfo;
    % change filename (important)
    i_imgInfo_out.Filename = fullfile(dir_img_out, i_fileName_woExt);
    % change image size (important)
    i_imgInfo_out.ImageSize = imgSize_out;
    % change voxel size (important)
    i_imgInfo_out.PixelDimensions = i_voxSize_out;
    % change affine transformation matrix (important)
    i_imgInfo_out.Transform = i_affine_obj_out;
    % others
    i_imgInfo_out.MultiplicativeScaling = 1;
    i_imgInfo_out.FileModDate = regexprep(char(datetime), ' ', '_');
    i_imgInfo_out.FileSize = [];
    i_imgInfo_out.Datatype = class(i_imgVol_mdcn);
    % save cropped MR image
    niftiwrite(i_imgVol_mdcn, i_imgInfo_out.Filename, i_imgInfo_out, 'Compressed', true);

    % save cropped label
    if ~isempty(dir_seg_out)
        % change NIfTI header info for the cropped label
        i_segInfo_out = i_imgInfo;
        % change filename (important)
        i_segInfo_out.Filename = fullfile(dir_seg_out, i_fileName_woExt);
        % change image size (important)
        i_segInfo_out.ImageSize = imgSize_out;
        % change voxel size (important)
        i_segInfo_out.PixelDimensions = i_voxSize_out;
        % change affine transformation matrix (important)
        i_segInfo_out.Transform = i_affine_obj_out;
        % others
        i_segInfo_out.MultiplicativeScaling = 1;
        i_segInfo_out.FileModDate = regexprep(char(datetime), ' ', '_');
        i_segInfo_out.FileSize = [];
        i_segInfo_out.Datatype = class(i_segVol_mdc);
        % save to .nii
        niftiwrite(i_segVol_mdc, i_segInfo_out.Filename, i_segInfo_out, 'Compressed', true);
    end
    % ===============================================================

    % log the cropping range
    cropRange(i, :) = [min(x_cropRange), max(x_cropRange), ...
        min(y_cropRange), max(y_cropRange), ...
        min(z_cropRange), max(z_cropRange)];
end

% gather all info
imgPreInfo.filename = fileNames;
imgPreInfo.cropRange = cropRange;
imgPreInfo.imageSize_original = imageSize_original;
imgPreInfo.imageSize_downsampled = imageSize_downsampled;
imgPreInfo.downFactor = downFactor;
end