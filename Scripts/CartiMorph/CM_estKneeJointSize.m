function joint_info = CM_estKneeJointSize(dir_seg, config_ROI_label, config_ROI_name)
% get list of segmentatoin masks
tmp = [dir(fullfile(dir_seg, "*.nii.gz"));dir(fullfile(dir_seg, "*.nii"))];
filename = {tmp.name}';
numCase = size(filename, 1);

% get the size and center of whole knee joint
size_joint = zeros(numCase, 3);
center_joint = zeros(numCase, 3);

for i=1:numCase
    % read NIfTI
    i_Name = filename{i,:};
    i_segPath = fullfile(dir_seg, i_Name);
    i_segVol = niftiread(i_segPath);

    % get the segmentation mask for the whole knee joint
    label_FC = str2double(config_ROI_label{strcmpi(config_ROI_name, 'femoral cartilage')});
    label_mTC = str2double(config_ROI_label{strcmpi(config_ROI_name, 'medial tibial cartilage')});
    label_lTC = str2double(config_ROI_label{strcmpi(config_ROI_name, 'lateral tibial cartilage')});
    mask_joint = uint8(i_segVol==label_FC | i_segVol==label_mTC | i_segVol==label_lTC);

    % remove cluster less than 10 voxels
    tmp = bwareaopen(mask_joint, 10, 26);  % conn=26
    mask_joint = uint8(imfill(tmp, 6, 'holes'));  % conn=6

    % find knee joint
    imgSize = size(mask_joint);
    [x_range, y_range, z_range] = ind2sub(imgSize, find(mask_joint)) ;
    dLR = [min(x_range), max(x_range)];  % L-R distance
    dPA = [min(y_range), max(y_range)];  % P-A distance
    dIS = [min(z_range), max(z_range)];  % I-S distance
    x_center = round((dLR(1) + dLR(2)) / 2);
    y_center = round((dPA(1) + dPA(2)) / 2);
    z_center = round((dIS(1) + dIS(2)) / 2);
    center_joint(i, :) = [x_center, y_center, z_center];
    size_joint(i, :) = [dLR(2)-dLR(1), dPA(2)-dPA(1), dIS(2)-dIS(1)] + 1;
end

% gather knee joint info
joint_info.center = center_joint;
joint_info.size = size_joint;
joint_info.filename = filename;
end