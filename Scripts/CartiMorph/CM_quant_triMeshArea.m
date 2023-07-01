function facesArea = CM_quant_triMeshArea(vertices, faces)
% ==============================================================================
% FUNCTION:
%     Calculate area of triangular mesh.
%
% INPUT:
%     -
%
% OUTPUT:
%     -
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 18-May-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================

vector1 = vertices(faces(:, 2), :) - vertices(faces(:, 1), :);
vector2 = vertices(faces(:, 3), :) - vertices(faces(:, 1), :);
crossV1V2 = cross(vector1, vector2, 2);
facesArea = 0.5 * vecnorm(crossV1V2, 2, 2);
end