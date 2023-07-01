function faces_out = CM_cal_surfaceClosing(...
    faces_in,...
    faces_source,...
    iteration_dilation,...
    iteration_erosion)
% ==============================================================================
% FUNCTION:
%     Apply surface/mesh close operation.
%
% INPUT:
%     - faces_source: (nf, 3), the faces of source mesh
%     - faces_in: (nf_in, 3), the input faces
%     - iteration_dilation: iteration time for surface dilation
%     - iteration_erosion: iteration time for surface erosion
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

%% Surface dilation
faces_dilated = CM_cal_surfaceDilation(...
    faces_in,...
    faces_source,...
    iteration_dilation);

%% Surface erosion
faces_out = CM_cal_surfaceErosion(...
    faces_dilated,...
    iteration_erosion);
end