% % ------------------------------------
% This script only works for specific study.
%
% Dataset: OAI-ZIB
% Data conversion history:
% 1. download images in DICOM, convert DICOM to .nii.gz
% 2. convert segmentation mask in .mhd/.raw to .nii.gz using python script "raw2nii.py"
% 3. modify the data array and header of segmentation mask in .nii.gz to match
%    that of corresponding image
% ------------------------------------

clear;
clc;

% =============================================================
% modify this part only
% =============================================================
% set paths
path_img = "path/to/image/nii";
path_seg = "path/to/segmentation/nii";
path_seg_out = "path/to/corrected-segmentation/nii";
% =============================================================

if ~exist(path_seg_out, 'dir')
    mkdir(path_seg_out);
end

list_img = dir(fullfile(path_img, '*.nii.gz'));
n_img = length(list_img);

for i = 1: n_img
    i_fileName_ext = list_img(i).name;
    i_fileName = i_fileName_ext(1:end-7);

    i_info_img = niftiinfo(fullfile(path_img, i_fileName_ext));
    i_info_seg = niftiinfo(fullfile(path_seg, i_fileName_ext));
    i_vol_seg = niftiread(i_info_seg);
    i_path_out = fullfile(path_seg_out, i_fileName);

    % flip data array of the segmentation mask and modify the affine matrix
    i_affineMat_img = i_info_img.Transform.T;
    i_affineMat_seg = i_info_seg.Transform.T;
    i_diag_img = diag(i_affineMat_img(1:3, 1:3));
    i_diag_seg = diag(i_affineMat_seg(1:3, 1:3));
    i_orientation_img = i_diag_img>0;
    i_orientation_seg = i_diag_seg>0;
    idx_flipDim = ~(i_orientation_img == i_orientation_seg);
    if idx_flipDim(1)
        i_vol_seg = flip(i_vol_seg, 1);
    end
    if idx_flipDim(2)
        i_vol_seg = flip(i_vol_seg, 2);
    end
    if idx_flipDim(3)
        i_vol_seg = flip(i_vol_seg, 3);
    end

    % modify header & save to .nii.gz
    i_info_seg_new = i_info_img;
    i_info_seg_new.Description = 'segmantation mask with corrected affine matrix as image file';
    i_info_seg_new.Datatype = 'uint8';
    i_info_seg_new.BitsPerPixel = 8;
    i_info_seg_new.Filename = i_path_out;
    i_info_seg_new.Filemoddate = datetime;
    i_info_seg_new.Filesize = [];
    niftiwrite(i_vol_seg, i_path_out, i_info_seg_new, 'Compressed', true);
end
