function SN_out = CM_cal_reorientSN(...
    SN_in,...
    vers_inter,...
    vers_outer,...
    size_voxel,...
    n_neigh)
% ==============================================================================
% FUNCTION:
%     Reorient surface normals so that they point from inner to outer surface.
%
% INPUT:
%     - SN_in: (nv, 3), input unit surface normals
%     - vers_inter: (nv, 3), vertices on the bone-cartilage interface
%     - vers_outer: (nv, 3), vertices on the outer cartilage surface
%     - size_voxel: voxel size
%     - n_neigh: number of neighbors
%
% OUTPUT:
%      - SN_out: (nv, 3), the orientation-corrected SNs
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



%% Step 1: flip SN if it is getting far away from the outer boundary
% ------------------------------------------------------------------------------------------
% remove duplicated vertices from the outer boundary
vers_outer = vers_outer(~ismember(vers_outer, vers_inter, 'rows'), :);

% scaling
SN_scaled = SN_in .* min(size_voxel);

% orientation correction
SN_f1 = zeros(size(SN_in));

% [enable parallel computing if available]
if isempty(gcp("nocreate"))
    % (without parallel computing)
    for i = 1:size(SN_in, 1)
        i_SN = SN_scaled(i, :);
        i_ver = vers_inter(i, :);
        i_endPoint_SN = i_ver + i_SN;
        i_endPoint_fSN = i_ver - i_SN;
        [i_distance_endPoint_SN, ~] = pdist2(vers_outer, i_endPoint_SN, 'euclidean', 'Smallest', 1);
        [i_distance_endPoint_fSN, ~] = pdist2(vers_outer, i_endPoint_fSN, 'euclidean', 'Smallest', 1);
        if i_distance_endPoint_SN > i_distance_endPoint_fSN
            SN_f1(i, :) = -i_SN;
        else
            SN_f1(i, :) = i_SN;
        end
    end
else
    % (same code with parallel computing)
    parpool;
    parfor i = 1:size(SN_in, 1)
        i_SN = SN_scaled(i, :);
        i_ver = vers_inter(i, :);
        i_endPoint_SN = i_ver + i_SN;
        i_endPoint_fSN = i_ver - i_SN;

        [i_distance_endPoint_SN, ~] = pdist2(vers_outer, i_endPoint_SN, 'euclidean', 'Smallest', 1);
        [i_distance_endPoint_fSN, ~] = pdist2(vers_outer, i_endPoint_fSN, 'euclidean', 'Smallest', 1);

        if i_distance_endPoint_SN > i_distance_endPoint_fSN
            SN_f1(i, :) = -i_SN;
        else
            SN_f1(i, :) = i_SN;
        end
    end
    delete(gcp);
end
% ------------------------------------------------------------------------------------------



%% Step 2: majority voting - flip the SN if the majority of its neighbors are in opposite direction
% ------------------------------------------------------------------------------------------
% get all non-zero SNs
SN_nonZero = SN_f1(~ismember(SN_f1, [0, 0, 0], 'row'), :);

% get coordinates of voxels with non-zero estimated SN
coor_nonZeroSN = vers_inter(~ismember(SN_f1, [0, 0, 0], 'row'), :);

% orientation correction
SN_f2 = zeros(size(SN_f1));
for j = 1:size(SN_f1,1)
    j_SN = SN_f1(j,:);
    j_ver = vers_inter(j, :);

    if ~isequal(j_SN, [0,0,0])
        % find neighbors of the i-the vertex
        [~, idx_neigh] = pdist2(coor_nonZeroSN, j_ver, 'euclidean', 'Smallest', n_neigh);
        j_SN_f1_neigh = SN_nonZero(idx_neigh, :);

        % majority voting: flip the SN if the majority of its neighbors are in opposite direction
        inner_product = dot(repmat(j_SN, n_neigh, 1), j_SN_f1_neigh, 2);
        num_sameOrientation = sum(inner_product>0) - 1; % exclude the i-th SN itself
        if num_sameOrientation > floor((n_neigh-1)/2)
            SN_f2(j,:) = j_SN;
        else
            SN_f2(j,:) = -j_SN;
        end
    end
end
% ------------------------------------------------------------------------------------------

SN_out = SN_f2;

end