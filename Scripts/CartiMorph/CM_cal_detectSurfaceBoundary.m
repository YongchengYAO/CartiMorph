function [marginEdges, marginFaces] = CM_cal_detectSurfaceBoundary(faces_in)
% ==============================================================================
% FUNCTION:
%
% INPUT:
%     - faces_in: (nf_in, 3), the input faces
%
% OUTPUT:
%     - marginEdges: size=[ne, 2], the edge of the surface boundary
%     - marginFaces: size=[nf, 3], the marginal faces
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


% (the following two matrixs are corresponding in rows)
% ----------------------------------------------------
% get edges from faces
edges = CM_cal_Faces2Edges(faces_in);
% find neighboring faces for each edge
[neighFaces_cell, n_neighFaces] = CM_cal_neighFaces4Edges(faces_in);
% ----------------------------------------------------

% find edges with only one adjacent face
idx_marginEdges = n_neighFaces==1;
marginEdges = edges(idx_marginEdges, :);

% find faces on the edge
idx_marginFaces = cell2mat(neighFaces_cell(idx_marginEdges));
marginFaces = faces_in(idx_marginFaces, :);

end