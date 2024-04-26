function atlas = CM_cal_VolumeParcellation_TC(mask_mTC, mask_lTC, kneeSide, size_voxel, size_img)
% ==============================================================================
% FUNCTION:
%     Tibial cartilage parcellation for knee template.
%
% INPUT:
%     - mask_mTC: segmentation mask for the mTC
%     - mask_lTC: segmentation mask for the lTC
%     - kneeSide: knee side, must be one of {"left", "right"}
%     - size_voxel: voxel size
%     - size_img: image size
%
% OUTPUT:
%     - atlas: the atlas of TC
%
% ROI code in the atlas:
%     11: aMTC
%     12: eMTC
%     13: pMTC
%     14: iMTC
%     15: cMTC
%     16: aLTC
%     17: eLTC
%     18: pLTC
%     19: iLTC
%     20: cLTC
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 23-Jun-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================

% voxel subscripts
[sub1_mTC, sub2_mTC, sub3_mTC] = ind2sub(size_img, find(mask_mTC));
subs_mTC = [sub1_mTC, sub2_mTC, sub3_mTC];
[sub1_lTC, sub2_lTC, sub3_lTC] = ind2sub(size_img, find(mask_lTC));
subs_lTC = [sub1_lTC, sub2_lTC, sub3_lTC];

% voxel coordinates
vers_MTC = subs_mTC .* size_voxel;
vers_LTC = subs_lTC .* size_voxel;


% ---------------------------------------------------------
% Locate cMTC
% ---------------------------------------------------------
% translation
center_MTC = mean(vers_MTC, 1);
vers_MTC_c = vers_MTC - center_MTC;
% SVD
[~, S, V] = svd(vers_MTC_c, 0);
diagS = diag(S);

% .........................................................
% find the nearest axis to the each singular vector (assuming RAS+ orientation)
sigV1 = V(:,1);
sigV2 = V(:,2);
sigV3 = V(:,3);
axis_R = [1,0,0];
axis_A = [0,1,0];
axis_S = [0,0,1];
% angle between singular vectors and axes
angle_sigV1_R = acosd(dot(sigV1, axis_R) / (norm(axis_R) * norm(sigV1)));
angle_sigV1_A = acosd(dot(sigV1, axis_A) / (norm(axis_A) * norm(sigV1)));
angle_sigV1_S = acosd(dot(sigV1, axis_S) / (norm(axis_S) * norm(sigV1)));
angle_sigV2_R = acosd(dot(sigV2, axis_R) / (norm(axis_R) * norm(sigV2)));
angle_sigV2_A = acosd(dot(sigV2, axis_A) / (norm(axis_A) * norm(sigV2)));
angle_sigV2_S = acosd(dot(sigV2, axis_S) / (norm(axis_S) * norm(sigV2)));
angle_sigV3_R = acosd(dot(sigV3, axis_R) / (norm(axis_R) * norm(sigV3)));
angle_sigV3_A = acosd(dot(sigV3, axis_A) / (norm(axis_A) * norm(sigV3)));
angle_sigV3_S = acosd(dot(sigV3, axis_S) / (norm(axis_S) * norm(sigV3)));
% convert angles to the range [0,90]
angles_sigV12RAS = [angle_sigV1_R, angle_sigV1_A, angle_sigV1_S];
flip_sigV1 = angles_sigV12RAS > 90;
angles_sigV12RAS(flip_sigV1) = 180 - angles_sigV12RAS(flip_sigV1);
angles_sigV22RAS = [angle_sigV2_R, angle_sigV2_A, angle_sigV2_S];
flip_sigV2 = angles_sigV22RAS > 90;
angles_sigV22RAS(flip_sigV2) = 180 - angles_sigV22RAS(flip_sigV2);
angles_sigV32RAS = [angle_sigV3_R, angle_sigV3_A, angle_sigV3_S];
flip_sigV3 = angles_sigV32RAS > 90;
angles_sigV32RAS(flip_sigV3) = 180 - angles_sigV32RAS(flip_sigV3);
% find the nearest axis for each singular vector
[~, direction_sigV1] = min(angles_sigV12RAS);
fake_angles_sigV22RAS = angles_sigV22RAS;
fake_angles_sigV22RAS(abs(direction_sigV1)) = 90;
[~, direction_sigV2] = min(fake_angles_sigV22RAS);
fake_angles_sigV32RAS = angles_sigV32RAS;
fake_angles_sigV32RAS(abs(direction_sigV1)) = 90;
fake_angles_sigV32RAS(abs(direction_sigV2)) = 90;
[~, direction_sigV3] = min(fake_angles_sigV32RAS);
absDirection_sigV123 = [direction_sigV1, direction_sigV2, direction_sigV3];
% .........................................................

% transformation
transMat_MTC(:, direction_sigV1) = sigV1;
transMat_MTC(:, direction_sigV2) = sigV2;
transMat_MTC(:, direction_sigV3) = sigV3;
transMat_MTC(:, diag(transMat_MTC)<0) = transMat_MTC(:, diag(transMat_MTC)<0) * -1;
vers_MTC_ct = transpose(transMat_MTC \ vers_MTC_c');

% initial parcellation of cMTL
tmpA = 5;
tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
tmpX = vers_MTC_ct(:,1);
tmpY = vers_MTC_ct(:,2);
idx_cMTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
vers_cMTC_ct = vers_MTC_ct(idx_cMTC, :);
vers_cMTC_c = transpose(transMat_MTC * vers_cMTC_ct');
vers_cMTC = vers_cMTC_c + center_MTC;

% adjust the cMTL untill it covers 20% volume of the MTL
volume_voxel = size_voxel(1) * size_voxel(2) * size_voxel(3);
volume_MTC = size(unique(vers_MTC, 'rows'), 1) * volume_voxel;
volume_cMTC = size(unique(vers_cMTC, 'rows'), 1) * volume_voxel;
recorder_osillation = 0;
counter_Act = 0;
while abs(volume_cMTC/volume_MTC - 0.2)>0.005 && recorder_osillation<1000
    if volume_cMTC/volume_MTC > 0.2
        counter_Act = counter_Act + 1;
        % new cMTL
        tmpA = tmpA - 0.5;
        tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
        tmpX = vers_MTC_ct(:,1);
        tmpY = vers_MTC_ct(:,2);
        idx_cMTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_cMTC_ct = vers_MTC_ct(idx_cMTC, :);
        vers_cMTC_c = transpose(transMat_MTC * vers_cMTC_ct');
        vers_cMTC = vers_cMTC_c + center_MTC;
        % new cMTL volume
        volume_cMTC = size(unique(vers_cMTC, 'rows'), 1) * volume_voxel;
        % update osillation status
        recorder_currAct = 1;
        if counter_Act==1
            recorder_lastAct=recorder_currAct;
        end
        if recorder_currAct~=recorder_lastAct
            recorder_osillation = recorder_osillation + 1;
        end
    else
        counter_Act = counter_Act + 1;
        % new cMTL
        tmpA = tmpA + 0.5;
        tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
        tmpX = vers_MTC_ct(:,1);
        tmpY = vers_MTC_ct(:,2);
        idx_cMTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_cMTC_ct = vers_MTC_ct(idx_cMTC, :);
        vers_cMTC_c = transpose(transMat_MTC * vers_cMTC_ct');
        vers_cMTC = vers_cMTC_c + center_MTC;
        % new cMTL area
        volume_cMTC = size(unique(vers_cMTC, 'rows'), 1) * volume_voxel;
        % update osillation status
        recorder_currAct = -1;
        if counter_Act==1
            recorder_lastAct=recorder_currAct;
        end
        if recorder_currAct~=recorder_lastAct
            recorder_osillation = recorder_osillation + 1;
        end
    end
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate cLTC
% ---------------------------------------------------------
% translation
center_LTC = mean(vers_LTC, 1);
vers_LTC_c = vers_LTC - center_LTC;
% SVD
[~, S, V] = svd(vers_LTC_c, 0);
diagS = diag(S);

% .........................................................
% find the nearest axis to the each singular vector (assuming RAS+ orientation)
sigV1 = V(:,1);
sigV2 = V(:,2);
sigV3 = V(:,3);
axis_R = [1,0,0];
axis_A = [0,1,0];
axis_S = [0,0,1];
% angle between singular vectors and axes
angle_sigV1_R = acosd(dot(sigV1, axis_R) / (norm(axis_R) * norm(sigV1)));
angle_sigV1_A = acosd(dot(sigV1, axis_A) / (norm(axis_A) * norm(sigV1)));
angle_sigV1_S = acosd(dot(sigV1, axis_S) / (norm(axis_S) * norm(sigV1)));
angle_sigV2_R = acosd(dot(sigV2, axis_R) / (norm(axis_R) * norm(sigV2)));
angle_sigV2_A = acosd(dot(sigV2, axis_A) / (norm(axis_A) * norm(sigV2)));
angle_sigV2_S = acosd(dot(sigV2, axis_S) / (norm(axis_S) * norm(sigV2)));
angle_sigV3_R = acosd(dot(sigV3, axis_R) / (norm(axis_R) * norm(sigV3)));
angle_sigV3_A = acosd(dot(sigV3, axis_A) / (norm(axis_A) * norm(sigV3)));
angle_sigV3_S = acosd(dot(sigV3, axis_S) / (norm(axis_S) * norm(sigV3)));
% convert angles to the range [0,90]
angles_sigV12RAS = [angle_sigV1_R, angle_sigV1_A, angle_sigV1_S];
flip_sigV1 = angles_sigV12RAS > 90;
angles_sigV12RAS(flip_sigV1) = 180 - angles_sigV12RAS(flip_sigV1);
angles_sigV22RAS = [angle_sigV2_R, angle_sigV2_A, angle_sigV2_S];
flip_sigV2 = angles_sigV22RAS > 90;
angles_sigV22RAS(flip_sigV2) = 180 - angles_sigV22RAS(flip_sigV2);
angles_sigV32RAS = [angle_sigV3_R, angle_sigV3_A, angle_sigV3_S];
flip_sigV3 = angles_sigV32RAS > 90;
angles_sigV32RAS(flip_sigV3) = 180 - angles_sigV32RAS(flip_sigV3);
% find the nearest axis for each singular vector
[~, direction_sigV1] = min(angles_sigV12RAS);
fake_angles_sigV22RAS = angles_sigV22RAS;
fake_angles_sigV22RAS(abs(direction_sigV1)) = 90;
[~, direction_sigV2] = min(fake_angles_sigV22RAS);
fake_angles_sigV32RAS = angles_sigV32RAS;
fake_angles_sigV32RAS(abs(direction_sigV1)) = 90;
fake_angles_sigV32RAS(abs(direction_sigV2)) = 90;
[~, direction_sigV3] = min(fake_angles_sigV32RAS);
absDirection_sigV123 = [direction_sigV1, direction_sigV2, direction_sigV3];
% .........................................................

% transformation
transMat_LTC(:, direction_sigV1) = sigV1;
transMat_LTC(:, direction_sigV2) = sigV2;
transMat_LTC(:, direction_sigV3) = sigV3;
transMat_LTC(:, diag(transMat_LTC)<0) = transMat_LTC(:, diag(transMat_LTC)<0) * -1;
vers_LTC_ct = transpose(transMat_LTC \ vers_LTC_c');

% initial parcellation of cMTL
tmpA = 5;
tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
tmpX = vers_LTC_ct(:,1);
tmpY = vers_LTC_ct(:,2);
idx_cLTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
vers_cLTC_ct = vers_LTC_ct(idx_cLTC, :);
vers_cLTC_c = transpose(transMat_LTC * vers_cLTC_ct');
vers_cLTC = vers_cLTC_c + center_LTC;

% adjust the cMTL untill it covers 20% volume of the MTL
volume_LTC = size(unique(vers_LTC, 'rows'), 1) * volume_voxel;
volume_cLTC = size(unique(vers_cLTC, 'rows'), 1) * volume_voxel;
recorder_osillation = 0;
counter_Act = 0;
while abs(volume_cLTC/volume_LTC - 0.2)>0.005 && recorder_osillation<1000
    if volume_cLTC/volume_LTC > 0.2
        counter_Act = counter_Act + 1;
        % new cMTL
        tmpA = tmpA - 0.5;
        tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
        tmpX = vers_LTC_ct(:,1);
        tmpY = vers_LTC_ct(:,2);
        idx_cLTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_cLTC_ct = vers_LTC_ct(idx_cLTC, :);
        vers_cLTC_c = transpose(transMat_LTC * vers_cLTC_ct');
        vers_cLTC = vers_cLTC_c + center_LTC;
        % new cMTL volume
        volume_cLTC = size(unique(vers_cLTC, 'rows'), 1) * volume_voxel;
        % update osillation status
        recorder_currAct = 1;
        if counter_Act==1
            recorder_lastAct=recorder_currAct;
        end
        if recorder_currAct~=recorder_lastAct
            recorder_osillation = recorder_osillation + 1;
        end
    else
        counter_Act = counter_Act + 1;
        % new cMTL
        tmpA = tmpA + 0.5;
        tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
        tmpX = vers_LTC_ct(:,1);
        tmpY = vers_LTC_ct(:,2);
        idx_cLTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_cLTC_ct = vers_LTC_ct(idx_cLTC, :);
        vers_cLTC_c = transpose(transMat_LTC * vers_cLTC_ct');
        vers_cLTC = vers_cLTC_c + center_LTC;
        % new cMTL volume
        volume_cLTC = size(unique(vers_cLTC, 'rows'), 1) * volume_voxel;
        % update osillation status
        recorder_currAct = -1;
        if counter_Act==1
            recorder_lastAct=recorder_currAct;
        end
        if recorder_currAct~=recorder_lastAct
            recorder_osillation = recorder_osillation + 1;
        end
    end
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aMTC, pMTC, iMTC, eMTC
% ---------------------------------------------------------
% centered and translated non-cMTC
vers_noncMTC_ct = vers_MTC_ct(~idx_cMTC, :);
% lTC centered to the centroid of mTC and translated to eigen-vectors of mTC
center_LTC_c2MTC = center_LTC - center_MTC;
center_LTC_c2MTC_t = transpose(transMat_MTC \ center_LTC_c2MTC');
% define cutting line 1 in x-y plane
a1 = 45;
transMat_MTC_U1 = [cosd(a1), -sind(a1), 0; sind(a1), cosd(a1), 0; 0, 0, 1];
vect1_MTC2LTC_t = transMat_MTC_U1 * center_LTC_c2MTC_t';
k1_MTC = vect1_MTC2LTC_t(2) / vect1_MTC2LTC_t(1);
% define cutting line 2 in x-y plane
a2 = -45;
transMat_MTC_U2 = [cosd(a2), -sind(a2), 0; sind(a2), cosd(a2), 0; 0, 0, 1];
vect2_MTC2LTC_t = transMat_MTC_U2 * center_LTC_c2MTC_t';
k2_MTC = vect2_MTC2LTC_t(2) / vect2_MTC2LTC_t(1);
% cut the non-mTC region into 4 clusters (ROIs)
idx_C1_MTC = vers_noncMTC_ct(:,2) > k1_MTC*vers_noncMTC_ct(:,1) & ...
    vers_noncMTC_ct(:,2) > k2_MTC*vers_noncMTC_ct(:,1);
idx_C2_MTC = vers_noncMTC_ct(:,2) < k1_MTC*vers_noncMTC_ct(:,1) & ...
    vers_noncMTC_ct(:,2) < k2_MTC*vers_noncMTC_ct(:,1);
idx_C3_MTC = vers_noncMTC_ct(:,2) <= k1_MTC*vers_noncMTC_ct(:,1) & ...
    vers_noncMTC_ct(:,2) >= k2_MTC*vers_noncMTC_ct(:,1);
idx_C4_MTC = vers_noncMTC_ct(:,2) >= k1_MTC*vers_noncMTC_ct(:,1) & ...
    vers_noncMTC_ct(:,2) <= k2_MTC*vers_noncMTC_ct(:,1);
vers_C1_MTC_ct = vers_noncMTC_ct(idx_C1_MTC, :);
vers_C2_MTC_ct = vers_noncMTC_ct(idx_C2_MTC, :);
vers_C3_MTC_ct = vers_noncMTC_ct(idx_C3_MTC, :);
vers_C4_MTC_ct = vers_noncMTC_ct(idx_C4_MTC, :);
vers_C1_MTC = transpose(transMat_MTC * vers_C1_MTC_ct') + center_MTC;
vers_C2_MTC = transpose(transMat_MTC * vers_C2_MTC_ct') + center_MTC;
vers_C3_MTC = transpose(transMat_MTC * vers_C3_MTC_ct') + center_MTC;
vers_C4_MTC = transpose(transMat_MTC * vers_C4_MTC_ct') + center_MTC;
vers_Clusters_MTC = {vers_C1_MTC, vers_C2_MTC, vers_C3_MTC, vers_C4_MTC};
% assign label to each cluster (assuming RAS+ orientation)
centerCluster_MTC(1, :) = mean(vers_C1_MTC, 1);
centerCluster_MTC(2, :) = mean(vers_C2_MTC, 1);
centerCluster_MTC(3, :) = mean(vers_C3_MTC, 1);
centerCluster_MTC(4, :) = mean(vers_C4_MTC, 1);
[~, idx_aMTC] = max(centerCluster_MTC(:, 2));
[~, idx_pMTC] = min(centerCluster_MTC(:, 2));
[~, idx_iMTC] = max(centerCluster_MTC(:, 1));
[~, idx_eMTC] = min(centerCluster_MTC(:, 1));
vers_aMTC = vers_Clusters_MTC{idx_aMTC};
vers_pMTC = vers_Clusters_MTC{idx_pMTC};
vers_iMTC = vers_Clusters_MTC{idx_iMTC};
vers_eMTC = vers_Clusters_MTC{idx_eMTC};
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aLTC, pLTC, iLTC, eLTC
% ---------------------------------------------------------
% centered and translated non-cLTC
vers_noncLTC_ct = vers_LTC_ct(~idx_cLTC, :);
% mTC centered to the centroid of lTC and translated to eigen-vectors of lTC
center_MTC_c2LTC = center_MTC - center_LTC;
center_MTC_c2LTC_t = transpose(transMat_LTC \ center_MTC_c2LTC');
% define cutting line 1 in x-y plane
a1 = 45;
transMat_LTC_U1 = [cosd(a1), -sind(a1), 0; sind(a1), cosd(a1), 0; 0, 0, 1];
vect1_LTC2MTC_t = transMat_LTC_U1 * center_MTC_c2LTC_t';
k1_LTC = vect1_LTC2MTC_t(2) / vect1_LTC2MTC_t(1);
% define cutting line 2 in x-y plane
a2 = -45;
transMat_LTC_U2 = [cosd(a2), -sind(a2), 0; sind(a2), cosd(a2), 0; 0, 0, 1];
vect2_LTC2MTC_t = transMat_LTC_U2 * center_MTC_c2LTC_t';
k2_LTC = vect2_LTC2MTC_t(2) / vect2_LTC2MTC_t(1);
% cut the non-lTC region into 4 clusters (ROIs)
idx_C1_LTC = vers_noncLTC_ct(:,2) > k1_LTC*vers_noncLTC_ct(:,1) & ...
    vers_noncLTC_ct(:,2) > k2_LTC*vers_noncLTC_ct(:,1);
idx_C2_LTC = vers_noncLTC_ct(:,2) < k1_LTC*vers_noncLTC_ct(:,1) & ...
    vers_noncLTC_ct(:,2) < k2_LTC*vers_noncLTC_ct(:,1);
idx_C3_LTC = vers_noncLTC_ct(:,2) <= k1_LTC*vers_noncLTC_ct(:,1) & ...
    vers_noncLTC_ct(:,2) >= k2_LTC*vers_noncLTC_ct(:,1);
idx_C4_LTC = vers_noncLTC_ct(:,2) >= k1_LTC*vers_noncLTC_ct(:,1) & ...
    vers_noncLTC_ct(:,2) <= k2_LTC*vers_noncLTC_ct(:,1);
vers_C1_LTC_ct = vers_noncLTC_ct(idx_C1_LTC, :);
vers_C2_LTC_ct = vers_noncLTC_ct(idx_C2_LTC, :);
vers_C3_LTC_ct = vers_noncLTC_ct(idx_C3_LTC, :);
vers_C4_LTC_ct = vers_noncLTC_ct(idx_C4_LTC, :);
vers_C1_LTC = transpose(transMat_LTC * vers_C1_LTC_ct') + center_LTC;
vers_C2_LTC = transpose(transMat_LTC * vers_C2_LTC_ct') + center_LTC;
vers_C3_LTC = transpose(transMat_LTC * vers_C3_LTC_ct') + center_LTC;
vers_C4_LTC = transpose(transMat_LTC * vers_C4_LTC_ct') + center_LTC;
vers_Clusters_LTC = {vers_C1_LTC, vers_C2_LTC, vers_C3_LTC, vers_C4_LTC};
% assign label to each cluster (assuming RAS+ orientation)
centerCluster_LTC(1, :) = mean(vers_C1_LTC, 1);
centerCluster_LTC(2, :) = mean(vers_C2_LTC, 1);
centerCluster_LTC(3, :) = mean(vers_C3_LTC, 1);
centerCluster_LTC(4, :) = mean(vers_C4_LTC, 1);
[~, idx_aLTC] = max(centerCluster_LTC(:, 2));
[~, idx_pLTC] = min(centerCluster_LTC(:, 2));
[~, idx_eLTC] = max(centerCluster_LTC(:, 1));
[~, idx_iLTC] = min(centerCluster_LTC(:, 1));
vers_aLTC = vers_Clusters_LTC{idx_aLTC};
vers_pLTC = vers_Clusters_LTC{idx_pLTC};
vers_eLTC = vers_Clusters_LTC{idx_eLTC};
vers_iLTC = vers_Clusters_LTC{idx_iLTC};
% ---------------------------------------------------------


% ---------------------------------------------------------
% combine results
% ---------------------------------------------------------
subsSubReg_TC.cMTC = round(vers_cMTC ./ size_voxel);
subsSubReg_TC.aMTC = round(vers_aMTC ./ size_voxel);
subsSubReg_TC.pMTC = round(vers_pMTC ./ size_voxel);
subsSubReg_TC.cLTC = round(vers_cLTC ./ size_voxel);
subsSubReg_TC.aLTC = round(vers_aLTC ./ size_voxel);
subsSubReg_TC.pLTC = round(vers_pLTC ./ size_voxel);
switch kneeSide
    case "right"
        subsSubReg_TC.iMTC = round(vers_iMTC ./ size_voxel);
        subsSubReg_TC.eMTC = round(vers_eMTC ./ size_voxel);
        subsSubReg_TC.iLTC = round(vers_iLTC ./ size_voxel);
        subsSubReg_TC.eLTC = round(vers_eLTC ./ size_voxel);
    case "left" % swapping interior and exterior compartments
        subsSubReg_TC.iMTC = round(vers_eMTC ./ size_voxel);
        subsSubReg_TC.eMTC = round(vers_iMTC ./ size_voxel);
        subsSubReg_TC.iLTC = round(vers_eLTC ./ size_voxel);
        subsSubReg_TC.eLTC = round(vers_iLTC ./ size_voxel);
end
% ---------------------------------------------------------


% ---------------------------------------------------------
% create atlas
%     11: aMTC
%     12: eMTC
%     13: pMTC
%     14: iMTC
%     15: cMTC
%     16: aLTC
%     17: eLTC
%     18: pLTC
%     19: iLTC
%     20: cLTC
atlas = zeros(size_img, 'uint8');
idx_aMTC = sub2ind(size_img, subsSubReg_TC.aMTC(:,1), subsSubReg_TC.aMTC(:,2), subsSubReg_TC.aMTC(:,3));
idx_eMTC = sub2ind(size_img, subsSubReg_TC.eMTC(:,1), subsSubReg_TC.eMTC(:,2), subsSubReg_TC.eMTC(:,3));
idx_pMTC = sub2ind(size_img, subsSubReg_TC.pMTC(:,1), subsSubReg_TC.pMTC(:,2), subsSubReg_TC.pMTC(:,3));
idx_iMTC = sub2ind(size_img, subsSubReg_TC.iMTC(:,1), subsSubReg_TC.iMTC(:,2), subsSubReg_TC.iMTC(:,3));
idx_cMTC = sub2ind(size_img, subsSubReg_TC.cMTC(:,1), subsSubReg_TC.cMTC(:,2), subsSubReg_TC.cMTC(:,3));
idx_aLTC = sub2ind(size_img, subsSubReg_TC.aLTC(:,1), subsSubReg_TC.aLTC(:,2), subsSubReg_TC.aLTC(:,3));
idx_eLTC = sub2ind(size_img, subsSubReg_TC.eLTC(:,1), subsSubReg_TC.eLTC(:,2), subsSubReg_TC.eLTC(:,3));
idx_pLTC = sub2ind(size_img, subsSubReg_TC.pLTC(:,1), subsSubReg_TC.pLTC(:,2), subsSubReg_TC.pLTC(:,3));
idx_iLTC = sub2ind(size_img, subsSubReg_TC.iLTC(:,1), subsSubReg_TC.iLTC(:,2), subsSubReg_TC.iLTC(:,3));
idx_cLTC = sub2ind(size_img, subsSubReg_TC.cLTC(:,1), subsSubReg_TC.cLTC(:,2), subsSubReg_TC.cLTC(:,3));
atlas(idx_aMTC) = 11;
atlas(idx_eMTC) = 12;
atlas(idx_pMTC) = 13;
atlas(idx_iMTC) = 14;
atlas(idx_cMTC) = 15;
atlas(idx_aLTC) = 16;
atlas(idx_eLTC) = 17;
atlas(idx_pLTC) = 18;
atlas(idx_iLTC) = 19;
atlas(idx_cLTC) = 20;
% ---------------------------------------------------------

end