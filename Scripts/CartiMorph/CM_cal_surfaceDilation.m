function faces_out = CM_cal_surfaceDilation(...
    faces_in,...
    faces_source,...
    iteration)
% ==============================================================================
% FUNCTION:
%     Apply surface/mesh dilation to a mesh.
%
% INPUT:
%     - faces_in: (nf_in, 3), the input faces
%     - faces_source: (nf, 3), the faces of source mesh
%     - iteration: iteration time for surface dilation
%     (Note 1) faces_source and faces_in must base on the same vertices matrix
%
% OUTPUT:
%     - faces_out: (nf_out, 3), the ouput faces
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

%% Define searching space
% edges and faces in the seaching space
% (the following two matrixs are corresponding in rows)
% ----------------------------------------------------
% edges
edges_source = CM_cal_Faces2Edges(faces_source);
% neighboring faces for each edge
[neighFaces_source, ~] = CM_cal_neighFaces4Edges(faces_source);
% ----------------------------------------------------

%% Find the first layer of faces to be added
% detect surface edge of the input mesh
[marginEdges_in, ~] = CM_cal_detectSurfaceBoundary(faces_in);

% find faces to be added to the edge of input mesh
faces_tba_cell = neighFaces_source(ismember(edges_source, marginEdges_in, 'rows'), :);
i_neighFacesID = unique(cell2mat(faces_tba_cell));
faces_tba = faces_source(i_neighFacesID, :);

% (!!!important!!!) ---
faces_tba = MPT_remove_triangles(faces_in, faces_tba, 'explicit'); % MeshProcessingToolbox
% (!!!important!!!) ---

%% Find more layers of faces to be added
for i=1:iteration-1
    % detect surface edge of the input mesh
    [marginEdges_tba, ~] = CM_cal_detectSurfaceBoundary(faces_tba);

    % find faces to be added to the edge of input mesh
    faces_tba_cell = neighFaces_source(ismember(edges_source, marginEdges_tba, 'rows'), :);
    i_neighFacesID = unique(cell2mat(faces_tba_cell));
    faces_tba_next = faces_source(i_neighFacesID, :);
    faces_tba = cat(1, faces_tba, faces_tba_next);

    % (!!!important!!!) ---
    faces_tba = MPT_remove_duplicated_triangles(faces_tba); % MeshProcessingToolbox
    faces_tba = MPT_remove_triangles(faces_in, faces_tba, 'explicit'); % MeshProcessingToolbox
    % (!!!important!!!) ---
end

%% Add faces to the edge of input mesh
faces_out = cat(1, faces_in, faces_tba);
end