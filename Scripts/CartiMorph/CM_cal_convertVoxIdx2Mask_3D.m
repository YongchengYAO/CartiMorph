function mask_3d = CM_cal_convertVoxIdx2Mask_3D(subs_vertices, size_img)

% convert voxel indices to volume
mask_3d = zeros(size_img);
idx_vertices = sub2ind(size_img, subs_vertices(:,1), subs_vertices(:,2), subs_vertices(:,3));
mask_3d(idx_vertices) = 1;

end