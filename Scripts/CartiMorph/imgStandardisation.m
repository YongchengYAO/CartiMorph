clear;
clc;

% =============================================================
% modify this part only
% =============================================================
% input folder
dir_img_in = "path/to/input/image/folder";
dir_seg_in = "path/to/input/segmentation/folder";
% output folder
dir_img_out = "path/to/output/image/folder";
dir_seg_out = "path/to/output/segmentation/folder";
% =============================================================


% -----------------------
% project-specific settings
% -----------------------
% image size of the OAIZIB dataset
config_imgSize_out = [160, 384, 384];

config_ROI_label = {'0', '1', '2', '3', '4', '5'};
config_ROI_name = {'background', 'femur', 'femoral cartilage',...
    'tibia', 'medial tibial cartilage', 'lateral tibial cartilage'};
% -----------------------

% make directories
if ~isfolder(dir_img_out)
    mkdir(dir_img_out);
end
if ~isfolder(dir_seg_out)
    mkdir(dir_seg_out);
end
if ~isfolder(dir_info_out)
    mkdir(dir_info_out);
end

% image standardisation
CM_imgStandardisation(dir_img_in, dir_img_out, config_imgSize_out, true);
% segmentation standardisation
CM_imgStandardisation(dir_seg_in, dir_seg_out, config_imgSize_out, false);
