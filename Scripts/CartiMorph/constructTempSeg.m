clc;
clear;

% =============================================
% modify this part only
% =============================================
% folder of the output segmentation masks warpped to the template image space
dir_warppedLabels = 'path/to/warpped/segmentations';
% path to template image
path_vxm_template = "path/to/template/template.nii.gz";
% paht to template segmentation
path_vxm_data_Template = "path/to/template/segmentation/templateSeg.nii.gz";
% =============================================


% -----------------------
% project-specific settings
% -----------------------
config_imgSize_out = [64, 128, 128];
config_ROI_label = {'0', '1', '2', '3', '4', '5'};
% -----------------------

% construct probability map
tmp = [dir(fullfile(dir_warppedLabels, "*.nii.gz"));...
    dir(fullfile(dir_warppedLabels, "*.nii"))];
list_warppedLabel = {tmp.name}';
tempProbMap = zeros(cat(2, config_imgSize_out, length(config_ROI_label)), "double");
for j=1:length(list_warppedLabel)
    j_warppedLabel = niftiread(fullfile(dir_warppedLabels, list_warppedLabel{j}));
    for k=1:length(config_ROI_label)
        tempProbMap(:,:,:,k) = tempProbMap(:,:,:,k) + double(j_warppedLabel==k-1);
    end
end
tempProbMap = tempProbMap ./ length(list_warppedLabel);

% construct and save the segmentation mask for the template
[~, vxm_tempSeg] = max(tempProbMap, [], 4);
vxm_tempSeg = uint8(vxm_tempSeg-1);
vxm_tempInfo = niftiinfo(path_vxm_template);
vxm_tempSegInfo = vxm_tempInfo;
vxm_tempSegInfo.Description = char("segmentation mask for the learned template");
vxm_tempSegInfo.Datatype = class(vxm_tempSeg);
vxm_tempSegInfo.Filemoddate = regexprep(char(datetime), ' ', '_');
vxm_tempSegInfo.Filename = path_vxm_data_Template;
vxm_tempSegInfo.Filesize = [];
niftiwrite(vxm_tempSeg, vxm_tempSegInfo.Filename, vxm_tempSegInfo, "Compressed",true);
