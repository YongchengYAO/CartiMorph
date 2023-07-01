function edges = CM_cal_Faces2Edges(faces)
% ==============================================================================
% FUNCTION:
%     Get edges from triangular faces.
%
% INPUT:
%     - faces: (nf, 3), faces of the mesh
%
% OUTPUT:
%     - edges: (ne, 2), edges of the mesh
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

edges = sort([faces(:,[1 2]) ; faces(:,[2 3]) ; faces(:,[3 1])], 2);
edges = unique(edges, 'rows');

end