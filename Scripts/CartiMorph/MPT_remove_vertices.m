function [V_out, T_out] = MPT_remove_vertices(V_set, V_in, T_in, mode)
%% remove_vertices : function to remove vertices from the vertex set.
%
% Author & support : nicolas.douillet (at) free.fr, 2020.
%
%
% Input arguments
%
%           [| | |]
% - V_set = [X Y Z], real matrix double, the vertex set to remove, size(V_set) = [nb_new_vertices,3],
%           [| | |]
%                    or positive integer row vector double, the index list of the vertices to remove.
%
%          [ |    |    |  ]
% - V_in = [X_in Y_in Z_in], real matrix double, the input point set, size(V_in) = [nb_input_vertices,3].
%          [ |    |    |  ]
%
%          [  |     |     |  ]
% - T_in = [i1_in i2_in i3_in], positive integer matrix double, the input triangulation, size(T_in) = [nb_input_triangles,3].
%          |  |     |     |  ]
%
% - mode : character string in the set {'indices','explicit','INDICES','EXPLICIT'}. Explicit mode corresponds to the
%          case where V_set is made of vertices [X Y Z] coordinates. Case insensitive.
%
%
% Output arguments
%
%           [  |     |     |  ]
% - V_out = [X_out Y_out Z_out], real matrix double, the output point set, size(V_out) = [nb_output_vertices,3],
%           [  |     |     |  ]
%
%           with nb_output_vertices = nb_input_vertices + nb_new_vertices.
%
%           [  |      |      |   ]
% - T_out = [i1_out i2_out i3_out], positive integer matrix double, the output triangulation, size(T_out) = [nb_output_triangles,3].
%           [  |      |      |   ]

if nargin  < 4
    mode = 'indices';
else
    assert((strcmpi(mode,'indices') && ismember(1,size(V_set))) || (strcmpi(mode,'explicit') && size(V_set,2) == 3),...
        'mode value must be either set to ''indices'' with V_set a one row/column indices vector or to ''explicit'' with size(V_set,2) = 3.');
end

V_out = V_in;
T_out = T_in;

if strcmpi(mode,'indices') && ismember(1,size(V_set)) || nargin < 4
    vtx_idx_2_suppr = V_set;
elseif strcmpi(mode,'explicit') && size(V_set,2) == 3
    vtx_idx_2_suppr = ismember(V_in,V_set,'rows');
end

% I Suppress vertices & triangles
V_out(vtx_idx_2_suppr,:) = [];
tgl_idx_2_suppr = MPT_find_triangles_from_vertex_list(T_in,vtx_idx_2_suppr);
T_out(tgl_idx_2_suppr,:) = [];

% II Reindex triangulation
keep_idx = setdiff(1:size(V_in,1),vtx_idx_2_suppr); % what V_out indices are relatively to V_in ones
M = containers.Map(keep_idx,1:size(V_out,1));
T_suppr_idx = isKey(M,num2cell(T_out));
T_out(T_suppr_idx) = cell2mat(values(M,num2cell(T_out(T_suppr_idx))));
end