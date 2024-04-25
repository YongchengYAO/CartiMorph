function [neighFaces, n_neighFaces] = CM_cal_neighFaces4Edges(faces)
% ==============================================================================
% FUNCTION:
%     Get neighboring faces for each edge.
%
% INPUT:
%     - faces: (nf, 3), faces of the mesh
%
% OUTPUT:
%     - neighFaces: [cell], (n_edges, 1) neighboring faces for each edge
%     - n_neighFaces: (n_edges, 1) the number of neighboring faces for each edge
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

% get edges from faces (contains duplicated edges)
edges = sort(cat(1, faces(:,[1,2]), faces(:,[2,3]), faces(:,[3,1])), 2);

% keep track of faceIDs
numFaces = size(faces, 1);
faceIDs = repmat((1:numFaces)', 3, 1);

% remove duplicated edges
[edges_clean, ~, idx_clean] = unique(edges, 'rows');
numEdges = size(edges_clean, 1);

% find neighboring faces for each edge
neighFaces = cell(numEdges, 1);
n_neighFaces = zeros(numEdges, 1);

% [enable parallel computing if available]
if ~license('test', 'Distrib_Computing_Toolbox')
    % (without parallel computing)
    for i = 1:numEdges
        idx_neighFaces = idx_clean == i;
        neighFaces{i, 1} = faceIDs(idx_neighFaces);
        n_neighFaces(i, 1) = sum(idx_neighFaces);
    end
elseif isempty(gcp("nocreate"))
    % (same code with parallel computing)
    parpool;
    parfor i = 1:numEdges
        idx_neighFaces = idx_clean == i;
        neighFaces{i, 1} = faceIDs(idx_neighFaces); %#ok<*PFBNS>
        n_neighFaces(i, 1) = sum(idx_neighFaces);
    end
else
    % (same code with parallel computing)
    parfor i = 1:numEdges
        idx_neighFaces = idx_clean == i;
        neighFaces{i, 1} = faceIDs(idx_neighFaces); %#ok<*PFBNS>
        n_neighFaces(i, 1) = sum(idx_neighFaces);
    end
end

end