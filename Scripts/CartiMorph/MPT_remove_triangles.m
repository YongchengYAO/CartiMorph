function [T_out] = MPT_remove_triangles(T_set, T_in, mode)
%% remove_triangles : function to remove triangles from the triangle set.
%
% Author & support : nicolas.douillet (at) free.fr, 2020.
%
%
% Input arguments
%
%           [|  |  | ]
% - T_set = [i1 i2 i3], positive integer matrix double, the triangle set, size(T_set) = [nb_triangles,3],
%           [|  |  | ]
%
%           or integer vector of indices, size(T_set) = [1,nb_triangles]. NB : in the case size(T_set) = [1,3]
%           the difference between the two possible options is only made thanks to the input argument mode value.
%
%          [  |     |     |  ]
% - T_in = [i1_in i2_in i3_in], positive integer matrix double, the input triangulation, size(T_in) = [nb_input_triangles,3].
%          [  |     |     |  ]
%
% - mode : character string in the set {'indices','explicit','INDICES','EXPLICIT'}. Case insensitive.
%
%
% Output argument
%
%           [  |      |      |   ]
% - T_out = [i1_out i2_out i3_out], positive integer matrix double, the output triangulation, size(T_out) = [nb_output_triangles,3],
%           [  |      |      |   ]
%
%           with nb_output_triangles = nb_input_triangles - nb_removed_triangles.

if nargin < 3
    mode = 'indices'; % default behaviour
end

T_out = T_in;

if strcmpi(mode,'indices') && ismember(1,size(T_set))
    T_out(T_set,:) = [];
elseif strcmpi(mode,'explicit') && size(T_set,2) == 3
    T_out = setdiff(T_in,T_set,'rows','stable');
else
    error('mode value must be either set to ''indices'' with T_set a one row/column vector or to ''explicit'' with size(T_set,2) = 3.');
end
end