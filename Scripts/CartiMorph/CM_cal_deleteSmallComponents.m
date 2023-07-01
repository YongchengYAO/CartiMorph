function faces_out = CM_cal_deleteSmallComponents(components, threshold)
% ==============================================================================
% FUNCTION:
%     Delete small mesh components.
%
% INPUT:
%     - components: mesh component
%     - threshold: size threshold below which the (small) components will be removed
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

size_components = cellfun(@(c) size(c,1), components);
total_size = sum(size_components, 1);
component_percentage = round(100 * size_components / total_size);
faces_out = cell2mat(components(component_percentage>=threshold, 1));

end