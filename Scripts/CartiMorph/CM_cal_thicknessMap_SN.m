function ThicknessMap = CM_cal_thicknessMap_SN(vers_inter, SN, FV_outer, depth)
% ==============================================================================
% FUNCTION:
%     SN-based thickness measurement.
%
% INPUT:
%     - vers_inter: (nv, 3), voxel coordinates
%     - SN: (nv, 3), surface normals
%     - FV_outer: [structure]
%          - FV_outer.vertices: the vertices on the outer boundary <<must be the coordinates of voxels>>
%          - FV_outer.faces: the faces on the outer boundary
%     - depth: the measuring depth
%
% OUTPUT:
%      - ThicknessMap
%
% External functions/toolbox:
%     - https://www.mathworks.com/matlabcentral/fileexchange/33073-triangle-ray-intersection
% ------------------------------------------------------------------------------
% Version:
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

% find 3 points for each triangular face
faces_outer = FV_outer.faces;
vers_outer = FV_outer.vertices;
p1 = vers_outer(faces_outer(:,1),:);
p2 = vers_outer(faces_outer(:,2),:);
p3 = vers_outer(faces_outer(:,3),:);

% SN based thickness measurement
ThicknessMap = cat(2, vers_inter, zeros(size(SN, 1), 1));

% [enable parallel computing if available]
if ~license('test', 'Distrib_Computing_Toolbox')
    % (without parallel computing)
    for i=1:size(SN,1)
        i_SN = SN(i, :);
        i_ver = vers_inter(i, :);
        [idx_intersect, ~, ~, ~, xcoor] = TriangleRayIntersection(i_ver, i_SN, p1, p2, p3, 'border', 'inclusive');
        intersections = unique(xcoor(idx_intersect, :), 'rows');
        if size(intersections,1)>0
            if size(intersections,1)==1
                distance = norm(i_ver - intersections);
            else
                % find the nearest intersection in the positive direction
                [~, idx_dest] = pdist2(intersections, i_ver, 'euclidean', 'Smallest', 1);
                destination = intersections(idx_dest, :);
                % calculate the thickness as the distance between i-th voxel and destination
                distance = norm(i_ver - destination);
            end
            if distance < depth
                ThicknessMap(i, 4) = distance;
            end
        end
    end
elseif isempty(gcp("nocreate"))
    % (same code with parallel computing)
    parpool;
    parfor i=1:size(SN,1)
        i_SN = SN(i, :);
        i_ver = vers_inter(i, :);
        [idx_intersect, ~, ~, ~, xcoor] = TriangleRayIntersection(i_ver, i_SN, p1, p2, p3, 'border', 'inclusive');
        intersections = unique(xcoor(idx_intersect, :), 'rows');
        if size(intersections,1)>0
            if size(intersections,1)==1
                distance = norm(i_ver - intersections);
            else
                % find the nearest intersection in the positive direction
                [~, idx_dest] = pdist2(intersections, i_ver, 'euclidean', 'Smallest', 1);
                destination = intersections(idx_dest, :);
                % calculate the thickness as the distance between i-th voxel and destination
                distance = norm(i_ver - destination);
            end
            if distance < depth
                ThicknessMap(i, 4) = distance;
            end
        end
    end
else
    % (same code with parallel computing)
    parfor i=1:size(SN,1)
        i_SN = SN(i, :);
        i_ver = vers_inter(i, :);
        [idx_intersect, ~, ~, ~, xcoor] = TriangleRayIntersection(i_ver, i_SN, p1, p2, p3, 'border', 'inclusive');
        intersections = unique(xcoor(idx_intersect, :), 'rows');
        if size(intersections,1)>0
            if size(intersections,1)==1
                distance = norm(i_ver - intersections);
            else
                % find the nearest intersection in the positive direction
                [~, idx_dest] = pdist2(intersections, i_ver, 'euclidean', 'Smallest', 1);
                destination = intersections(idx_dest, :);
                % calculate the thickness as the distance between i-th voxel and destination
                distance = norm(i_ver - destination);
            end
            if distance < depth
                ThicknessMap(i, 4) = distance;
            end
        end
    end
end

end