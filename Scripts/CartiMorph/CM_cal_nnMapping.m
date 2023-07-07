function seg_out = CM_cal_nnMapping(mask_dest, seg_src)
% ==============================================================================
% FUNCTION:
%     Map segmentation (i.e., label) to mask (i.e. binary image).
%
% INPUT:
%     - mask_dest: the target space where labels from the source segmentation mask should be mapped to
%     - seg_src: source segmentation mask with labels
%
% OUTPUT:
%     - seg_out: the output segmentation mask
%
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 27-Jun-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================

size_img = size(mask_dest);
idx_dest = find(mask_dest);
[sub1_dest, sub2_dest, sub3_dest] = ind2sub(size_img, idx_dest);
subs_dest = [sub1_dest, sub2_dest, sub3_dest];
[sub1_src, sub2_src, sub3_src] = ind2sub(size_img, find(seg_src));
subs_src = [sub1_src, sub2_src, sub3_src];
[~, tmpIdx] = pdist2(subs_src, subs_dest, 'euclidean', 'Smallest', 1);
subs_nearVox_src = subs_src(tmpIdx, :);
idx_nearVox_src = sub2ind(size_img, subs_nearVox_src(:,1),...
    subs_nearVox_src(:,2), subs_nearVox_src(:,3));
seg_out = zeros(size_img, class(seg_src));
seg_out(idx_dest) = seg_src(idx_nearVox_src);

end