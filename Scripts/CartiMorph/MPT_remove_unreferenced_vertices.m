function [V_out, T_out] = MPT_remove_unreferenced_vertices(V_in, T_in)
%% remove_unreferenced_vertices : function to remove vertices
% which are not referenced in the triangulation.
%
% Author & support : nicolas.douillet (at) free.fr, 2020.
%
%
% Input arguments
%
%          [ |    |    |  ]
% - V_in = [X_in Y_in Z_in], real matrix double, the input point set, size(V_in) = [nb_input_vertices,3].
%          [ |    |    |  ]
%
%          [  |     |     |  ]
% - T_in = [i1_in i2_in i3_in], positive integer matrix double, the input triangulation, size(T_in) = [nb_input_triangles,3].
%          [  |     |     |  ]
%
%
% Output arguments
%
%           [  |     |     |  ]
% - V_out = [X_out Y_out Z_out], real matrix double, the output point set, size(V_out) = [nb_output_vertices,3].
%           [  |     |     |  ]
%
%           where nb_output_vertices = nb_input_vertices - nb_unreferenced_vertices.
%
%           [  |      |      |   ]
% - T_out = [i1_out i2_out i3_out], positive integer matrix double, the output triangulation, size(T_out) = [nb_output_triangles,3],
%           [  |      |      |   ]
%
%           where nb_output_triangles = nb_input_triangles.

unref_vtx_idx = setdiff(1:size(V_in,1),unique(T_in(:)));
[V_out,T_out] = MPT_remove_vertices(unref_vtx_idx,V_in,T_in,'indices');

end