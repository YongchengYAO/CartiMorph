function subs_filled = CM_cal_reconCartDefect_curve_TC(subs_in, size_img)
% ==============================================================================
% FUNCTION:
%     Full-thickness cartilage defect reconstruction for Tibial Cartilage (step 2).
%
% INPUT:
%     - subs_in: (nc_in, 3), subscripts of voxels on the bone-cartilage interface
%     - size_img: image size
%
% OUTPUT:
%     - subs_filled: (nf_out, 3), subscripts of voxels on the filled bone-cartilage interface
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 25-Jul-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================


%% Find sagittal slices need to be filled
sagIdx = unique(subs_in(:, 1));
num_sagSlices= size(sagIdx, 1);
sagIdx_tbf = [];
for i=1:num_sagSlices
    % get voxels indices in th i-th sagittal slices
    i_sagIdx = sagIdx(i);
    i_sagSlice = subs_in(subs_in(:,1)==i_sagIdx, :, :);
    % remove isolated voxels
    i_sagSlice_vol = CM_cal_convertVoxIdx2Mask_3D(i_sagSlice, size_img);
    i_sagSlice_vol = bwareaopen(i_sagSlice_vol, 10, 26);
    % find connected components
    i_cc = bwconncomp(i_sagSlice_vol);
    if i_cc.NumObjects > 1
        sagIdx_tbf = cat(1, sagIdx_tbf, i_sagIdx);
    end
end


%% Setting
maxOrder = 5;
subs_filled = subs_in;
num_sagSlices_tbf = size(sagIdx_tbf, 1);


%% Gap filling via curve fitting
% % Testing: plot-------------------------------------------------
% count = 1;
% figure
% % Testing: plot-------------------------------------------------

for j=1:num_sagSlices_tbf
    % get voxels indices in th i-th sagittal slices
    j_sagIdx = sagIdx_tbf(j);
    j_sagSlice = subs_in(subs_in(:,1)==j_sagIdx, :, :);

    if size(j_sagSlice,1)>=20
        % [Normalization]
        % -----------------------------------
        % find the center
        j_sagSlice_2D = j_sagSlice(:,[2,3]);
        j_center_2D = round([mean(j_sagSlice_2D(:,1)), min(j_sagSlice_2D(:,2))-1]);
        % normalize the voxels indices via translation to the estimated center
        j_sagSlice_2D_norm = j_sagSlice_2D - j_center_2D;
        j_x = j_sagSlice_2D_norm(:,1);
        j_y = j_sagSlice_2D_norm(:,2);
        j_xy = [j_x, j_y];
        % remove duplicated points
        j_xy = unique(j_xy, 'rows');
        j_x = j_xy(:, 1);
        j_y = j_xy(:, 2);
        % -----------------------------------

        % [Curve fittings]
        % -----------------------------------
        % supress warning: "curvefit:fit:equationBadlyConditioned"
        warning('off', 'curvefit:fit:equationBadlyConditioned')
        % find the best curve fitting model
        j_bestModel = CM_cal_bestCurveFit_poly(j_x, j_y, maxOrder);
        % estimate/evaluate the best model
        j_x_grid_norm = transpose(min(j_x):1/10:max(j_x));
        j_y_hat_grid_norm = j_bestModel(j_x_grid_norm);
        % move the estimated points back to the original center
        j_x_grid = j_x_grid_norm + j_center_2D(1);
        j_y_hat_grid = j_y_hat_grid_norm + j_center_2D(2);
        j_xy_grid = [j_x_grid, j_y_hat_grid];
        % -----------------------------------

        % [Fill the gaps in sagittal slice]
        % -----------------------------------
        if min(j_xy_grid(:,1))>0 &&...
                min(j_xy_grid(:,2))>0 &&...
                max(j_xy_grid(:,1))<=size_img(2) &&...
                max(j_xy_grid(:,2))<=size_img(3)
            search_range = norm([1,1,1]);  % when vers is voxel indices
            [j_distance, ~] = pdist2(j_sagSlice_2D, j_xy_grid, 'euclidean', 'Smallest', 1);
            if sum(j_distance > search_range)>0
                idx_xGrid_fill = j_distance > search_range;
                j_xy_fill_smooth = j_xy_grid(idx_xGrid_fill, :);
                j_xy_filling_2D = unique(round(j_xy_fill_smooth), 'rows');
                j_sagSlice_filling = [repmat(j_sagIdx, [size(j_xy_filling_2D,1),1]), j_xy_filling_2D];
                subs_filled = cat(1, subs_filled, j_sagSlice_filling);
            end
        end
        % -----------------------------------
    end

    %     % Testing: plot------------------------------------------------
    %     if mod(j,1)==0
    %         subplot(ceil(num_sagSlices_tbf/(4*1)),8,2*(count-1)+1)
    %         plot(j_sagSlice_2D(:,1), j_sagSlice_2D(:,2), '.', 'Color', 'b')
    %         hold on
    %         plot(j_x_grid, j_y_hat_grid, '.', 'Color', 'r')
    %         title(num2str(j_sagIdx), 'Interpreter','none')
    %         axis equal
    %         hold off
    %
    %         subplot(ceil(num_sagSlices_tbf/(4*1)),8,2*(count-1)+2)
    %         plot(j_sagSlice_2D(:,1), j_sagSlice_2D(:,2),'.', 'Color', 'b')
    %         hold on
    %         if exist("j_xy_filling_2D", 'var')
    %             plot(j_xy_filling_2D(:,1), j_xy_filling_2D(:,2),'.', 'Color', 'r')
    %         end
    %         title(num2str(j_sagIdx), 'Interpreter','none')
    %         axis equal
    %         hold off
    %
    %         % !!! important !!! (must clear this variable)
    %         clear j_xy_filling_2D
    %         % !!! important !!!
    %         count = count + 1;
    %     end
    %     % Testing: plot-------------------------------------------------
end

end