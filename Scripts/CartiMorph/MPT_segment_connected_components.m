function [cc_nb, components] = MPT_segment_connected_components(T, mode)
%% segment_connected_components : function to compute the number cc_nb of connected
% components and consequently segment the triangulation into cc_nb triangulation cells.
%
% Author & support : nicolas.douillet (at) free.fr, 2020.
%
%
% Input arguments
%
%       [|  |  | ]
% - T = [i1 i2 i3], positive integer matrix double, the triangulation, size(T) = [nb_input_triangles,3].
%       [|  |  | ]
%
% - mode : character string in the set {'explicit','indices','EXPLICIT','INDICES'}, the format of each cell
%          content of output cell array components. In case mode is set to 'explicit', triangles are refered
%          as triplet lists of positive integer scalar double, whereas in case it is set to 'indices', they are
%          just identified with their indices (positive integer scalar double). Case insensitive.
%
%
% Output arguments
%
% - cc_nb : positive integer scalar double, the number of connected components.
%
% - components : cell array of triangle sets (positive integer matrices double), the component array.

if nargin < 2
    mode = 'explicit'; % default
end

components = {};
component = [];
cc_nb = 0; % hypothesis : T non empty

ngb_T = MPT_find_neighbor_triangle_indices(T); % 'all'
stored_tgl_idx = 1; % Default seed triangle is #1
t = 1; % nb processed / stored triangles
curr_tgl_idx = stored_tgl_idx(t);


if strcmpi(mode,'explicit')

    component = cat(1,component,T(curr_tgl_idx,:));

    while numel(stored_tgl_idx) < size(T,1) % some unstored triangles remain

        % One same component
        while t < numel(stored_tgl_idx) + 1 % ~isempty(idx_ngb_tgl_2_store)
            curr_tgl_idx = stored_tgl_idx(t);
            ngb_tgl_idx = cell2mat(ngb_T(curr_tgl_idx,1))';
            idx_ngb_tgl_2_store = setdiff(ngb_tgl_idx,stored_tgl_idx);
            component = cat(1,component,T(idx_ngb_tgl_2_store,:));
            stored_tgl_idx = cat(2,stored_tgl_idx,idx_ngb_tgl_2_store);
            t = t + 1;
        end

        components = cat(1,components,{component});

        % New component
        component = [];
        cc_nb = cc_nb + 1;

        % New triangle seed : the first which is not in the list
        unstored_tgl_idx = setdiff(1:size(T,1),stored_tgl_idx);

        if ~isempty(unstored_tgl_idx) % some unstored triangles remain
            curr_tgl_idx = unstored_tgl_idx(1,1); % default seed triangle is 1st of the list
            component = cat(1,component,T(curr_tgl_idx,:));
            stored_tgl_idx = cat(2,stored_tgl_idx,curr_tgl_idx);
        end

        if numel(stored_tgl_idx) == size(T,1) % store last triangle
            if ~isempty(component)
                components = cat(1,components,{component});
                cc_nb = cc_nb + 1;
            end
        end
    end

elseif strcmpi(mode,'indices')

    component = cat(2,component,curr_tgl_idx);

    while numel(stored_tgl_idx) < size(T,1) % some unstored triangles remain

        % One same component
        while t < numel(stored_tgl_idx) + 1 % ~isempty(idx_ngb_tgl_2_store)
            curr_tgl_idx = stored_tgl_idx(t);
            ngb_tgl_idx = cell2mat(ngb_T(curr_tgl_idx,1))';
            idx_ngb_tgl_2_store = setdiff(ngb_tgl_idx,stored_tgl_idx);
            component = cat(2,component,idx_ngb_tgl_2_store);
            stored_tgl_idx = cat(2,stored_tgl_idx,idx_ngb_tgl_2_store);
            t = t + 1;
        end

        components = cat(1,components,{component});

        % New component
        component = [];
        cc_nb = cc_nb + 1;

        % New triangle seed : the first which is not in the list
        unstored_tgl_idx = setdiff(1:size(T,1),stored_tgl_idx);

        if ~isempty(unstored_tgl_idx) % some unstored triangles remain
            curr_tgl_idx = unstored_tgl_idx(1,1); % default seed triangle is 1st of the list
            component = cat(2,component,curr_tgl_idx);
            stored_tgl_idx = cat(2,stored_tgl_idx,curr_tgl_idx);
        end

        if numel(stored_tgl_idx) == size(T,1) % store last triangle
            if ~isempty(component)
                components = cat(1,components,{component});
            end
        end
    end
end
end