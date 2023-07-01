function  boundary = CM_cal_getBoundary2D(img3d, idx_slicingDim)
% ==============================================================================
% FUNCTION:
%     Returns the boundary of a 3D ROI.
%
% INPUT:
%     - img3d: [uint8] 3D ROI - a binary 3D image
%     - idx_slicingDim: [uint8] the dimension to be sliced
%
% OUTPUT:
%     - boundary: [uint8] the boundary of 3D ROI - a binary 3D image
%
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 09-May-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================

%% Get indices of slices
size_seg = size(img3d);
idx_seg = find(img3d);
[sub1_seg, sub2_seg, sub3_seg] = ind2sub(size_seg, idx_seg);
switch idx_slicingDim
    case 1
        idx_Slices = sort(unique(sub1_seg));
    case 2
        idx_Slices = sort(unique(sub2_seg));
    case 3
        idx_Slices = sort(unique(sub3_seg));
end

%% Get the boundary for each slice
boundary = zeros(size_seg, 'uint8');
for i=1:length(idx_Slices)
    % get the i-th slice
    i_idx = idx_Slices(i);
    i_slice = CM_cal_slice3Dto2D(img3d, idx_slicingDim, i_idx);  % uint8
    % get boundary for the i-th slice (conn=4, pixels are connected if their edges touch)
    i_boundary = bwperim(i_slice, 4);
    % save the boundary in 3D array
    switch idx_slicingDim
        case 1
            boundary(i_idx, :, :) = i_boundary;
        case 2
            boundary(:, i_idx, :) = i_boundary;
        case 3
            boundary(:, :, i_idx) = i_boundary;
    end
end
end