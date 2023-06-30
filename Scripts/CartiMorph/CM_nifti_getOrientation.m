function [dim_Right, dim_Anterior, dim_Superior] = CM_nifti_getOrientation(affineT)
% ==============================================================================
% FUNCTION:
%     Get NIfTI orientation. Find the anatomical orientation (R-L, A-P, S-L) of the image bases
%
% INPUT:
%     - affineT: (4,4), affine transformation matrix
%
% OUTPUT:
%     - dim_Right: dimension of image points to right
%     - dim_Anterior: dimension of image points to anterior
%     - dim_Superior: dimension of image points to superior
%
% This function only works for NIfTI image
% Note, in NIfTI standard, real world bases correspond to {R, A, S} direction
% Note, real world bases and image bases are orthorgonal bases
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 06-Jul-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================


% ignore translation in affine transformation
mat = affineT(1:3, 1:3);

% "mat" is a linear transformation from "image space" to "real world space"
% [note, in NIfTI header, bases are rows in the matrix]
axis_i_real = mat(1, :);  % i axis in "image space" transformed to "real world space"
axis_j_real = mat(2, :);  % j axis in "image space" transformed to "real world space"
axis_k_real = mat(3, :);  % k axis in "image space" transformed to "real world space"

% define the orientation for real world bases -- the NIfTI standard RAS+
axis_R_real = [1,0,0];  % the [1,0,0] vector in "real space" point to Right
axis_A_real = [0,1,0];  % the [0,1,0] vector in "real space" point to Anterior
axis_S_real = [0,0,1];  % the [0,0,1] vector in "real space" point to Superior

% angle between transformed image bases and real world bases
angle_i_R = acosd(dot(axis_i_real, axis_R_real) / (norm(axis_R_real) * norm(axis_i_real)));
angle_i_A = acosd(dot(axis_i_real, axis_A_real) / (norm(axis_A_real) * norm(axis_i_real)));
angle_i_S = acosd(dot(axis_i_real, axis_S_real) / (norm(axis_S_real) * norm(axis_i_real)));

angle_j_R = acosd(dot(axis_j_real, axis_R_real) / (norm(axis_R_real) * norm(axis_j_real)));
angle_j_A = acosd(dot(axis_j_real, axis_A_real) / (norm(axis_A_real) * norm(axis_j_real)));
angle_j_S = acosd(dot(axis_j_real, axis_S_real) / (norm(axis_S_real) * norm(axis_j_real)));

angle_k_R = acosd(dot(axis_k_real, axis_R_real) / (norm(axis_R_real) * norm(axis_k_real)));
angle_k_A = acosd(dot(axis_k_real, axis_A_real) / (norm(axis_A_real) * norm(axis_k_real)));
angle_k_S = acosd(dot(axis_k_real, axis_S_real) / (norm(axis_S_real) * norm(axis_k_real)));

% convert angles to range [0,90] degree considering flipping
angles_i2RAS = [angle_i_R, angle_i_A, angle_i_S];
flip_i = angles_i2RAS > 90;
angles_i2RAS(flip_i) = 180 - angles_i2RAS(flip_i);

angles_j2RAS = [angle_j_R, angle_j_A, angle_j_S];
flip_j = angles_j2RAS > 90;
angles_j2RAS(flip_j) = 180 - angles_j2RAS(flip_j);

angles_k2RAS = [angle_k_R, angle_k_A, angle_k_S];
flip_K = angles_k2RAS > 90;
angles_k2RAS(flip_K) = 180 - angles_k2RAS(flip_K);

% find the approximate direction of transformed image bases
[~, direction_i] = min(angles_i2RAS);
if flip_i(direction_i)
    direction_i = direction_i .* -1;
end

fake_angles_j2RAS = angles_j2RAS;
fake_angles_j2RAS(abs(direction_i)) = 90;
[~, direction_j] = min(fake_angles_j2RAS);
if flip_j(direction_j)
    direction_j = direction_j .* -1;
end

fake_angles_k2RAS = angles_k2RAS;
fake_angles_k2RAS(abs(direction_i)) = 90;
fake_angles_k2RAS(abs(direction_j)) = 90;
[~, direction_k] = min(fake_angles_k2RAS);
if flip_K(direction_k)
    direction_k = direction_k .* -1;
end

% find the image dimension for Right, Anterior, and Superior directions
dim_Right = find([direction_i, direction_j, direction_k]==1);
if isempty(dim_Right)
    dim_Right = -1 * find([direction_i, direction_j, direction_k]==-1);
end

dim_Anterior = find([direction_i, direction_j, direction_k]==2);
if isempty(dim_Anterior)
    dim_Anterior = -1 * find([direction_i, direction_j, direction_k]==-2);
end

dim_Superior = find([direction_i, direction_j, direction_k]==3);
if isempty(dim_Superior)
    dim_Superior = -1 * find([direction_i, direction_j, direction_k]==-3);
end

end