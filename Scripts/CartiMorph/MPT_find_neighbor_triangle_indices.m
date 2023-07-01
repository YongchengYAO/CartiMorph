function [ngb_T] = MPT_find_neighbor_triangle_indices(T, T_subset, mode)
%% find_neighbor_triangle_indices : function to compute the list of triangles
% which are neighbors (share one edge) to the triangles in T_subset.
%
% Author & support : nicolas.douillet (at) free.fr, 2020.
%
%
% Input arguments
%
%       [ |  |  |]
% - T = [i1 i2 i3], positive integer matrix double, the triangulation, size(T) = [nb_triangles,3].
%       [ |  |  |]
%
% - T_subset : either positive integer row vector double* (the indices of the triangles; default behaviour) or
%              positive integer matrix double giving the explicit indices triplet list. In this latter case,
%              mode must be set to 'explicit'.
%
% - mode : character string in the set : {'explicit',indices,'EXPLICIT','INDICES'}. Explicit mode
%          corresponds to the case where T_subset is made of triangle vertices [i1 i2 i3] indices.
%          Case insensitive.
%
%
% Output argument
%
% - ngb_T : positive integer matrix double, the neighbor triangle indices, size(ngb_T) = [nbg_nb,3],
%           with nbg_nb the number of neighbors.

if nargin > 1
    if nargin > 2
        if strcmpi(mode,'indices')
            subset_idx = T_subset;
        elseif strcmpi(mode,'explicit')
            subset_idx = find(ismember(T,T_subset,'rows'));
        end
    else
        % mode = 'indices'; % default behaviour
        subset_idx = T_subset;
    end
    T_subset = T(subset_idx,:);
else
    T_subset = T;
end

ngb_T = cellfun(@(t) find(sum(bitor(bitor(T==T_subset(t,1),T==T_subset(t,2)),T==T_subset(t,3)),2)==2),...
    num2cell((1:size(T_subset,1))'),'un',0);
end