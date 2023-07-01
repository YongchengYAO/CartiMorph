function SN_out = CM_cal_smoothSN(SN_in, vers_inter, n_neigh)
% ==============================================================================
% FUNCTION:
%     Spatial smoothing of SNs.
%
% INPUT:
%     - SN_in: (nv, 3), surface normal
%     - vers_inter: (nv, 3), voxel coordinates
%     - n_neigh: number of neighbors for spatial smoothing of SN
%
% OUTPUT:
%      - SN_out: (nv, 3), smoothed SNs
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

% smoothed surface normal
SN_out = zeros(size(SN_in));

% [enable parallel computing if available]
if isempty(gcp("nocreate"))
    % (without parallel computing)
    for i = 1:size(vers_inter, 1)
        % find the i-th voxel
        i_coor = vers_inter(i, :);
        % find neighbors of the i-th voxel and their SN
        [~, idx_neigh] = pdist2(vers_inter, i_coor, 'euclidean', 'Smallest', n_neigh);
        SN_neigh = SN_in(idx_neigh, :);
        % calculate the mean SN as the smoothed SN for this voxel
        mean_SN = mean(SN_neigh, 1);
        SN_out(i, :) = mean_SN ./ norm(mean_SN);
    end
else
    % (same code with parallel computing)
    parpool;
    parfor i = 1:size(vers_inter, 1)
        % find the i-th voxel
        i_coor = vers_inter(i, :);
        % find neighbors of the i-th voxel and their SN
        [~, idx_neigh] = pdist2(vers_inter, i_coor, 'euclidean', 'Smallest', n_neigh);
        SN_neigh = SN_in(idx_neigh, :);
        % calculate the mean SN as the smoothed SN for this voxel
        mean_SN = mean(SN_neigh, 1);
        SN_out(i, :) = mean_SN ./ norm(mean_SN);
    end
    delete(gcp);
end

end