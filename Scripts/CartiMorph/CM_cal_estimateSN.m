function SN = CM_cal_estimateSN(vers_voxels, n_neigh)
% ==============================================================================
% FUNCTION:
%     Surface normals estimation.
%
% INPUT:
%     - coor_voxels: (nv, 3), voxel coordinates
%     - n_neigh: number of neighbors to estimate surface normal for a voxel
%
% OUTPUT:
%      - SN: (nv, 3), the estimated SNs
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 11-May-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================

n_voxels = size(vers_voxels, 1); % number of vertices
SN = zeros(n_voxels, 3); % unit surface normal

% [enable parallel computing if available]
if ~license('test', 'Distrib_Computing_Toolbox')
    % (without parallel computing)
    for i = 1:n_voxels
        % get the coordinates of the i-th voxel
        i_vox = vers_voxels(i, :);
        % find the neighbors of the i-th voxel
        [~, idx_neigh] = pdist2(vers_voxels, i_vox, 'euclidean', 'Smallest', n_neigh);
        % get the coordinates of neighbors and the i-th voxel
        i_pool = vers_voxels(idx_neigh, :);
        % estimate the surface normal
        i_pool_centered = i_pool - mean(i_pool, 1);
        [~, ~, V] = svd(i_pool_centered, 0);
        i_SN = V(:, end);
        % get unit surface normal
        SN(i, :) = i_SN ./ norm(i_SN);
    end
elseif isempty(gcp("nocreate"))
    % (same code with parallel computing)
    parpool;
    parfor i = 1:n_voxels
        % get the coordinates of the i-th voxel
        i_vox = vers_voxels(i, :);
        % find the neighbors of the i-th voxel
        [~, idx_neigh] = pdist2(vers_voxels, i_vox, 'euclidean', 'Smallest', n_neigh);
        % get the coordinates of neighbors and the i-th voxel
        i_pool = vers_voxels(idx_neigh, :);
        % estimate the surface normal
        i_pool_centered = i_pool - mean(i_pool, 1);
        [~, ~, V] = svd(i_pool_centered, 0);
        i_SN = V(:, end);
        % get unit surface normal
        SN(i, :) = i_SN ./ norm(i_SN);
    end
else
    % (same code with parallel computing)
    parfor i = 1:n_voxels
        % get the coordinates of the i-th voxel
        i_vox = vers_voxels(i, :);
        % find the neighbors of the i-th voxel
        [~, idx_neigh] = pdist2(vers_voxels, i_vox, 'euclidean', 'Smallest', n_neigh);
        % get the coordinates of neighbors and the i-th voxel
        i_pool = vers_voxels(idx_neigh, :);
        % estimate the surface normal
        i_pool_centered = i_pool - mean(i_pool, 1);
        [~, ~, V] = svd(i_pool_centered, 0);
        i_SN = V(:, end);
        % get unit surface normal
        SN(i, :) = i_SN ./ norm(i_SN);
    end
end

end