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

% output files
path_kneeJointInfo = "path/to/kneeJointInfo.mat";
path_imgPreInfo = "path/to/imgPreInfo.mat";

% size of the low-resolution images after [resampling and cropping]
config_imgSize_out = [64, 128, 128];

% downsampling option: 'fixed' or 'automatic'
%   - 'fixed': fix downsampling factor
%   - 'automatic': automatic downsampling factor
opt_downMode = 'fixed';

% fixed downsampling factor, used in the 'fixed' mode only
%   - opt_downFactor>1 means downsampling
%   - opt_downFactor<1 means upsampling
opt_downFactor = 2;

% padding, used in the 'automatic' mode only
%   - it controls the margins surrounding the bounding box of ROIs (FC & TC)
opt_padding = 4;
% =============================================================


% -----------------------
% project-specific settings
% -----------------------
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

% estimate knee joint info
kneeJointInfo = CM_estKneeJointSize(dir_seg_in, config_ROI_label, config_ROI_name);

% save knee joint info
save(path_kneeJointInfo, '-struct', "kneeJointInfo");

% ---------------------------------------------------------------------------
% image preprocessing 
% ---------------------------------------------------------------------------
switch opt_downMode
    case "fixed"
        % [option 1] fixed downsampling factor: masking, downsampling, cropping, image intensity normalization
        imgPreInfo = CM_imgPreprocess_mdcn_fixedDownFactor(dir_seg_in, dir_img_in, dir_seg_out, dir_img_out,...
                        config_imgSize_out, kneeJointInfo, opt_downFactor);
    case "automatic"
        % [option 2] automatic downsampling factor: masking, downsampling, cropping, image intensity normalization
        imgPreInfo = CM_imgPreprocess_mdcn(dir_seg_in, dir_img_in, dir_seg_out, dir_img_out,...
                        config_imgSize_out, kneeJointInfo, opt_padding);
end
% ---------------------------------------------------------------------------

% save cropping range (in the downsampled image)
save(path_imgPreInfo, '-struct', "imgPreInfo");
