function [faces_filled, vers_filled, faces_filling, vers_filling] = CM_cal_reconCartDefect_conn(...
    faces_inter, ...
    FV_bone)
% ==============================================================================
% FUNCTION:
%     Full-thickness cartilage defect reconstruction (step 1).
%
% INPUT:
%     - faces_inter: (nf_in, 3), faces of the bone-cartilage interface
%     - FV_bone: the bone surface
%
% OUTPUT:
%     - faces_filled: (nf_filled, 3), faces of the filled surface
%     - vers_filled: (nv_filled, 3), vertices of the filled surface
%     - faces_filling: (nf_filling, 3), faces of the filling surface
%     - vers_filling: (nv_filling, 3), vertices of the filling surface
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


%% Find filling components
% bone vertices and faces
vers_bone = FV_bone.vertices;
faces_bone = FV_bone.faces;
% remove interface mesh from the bone mesh (MeshProcessingToolbox)
faces_nonInter = MPT_remove_triangles(faces_inter, faces_bone, 'explicit');
% remove large components from the non-interface mesh (MeshProcessingToolbox)
[~, components_nonInter] = MPT_segment_connected_components(faces_nonInter, 'explicit');
faces_filling = CM_cal_deleteLargeComponents(components_nonInter, 50);


%% Add filling mesh to the interface mesh
% add filling mesh
faces_filled  = cat(1, faces_inter, faces_filling);
% remove duplicated faces (MeshProcessingToolbox)
faces_filled = MPT_remove_duplicated_triangles(faces_filled);
% remove unreferenced vertices (MeshProcessingToolbox)
[vers_filled, faces_filled] = MPT_remove_unreferenced_vertices(vers_bone, faces_filled);


%% Update the mesh of filling components
if ~isempty(faces_filling)
    % remove duplicated faces (MeshProcessingToolbox)
    faces_filling = MPT_remove_duplicated_triangles(faces_filling);
    % remove unreferenced vertices (MeshProcessingToolbox)
    [vers_filling, faces_filling] = MPT_remove_unreferenced_vertices(vers_bone, faces_filling);
else
    vers_filling = [];
end

end