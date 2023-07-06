clear;
clc;


% =============================================================
% modify this part only
% =============================================================
% [input]
% template image
file_template_in = 'path/to/template/segmentation/CLAIR-Knee-103R_template.nii.gz';
% template segmentation
file_segmentation_in = 'path/to/template/segmentation/CLAIR-Knee-103R_segmentation.nii.gz';

% [output]
% template image
file_template_out = 'path/to/template/segmentation/CLAIR-Knee-103R_template_160x384x384_V2.nii.gz';
% template segmentation
file_segmentation_out = 'path/to/template/segmentation/CLAIR-Knee-103R_segmentation_160x384x384_V2.nii.gz';

% output image size
imgSize_out = [160, 384, 384];
% =============================================================


% ROI to be smoothed after resampling
label_tbs = [1,2,3,4,5];

% Gaussian smoothing parameter
maskSmoothing_gamma = 2;
ROISmoothing_gamma = 2;
threshold = 0.5;


% =============================================================
% Resample template image (subject to RAS+ orientation)
% =============================================================
% resample
template_info = niftiinfo(file_template_in);
template_in = double(niftiread(template_info));
template_out = CM_imgPreprocess_resample(template_in, imgSize_out, 'linear', class(template_in));

% update voxel size
voxelSize_in = template_info.PixelDimensions;
imgSize_in = template_info.ImageSize;
scale = imgSize_in ./ imgSize_out;
voxelSize_out = voxelSize_in .* scale;

% update the affine matrix
temp_affineMat = template_info.Transform.T;
temp_affineMat_scaling = [scale(1),0,0,0;
    0,scale(2),0,0;
    0,0,scale(3),0;
    0,0,0,1];
tmep_affineMat_out = transpose(transpose(temp_affineMat) * temp_affineMat_scaling);

% remove file extension
[folder, tmp_fileName, tmp_ext] = fileparts(file_template_out);
if strcmp(tmp_ext, ".gz")
    [~, fileName_woExt, ~] = fileparts(tmp_fileName);
else
    fileName_woExt = tmp_fileName;
end
file_template_out_woExt = fullfile(folder, fileName_woExt);

% update header
template_out_info = template_info;
template_out_info.Transform.T = tmep_affineMat_out;
template_out_info.Filename = file_template_out_woExt;
template_out_info.Datatype = class(template_out);
template_out_info.ImageSize = size(template_out);
template_out_info.Filemoddate = datetime;
template_out_info.Filesize = [];
template_out_info.PixelDimensions = voxelSize_out;
niftiwrite(template_out, template_out_info.Filename, template_out_info, 'Compressed', true);
% =============================================================


% =============================================================
% resample template segmentation (subject to RAS+ orientation)
% =============================================================
% resample
segmentation_info = niftiinfo(file_segmentation_in);
segmentation_in = uint8(niftiread(segmentation_info));
segmentation_out = CM_imgPreprocess_resample(segmentation_in, imgSize_out, 'nearest', class(segmentation_in));

% update voxel size
voxelSize_in = segmentation_info.PixelDimensions;
imgSize_in = segmentation_info.ImageSize;
scale = imgSize_in ./ imgSize_out;
voxelSize_out = voxelSize_in .* scale;

% update the affine matrix
seg_affineMat = segmentation_info.Transform.T;
seg_affineMat_scaling = [scale(1),0,0,0;
    0,scale(2),0,0;
    0,0,scale(3),0;
    0,0,0,1];
seg_affineMat_out = transpose(transpose(seg_affineMat) * seg_affineMat_scaling);

% smooth the mask of combined ROI: bone and cartilage mask
mask_BC_out = double(segmentation_out>0);
mask_BC_out_s = imgaussfilt3(mask_BC_out, maskSmoothing_gamma, "FilterDomain", "spatial")>threshold;

% -------------------------------
% Gaussian smoothing for each ROI
% -------------------------------
if ROISmoothing_gamma~=0
    % smoothing
    mask_s_segROIs = [];
    prop_segROIs = [];
    for i=label_tbs
        i_ROI = num2str(i);
        i_mask = double(segmentation_out==i);
        i_prop = imgaussfilt3(i_mask, ROISmoothing_gamma, "FilterDomain", "spatial");
        i_mask_s = i_prop>threshold;
        eval(append('mask_s_segROIs.x', i_ROI, '=i_mask_s;'));
        eval(append('prop_segROIs.x', i_ROI, '=i_prop;'));
    end
    % combine the smoothed masks
    segmentation_out_s = zeros(size(segmentation_out));
    mask_accumulated = zeros(size(segmentation_out));
    for j=label_tbs
        j_ROI = num2str(j);
        eval(append('j_mask_s=mask_s_segROIs.x', j_ROI, ';'))
        segmentation_out_s(j_mask_s) = j;
        mask_accumulated = mask_accumulated + j_mask_s;
    end
    % handle overlapped regions
    mask_overlap = mask_accumulated > 1;
    idx_overlap = find(mask_overlap);
    probMat = [];
    for k=label_tbs
        k_ROI = num2str(k);
        eval(append('k_prop=prop_segROIs.x', k_ROI, ';'));
        probMat = cat(2, probMat, k_prop(idx_overlap));
    end
    [~, idx_maxCol] = max(probMat,[], 2);
    for p=label_tbs
        p_ROI = num2str(p);
        eval(append('segmentation_out_s(idx_overlap(idx_maxCol==', p_ROI ,'))=', p_ROI, ';'));
    end
else
    segmentation_out_s = segmentation_out;
end
% -------------------------------

% remove file extension
[folder, tmp_fileName, tmp_ext] = fileparts(file_segmentation_out);
if strcmp(tmp_ext, ".gz")
    [~, fileName_woExt, ~] = fileparts(tmp_fileName);
else
    fileName_woExt = tmp_fileName;
end
file_segmentation_out_woExt = fullfile(folder, fileName_woExt);

% update header
segmentation_out_s_info = segmentation_info;
segmentation_out_s_info.Transform.T = seg_affineMat_out;
segmentation_out_s_info.Filename = file_segmentation_out_woExt;
segmentation_out_s_info.Datatype = class(segmentation_out_s);
segmentation_out_s_info.ImageSize = size(segmentation_out_s);
segmentation_out_s_info.Filemoddate = datetime;
segmentation_out_s_info.Filesize = [];
segmentation_out_s_info.PixelDimensions = voxelSize_out;
niftiwrite(segmentation_out_s, segmentation_out_s_info.Filename, segmentation_out_s_info, 'Compressed', true);
% =============================================================
