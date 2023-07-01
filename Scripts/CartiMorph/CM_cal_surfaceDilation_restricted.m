function faces_out = CM_cal_surfaceDilation_restricted(...
    faces_in,...
    faces_source,...
    vers_source,...
    vers_border)
% ==============================================================================
% FUNCTION:
%     Apply restricted surface/mesh dilation to a mesh.
%
% INPUT:
%     - faces_in: (nf_in, 3), the input faces
%     - faces_source: (nf, 3), the faces of source mesh
%     - vers_source: (nv, 3), the vertices of source mesh
%     - vers_border: (nv_border, 3), the vertices on border of dilation space
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
% delete duplicated faces
faces_in = MPT_remove_duplicated_triangles(faces_in);
% detect surface edge of the input mesh
[marginEdges_in, ~] = CM_cal_detectSurfaceBoundary(faces_in);

% find faces to be added to the edge of input mesh
faces_tba_cell = neighFaces_source(ismember(edges_source, marginEdges_in, 'rows'), :);
i_neighFacesID = unique(cell2mat(faces_tba_cell));
faces_tba = faces_source(i_neighFacesID, :);

% (!!!important!!!) ---
faces_tba = MPT_remove_triangles(faces_in, faces_tba, 'explicit'); % MeshProcessingToolbox
% (!!!important!!!) ---

% faces that reach the dilation border will not be added
idx_border = ismember(vers_source, vers_border, 'rows');
versID_source = transpose(1:size(vers_source,1));
versID_border = versID_source(idx_border);
idx_exclude = sum(ismember(faces_tba, versID_border), 2)>=1;
faces_tba(idx_exclude, :) = [];


%% Find more layers of faces to be added
flag_continue = true;
if ~isempty(faces_tba)
    while flag_continue
        % detect surface edge of the input mesh
        [marginEdges_tba, ~] = CM_cal_detectSurfaceBoundary(faces_tba);

        % find faces to be added to the edge of input mesh
        faces_tba_cell = neighFaces_source(ismember(edges_source, marginEdges_tba, 'rows'), :);
        i_neighFacesID = unique(cell2mat(faces_tba_cell));
        faces_tba_next = faces_source(i_neighFacesID, :);
        % (!!!important!!!) ---
        faces_tba_next = MPT_remove_triangles(faces_in, faces_tba_next, 'explicit'); % MeshProcessingToolbox
        faces_tba_next = MPT_remove_triangles(faces_tba, faces_tba_next, 'explicit'); % MeshProcessingToolbox
        idx_exclude = sum(ismember(faces_tba_next,versID_border), 2)>=1;
        faces_tba_next(idx_exclude, :) = [];
        % (!!!important!!!) ---
        faces_tba = cat(1, faces_tba, faces_tba_next);

        % stop surface dilation if no more faces can be added
        if isempty(faces_tba_next)
            flag_continue = false;
        end
    end
end


%% Add faces to the edge of input mesh
faces_out = cat(1, faces_in, faces_tba);

end