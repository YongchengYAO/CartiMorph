function img2d = CM_cal_slice3Dto2D(img3d, dim, idx_dim)
% ==============================================================================
% FUNCTION:
%     Extract one slice from a 3D array.
%
% INPUT:
%     - img3d: [uint8] 3D image
%     - dim: [uint8] the dimension to be sliced
%     - idx_dim: [uint16] the index of the selected slice
%
% OUTPUT:
%      - img2d: [uint8] 2D image
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

% sanity check
flag_inRange = (1<=idx_dim) & (idx_dim<=size(img3d, dim));
assert(flag_inRange, append('Error: "idx_dim" should be in the range of [1,', num2str(size(img3d,dim)), ']'))

%% Slice the 3d array and squeeze into 2d array
if dim == 1
    img2d = squeeze(img3d(idx_dim, :, :));
elseif dim == 2
    img2d = squeeze(img3d(:, idx_dim, :));
elseif  dim == 3
    img2d = squeeze(img3d(:, :, idx_dim));
end
end