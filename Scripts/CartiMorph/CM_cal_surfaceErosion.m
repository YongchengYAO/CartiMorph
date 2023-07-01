function faces_out = CM_cal_surfaceErosion(faces_in, iteration)
% ==============================================================================
% FUNCTION:
%     Apply surface/mesh erosion to a mesh.
%
% INPUT:
%     - faces_in: (nf_in, 3), the input faces
%     - iteration: iteration time for surface dilation
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
% edges and faces of the input faces
% (the following two matrixs are corresponding in rows)
% ----------------------------------------------------
% edges
edges_source = CM_cal_Faces2Edges(faces_in);
% neighboring faces for each edge
[neighFaces_source, n_neighFaces_source] = CM_cal_neighFaces4Edges(faces_in);
% ----------------------------------------------------


%% Find the first layer of faces to be deleted
[~, faces_tbd] = CM_cal_detectSurfaceBoundary(faces_in);
faces_tbd = MPT_remove_duplicated_triangles(faces_tbd);


%% Find other layers of faces to be deleted
faces_tbd_next = faces_tbd;
for i=1:iteration-1
    % detect surface edge of the mesh to be deleted
    [marginEdges_tbd, ~] = CM_cal_detectSurfaceBoundary(faces_tbd_next);

    % find faces to be deleted
    idx_candidateEdges = ismember(edges_source, marginEdges_tbd, 'rows') & n_neighFaces_source==2;
    neighFaces_candidates_cell = neighFaces_source(idx_candidateEdges, :);
    i_neighFacesID = unique(cell2mat(neighFaces_candidates_cell));
    faces_tbd_next = faces_in(i_neighFacesID, :);
    % (!!!important!!!) ---
    faces_tbd_next = MPT_remove_duplicated_triangles(faces_tbd_next);
    faces_tbd_next = MPT_remove_triangles(faces_tbd, faces_tbd_next, 'explicit');
    faces_tbd = cat(1, faces_tbd, faces_tbd_next);
    % (!!!important!!!) ---
end


%% Delete multiple layers of marginal faces
faces_out = MPT_remove_triangles(faces_tbd, faces_in, 'explicit'); % MeshProcessingToolbox

end