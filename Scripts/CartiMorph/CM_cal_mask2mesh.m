function FV = CM_cal_mask2mesh(mask3d)
% ==============================================================================
% FUNCTION:
%     Surface reconstruction for a 3D ROI.
%
% INPUT:
%     - mask3d: [uint8] a 3D mask
%
% OUTPUT:
%     - FV: [structure]
%         - FV.faces: size=[nf, 3], the faces on the boundary
%         - FV.vertices: size=[nv, 3], the vertices on the boundary
%
% <<< Caution <<<
% (tested on Matlab 2021b (release 3))
% The build-in function "isosurface" returns (x,y) coordinates
% Other build-in functions in matlab may return (row, column) coordinates
% >>> Caution >>>
%
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 02-Jun-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================

% get triangular mesh for the boundary of the ROI
FV = isosurface(~mask3d, 0);

% change the orientation: the "isosurface" function have swap the first two dimensions
tmp = FV.vertices;
FV.vertices(:,2) = tmp(:,1);
FV.vertices(:,1) = tmp(:,2);

% vertices positions should represent the subscripts of voxels
subs = round(FV.vertices);
faces = FV.faces;

% remove duplicated vertices
[subs, faces] = MPT_remove_duplicated_vertices(subs, faces); % MeshProcessingToolbox

% remove unreferenced vertices
[subs, faces] = MPT_remove_unreferenced_vertices(subs, faces); % MeshProcessingToolbox

% save vertices and faces
FV.faces = faces;
FV.vertices = subs;

end
