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
dir_info_out = "path/to/output/info/folder";
% =============================================================


% -----------------------
% project-specific settings
% -----------------------
% size of the low-resolution images after [cropping and auto-resampling]
% [cropping and auto-resampling] take place in function CM_imgPreprocess_mdcn()
config_imgSize_out = [64, 128, 128];

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

% estimate knee joint info
kneeJointInfo_Tr = CM_estKneeJointSize(dir_seg_in, config_ROI_label, config_ROI_name);

% save knee joint info
path_kneeJointInfo_Tr = fullfile(dir_info_out, "kneeJointInfo_Tr.mat");
save(path_kneeJointInfo_Tr, '-struct', "kneeJointInfo_Tr");

% ---------------------------------------------------------------------------
% image preprocessing 
% ---------------------------------------------------------------------------
% [option 1] fixed downsampling factor: masking, downsampling, cropping, image intensity normalization
cropRange_Tr = CM_imgPreprocess_mdcn_fixDownFactor(dir_seg_in, dir_img_in, dir_seg_out, dir_img_out,...
    config_imgSize_out, kneeJointInfo_Tr, 2);

% % [option 2] automatic downsampling factor: masking, downsampling, cropping, image intensity normalization
% cropRange_Tr = CM_imgPreprocess_mdcn(dir_seg_in, dir_img_in, dir_seg_out, dir_img_out,...
%     config_imgSize_out, kneeJointInfo_Tr, 4);
% ---------------------------------------------------------------------------

% save cropping range (in the downsampled image)
path_cropRange_Tr = fullfile(dir_info_out, "cropRange_Tr.mat");
save(path_cropRange_Tr, '-struct', "cropRange_Tr");
