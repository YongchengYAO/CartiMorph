function [tgl_idx_list] = MPT_find_triangles_from_vertex_list(T, vtx_idx)
%% find_triangles_from_vertex_list : function to compute the index
% list of triangles containing the vertex indices of vtx_idx.
%
% Author & support : nicolas.douillet (at) free.fr, 2020.
%
%
% Input arguments
%
%       [|  |  | ]
% - T = [i1 i2 i3], positive integer matrix double, the triangulation, size(T) = [nb_triangles,3].
%       [|  |  | ]
%
% - vtx_idx : positive integer row vector double, the vertex indices list.
%
%
% Output argument
%
% - tgl_idx_list : positive integer row vector double, the triangle indices list.

tgl_idx_list = find(sum(reshape(ismember(T(:),vtx_idx),[size(T,1),size(T,2)]),2));
end