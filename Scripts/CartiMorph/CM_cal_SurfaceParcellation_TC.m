function [versSubReg_iC_TC, versSubReg_scB_TC, meshSubReg_iC_TC, meshSubReg_scB_TC] = CM_cal_SurfaceParcellation_TC( ...
    mesh_iC_LTC, ...
    mesh_iC_MTC, ...
    mesh_scB_LTC, ...
    mesh_scB_MTC, ...
    size_voxel, ...
    knee_side)
% ==============================================================================
% FUNCTION:
%     Cartilage parcellation of FC.
%
% INPUT:
%     - mesh_iC_LTC: interior cartilage surface of LTC
%     - mesh_iC_MTC: interior cartilage surface of MTC
%     - mesh_scB_LTC: subchondral bone surface of LTC
%     - mesh_scB_MTC: subchondral bone surface of MTC
%     - size_voxel: voxel size
%     - knee_side: knee side, must be one of {"left", "right"}
%
% OUTPUT:
%     - versSubReg_iC_TC: [structure], vertices on the interior cartilage surface of TC
%     - versSubReg_scB_TC: [structure], vertices on the subchondral bone surface of TC
%     - meshSubReg_iC_TC: [structure], the interior cartilage surface of TC
%     - meshSubReg_scB_TC: [structure], the subchondral bone surface of TC
% ------------------------------------------------------------------------------
% Matlab Version: 2019b or later
%
% Last updated on: 17-Sep-2022
%
% Author:
% Yongcheng YAO (yao_yongcheng@link.cuhk.edu.hk)
% Department of Imaging and Interventional Radiology,
% Chinese University of Hong Kong (CUHK)
%
% Copyright 2020 Yongcheng YAO
% ------------------------------------------------------------------------------
% ==============================================================================

%% Preparing
% interior cartilage surface for MTC
faces_iC_MTC = mesh_iC_MTC.faces;
vers_iC_MTC = mesh_iC_MTC.vertices;
subs_iC_MTC = round(vers_iC_MTC ./ size_voxel);

% subchondral bone surface for MTC
faces_scB_MTC = mesh_scB_MTC.faces;
vers_scB_MTC = mesh_scB_MTC.vertices;
subs_scB_MTC = round(vers_scB_MTC ./ size_voxel);

% interior cartilage surface for LTC
faces_iC_LTC = mesh_iC_LTC.faces;
vers_iC_LTC = mesh_iC_LTC.vertices;
subs_iC_LTC = round(vers_iC_LTC ./ size_voxel);

% subchondral bone surface for LTC
faces_scB_LTC = mesh_scB_LTC.faces;
vers_scB_LTC = mesh_scB_LTC.vertices;
subs_scB_LTC = round(vers_scB_LTC ./ size_voxel);



%% Parcellate subchondral bone area of TC -- "filled TC"
% ---------------------------------------------------------
% Locate cMTC
% ---------------------------------------------------------
% translation
center_scB_MTC = mean(vers_scB_MTC, 1);
vers_scB_MTC_c = vers_scB_MTC - center_scB_MTC;
% SVD
[~, S, V] = svd(vers_scB_MTC_c, 0);
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
fake_angles_sigV22RAS(direction_sigV1) = 90;
[~, direction_sigV2] = min(fake_angles_sigV22RAS);
fake_angles_sigV32RAS = angles_sigV32RAS;
fake_angles_sigV32RAS(direction_sigV1) = 90;
fake_angles_sigV32RAS(direction_sigV2) = 90;
[~, direction_sigV3] = min(fake_angles_sigV32RAS);
absDirection_sigV123 = [direction_sigV1, direction_sigV2, direction_sigV3];
% .........................................................

% transformation
transMat_scB_MTC(:, direction_sigV1) = sigV1;
transMat_scB_MTC(:, direction_sigV2) = sigV2;
transMat_scB_MTC(:, direction_sigV3) = sigV3;
transMat_scB_MTC(:,diag(transMat_scB_MTC)<0) = transMat_scB_MTC(:,diag(transMat_scB_MTC)<0) * -1;
vers_scB_MTC_ct = transpose(transMat_scB_MTC \ vers_scB_MTC_c');

% initial parcellation of cMTL
tmpA = 5;
tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
tmpX = vers_scB_MTC_ct(:,1);
tmpY = vers_scB_MTC_ct(:,2);
idx_scB_cMTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
vers_scB_cMTC_ct = vers_scB_MTC_ct(idx_scB_cMTC, :);
vers_scB_cMTC_c = transpose(transMat_scB_MTC * vers_scB_cMTC_ct');
vers_scB_cMTC = vers_scB_cMTC_c + center_scB_MTC;

% adjust the cMTL untill it covers 20% area of the MTL
area_scB_MTC = sum(CM_quant_triMeshArea(vers_scB_MTC, faces_scB_MTC));
faces_scB_cMTC = CM_cal_extractFaces_OR(faces_scB_MTC, vers_scB_MTC, vers_scB_cMTC);
area_scB_cMTC = sum(CM_quant_triMeshArea(vers_scB_MTC, faces_scB_cMTC));
recorder_osillation = 0;
counter_Act = 0;
while abs(area_scB_cMTC/area_scB_MTC - 0.2)>0.005 && recorder_osillation<1000
    if area_scB_cMTC/area_scB_MTC > 0.2
        counter_Act = counter_Act + 1;
        % new cMTL
        tmpA = tmpA - 0.5;
        tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
        tmpX = vers_scB_MTC_ct(:,1);
        tmpY = vers_scB_MTC_ct(:,2);
        idx_scB_cMTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_scB_cMTC_ct = vers_scB_MTC_ct(idx_scB_cMTC, :);
        vers_scB_cMTC_c = transpose(transMat_scB_MTC * vers_scB_cMTC_ct');
        vers_scB_cMTC = vers_scB_cMTC_c + center_scB_MTC;
        % new cMTL area
        faces_scB_cMTC = CM_cal_extractFaces_OR(faces_scB_MTC, vers_scB_MTC, vers_scB_cMTC);
        area_scB_cMTC = sum(CM_quant_triMeshArea(vers_scB_MTC, faces_scB_cMTC));
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
        tmpX = vers_scB_MTC_ct(:,1);
        tmpY = vers_scB_MTC_ct(:,2);
        idx_scB_cMTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_scB_cMTC_ct = vers_scB_MTC_ct(idx_scB_cMTC, :);
        vers_scB_cMTC_c = transpose(transMat_scB_MTC * vers_scB_cMTC_ct');
        vers_scB_cMTC = vers_scB_cMTC_c + center_scB_MTC;
        % new cMTL area
        faces_scB_cMTC = CM_cal_extractFaces_OR(faces_scB_MTC, vers_scB_MTC, vers_scB_cMTC);
        area_scB_cMTC = sum(CM_quant_triMeshArea(vers_scB_MTC, faces_scB_cMTC));
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
subs_scB_cMTC = round(vers_scB_cMTC ./ size_voxel);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate cLTC
% ---------------------------------------------------------
% translation
center_scB_LTC = mean(vers_scB_LTC, 1);
vers_scB_LTC_c = vers_scB_LTC - center_scB_LTC;
% SVD
[~, S, V] = svd(vers_scB_LTC_c, 0);
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
fake_angles_sigV22RAS(direction_sigV1) = 90;
[~, direction_sigV2] = min(fake_angles_sigV22RAS);
fake_angles_sigV32RAS = angles_sigV32RAS;
fake_angles_sigV32RAS(direction_sigV1) = 90;
fake_angles_sigV32RAS(direction_sigV2) = 90;
[~, direction_sigV3] = min(fake_angles_sigV32RAS);
absDirection_sigV123 = [direction_sigV1, direction_sigV2, direction_sigV3];
% .........................................................

% transformation
transMat_scB_LTC(:, direction_sigV1) = sigV1;
transMat_scB_LTC(:, direction_sigV2) = sigV2;
transMat_scB_LTC(:, direction_sigV3) = sigV3;
transMat_scB_LTC(:,diag(transMat_scB_LTC)<0) = transMat_scB_LTC(:,diag(transMat_scB_LTC)<0) * -1;
vers_scB_LTC_ct = transpose(transMat_scB_LTC \ vers_scB_LTC_c');

% initial parcellation of cMTL
tmpA = 5;
tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
tmpX = vers_scB_LTC_ct(:,1);
tmpY = vers_scB_LTC_ct(:,2);
idx_scB_cLTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
vers_scB_cLTC_ct = vers_scB_LTC_ct(idx_scB_cLTC, :);
vers_scB_cLTC_c = transpose(transMat_scB_LTC * vers_scB_cLTC_ct');
vers_scB_cLTC = vers_scB_cLTC_c + center_scB_LTC;

% adjust the cMTL untill it covers 20% area of the MTL
area_scB_LTC = sum(CM_quant_triMeshArea(vers_scB_LTC, faces_scB_LTC));
faces_scB_cLTC = CM_cal_extractFaces_OR(faces_scB_LTC, vers_scB_LTC, vers_scB_cLTC);
area_scB_cLTC = sum(CM_quant_triMeshArea(vers_scB_LTC, faces_scB_cLTC));
recorder_osillation = 0;
counter_Act = 0;
while abs(area_scB_cLTC/area_scB_LTC - 0.2)>0.005 && recorder_osillation<1000
    if area_scB_cLTC/area_scB_LTC > 0.2
        counter_Act = counter_Act + 1;
        % new cMTL
        tmpA = tmpA - 0.5;
        tmpB = tmpA * sqrt(diagS(absDirection_sigV123==2) / diagS(absDirection_sigV123==1));
        tmpX = vers_scB_LTC_ct(:,1);
        tmpY = vers_scB_LTC_ct(:,2);
        idx_scB_cLTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_scB_cLTC_ct = vers_scB_LTC_ct(idx_scB_cLTC, :);
        vers_scB_cLTC_c = transpose(transMat_scB_LTC * vers_scB_cLTC_ct');
        vers_scB_cLTC = vers_scB_cLTC_c + center_scB_LTC;
        % new cMTL area
        faces_scB_cLTC = CM_cal_extractFaces_OR(faces_scB_LTC, vers_scB_LTC, vers_scB_cLTC);
        area_scB_cLTC = sum(CM_quant_triMeshArea(vers_scB_LTC, faces_scB_cLTC));
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
        tmpX = vers_scB_LTC_ct(:,1);
        tmpY = vers_scB_LTC_ct(:,2);
        idx_scB_cLTC = (tmpX.^2 ./ tmpA^2 + tmpY.^2 ./ tmpB^2 - 1)<0;
        vers_scB_cLTC_ct = vers_scB_LTC_ct(idx_scB_cLTC, :);
        vers_scB_cLTC_c = transpose(transMat_scB_LTC * vers_scB_cLTC_ct');
        vers_scB_cLTC = vers_scB_cLTC_c + center_scB_LTC;
        % new cMTL area
        faces_scB_cLTC = CM_cal_extractFaces_OR(faces_scB_LTC, vers_scB_LTC, vers_scB_cLTC);
        area_scB_cLTC = sum(CM_quant_triMeshArea(vers_scB_LTC, faces_scB_cLTC));
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
subs_scB_cLTC = round(vers_scB_cLTC ./ size_voxel);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aMTC, pMTC, iMTC, eMTC
% ---------------------------------------------------------
% centered and translated non-cMTC
vers_scB_noncMTC_ct = vers_scB_MTC_ct(~idx_scB_cMTC, :);
% lTC centered to the centroid of mTC and translated to eigen-vectors of mTC
center_scB_LTC_c2MTC = center_scB_LTC - center_scB_MTC;
center_scB_LTC_c2MTC_t = transpose(transMat_scB_MTC \ center_scB_LTC_c2MTC');
% define cutting line 1 in x-y plane
a1 = 45;
transMat_scB_MTC_U1 = [cosd(a1), -sind(a1), 0; sind(a1), cosd(a1), 0; 0, 0, 1];
vect1_scB_MTC2LTC_t = transMat_scB_MTC_U1 * center_scB_LTC_c2MTC_t';
k1_scB_MTC = vect1_scB_MTC2LTC_t(2) / vect1_scB_MTC2LTC_t(1);
% define cutting line 2 in x-y plane
a2 = -45;
transMat_scB_MTC_U2 = [cosd(a2), -sind(a2), 0; sind(a2), cosd(a2), 0; 0, 0, 1];
vect2_scB_MTC2LTC_t = transMat_scB_MTC_U2 * center_scB_LTC_c2MTC_t';
k2_scB_MTC = vect2_scB_MTC2LTC_t(2) / vect2_scB_MTC2LTC_t(1);
% cut the non-mTC region into 4 clusters (ROIs)
idx_scB_C1_MTC = vers_scB_noncMTC_ct(:,2) > k1_scB_MTC*vers_scB_noncMTC_ct(:,1) & ...
    vers_scB_noncMTC_ct(:,2) > k2_scB_MTC*vers_scB_noncMTC_ct(:,1);
idx_scB_C2_MTC = vers_scB_noncMTC_ct(:,2) < k1_scB_MTC*vers_scB_noncMTC_ct(:,1) & ...
    vers_scB_noncMTC_ct(:,2) < k2_scB_MTC*vers_scB_noncMTC_ct(:,1);
idx_scB_C3_MTC = vers_scB_noncMTC_ct(:,2) <= k1_scB_MTC*vers_scB_noncMTC_ct(:,1) & ...
    vers_scB_noncMTC_ct(:,2) >= k2_scB_MTC*vers_scB_noncMTC_ct(:,1);
idx_scB_C4_MTC = vers_scB_noncMTC_ct(:,2) >= k1_scB_MTC*vers_scB_noncMTC_ct(:,1) & ...
    vers_scB_noncMTC_ct(:,2) <= k2_scB_MTC*vers_scB_noncMTC_ct(:,1);
vers_scB_C1_MTC_ct = vers_scB_noncMTC_ct(idx_scB_C1_MTC, :);
vers_scB_C2_MTC_ct = vers_scB_noncMTC_ct(idx_scB_C2_MTC, :);
vers_scB_C3_MTC_ct = vers_scB_noncMTC_ct(idx_scB_C3_MTC, :);
vers_scB_C4_MTC_ct = vers_scB_noncMTC_ct(idx_scB_C4_MTC, :);
vers_scB_C1_MTC = transpose(transMat_scB_MTC * vers_scB_C1_MTC_ct') + center_scB_MTC;
vers_scB_C2_MTC = transpose(transMat_scB_MTC * vers_scB_C2_MTC_ct') + center_scB_MTC;
vers_scB_C3_MTC = transpose(transMat_scB_MTC * vers_scB_C3_MTC_ct') + center_scB_MTC;
vers_scB_C4_MTC = transpose(transMat_scB_MTC * vers_scB_C4_MTC_ct') + center_scB_MTC;
vers_scB_Clusters_MTC = {vers_scB_C1_MTC, vers_scB_C2_MTC, vers_scB_C3_MTC, vers_scB_C4_MTC};
% assign label to each cluster (assuming RAS+ orientation)
centerCluster_MTC(1, :) = mean(vers_scB_C1_MTC, 1);
centerCluster_MTC(2, :) = mean(vers_scB_C2_MTC, 1);
centerCluster_MTC(3, :) = mean(vers_scB_C3_MTC, 1);
centerCluster_MTC(4, :) = mean(vers_scB_C4_MTC, 1);
[~, idx_aMTC] = max(centerCluster_MTC(:, 2));
[~, idx_pMTC] = min(centerCluster_MTC(:, 2));
[~, idx_iMTC] = max(centerCluster_MTC(:, 1));
[~, idx_eMTC] = min(centerCluster_MTC(:, 1));
vers_scB_aMTC = vers_scB_Clusters_MTC{idx_aMTC};
vers_scB_pMTC = vers_scB_Clusters_MTC{idx_pMTC};
vers_scB_iMTC = vers_scB_Clusters_MTC{idx_iMTC};
vers_scB_eMTC = vers_scB_Clusters_MTC{idx_eMTC};
subs_scB_aMTC = round(vers_scB_aMTC ./ size_voxel);
subs_scB_pMTC = round(vers_scB_pMTC ./ size_voxel);
subs_scB_iMTC = round(vers_scB_iMTC ./ size_voxel);
subs_scB_eMTC = round(vers_scB_eMTC ./ size_voxel);
% ---------------------------------------------------------


% ---------------------------------------------------------
% Locate aLTC, pLTC, iLTC, eLTC
% ---------------------------------------------------------
% centered and translated non-cLTC
vers_scB_noncLTC_ct = vers_scB_LTC_ct(~idx_scB_cLTC, :);
% mTC centered to the centroid of lTC and translated to eigen-vectors of lTC
center_scB_MTC_c2LTC = center_scB_MTC - center_scB_LTC;
center_scB_MTC_c2LTC_t = transpose(transMat_scB_LTC \ center_scB_MTC_c2LTC');
% define cutting line 1 in x-y plane
a1 = 45;
transMat_scB_LTC_U1 = [cosd(a1), -sind(a1), 0; sind(a1), cosd(a1), 0; 0, 0, 1];
vect1_scB_LTC2MTC_t = transMat_scB_LTC_U1 * center_scB_MTC_c2LTC_t';
k1_scB_LTC = vect1_scB_LTC2MTC_t(2) / vect1_scB_LTC2MTC_t(1);
% define cutting line 2 in x-y plane
a2 = -45;
transMat_scB_LTC_U2 = [cosd(a2), -sind(a2), 0; sind(a2), cosd(a2), 0; 0, 0, 1];
vect2_scB_LTC2MTC_t = transMat_scB_LTC_U2 * center_scB_MTC_c2LTC_t';
k2_scB_LTC = vect2_scB_LTC2MTC_t(2) / vect2_scB_LTC2MTC_t(1);
% cut the non-lTC region into 4 clusters (ROIs)
idx_scB_C1_LTC = vers_scB_noncLTC_ct(:,2) > k1_scB_LTC*vers_scB_noncLTC_ct(:,1) & ...
    vers_scB_noncLTC_ct(:,2) > k2_scB_LTC*vers_scB_noncLTC_ct(:,1);
idx_scB_C2_LTC = vers_scB_noncLTC_ct(:,2) < k1_scB_LTC*vers_scB_noncLTC_ct(:,1) & ...
    vers_scB_noncLTC_ct(:,2) < k2_scB_LTC*vers_scB_noncLTC_ct(:,1);
idx_scB_C3_LTC = vers_scB_noncLTC_ct(:,2) <= k1_scB_LTC*vers_scB_noncLTC_ct(:,1) & ...
    vers_scB_noncLTC_ct(:,2) >= k2_scB_LTC*vers_scB_noncLTC_ct(:,1);
idx_scB_C4_LTC = vers_scB_noncLTC_ct(:,2) >= k1_scB_LTC*vers_scB_noncLTC_ct(:,1) & ...
    vers_scB_noncLTC_ct(:,2) <= k2_scB_LTC*vers_scB_noncLTC_ct(:,1);
vers_scB_C1_LTC_ct = vers_scB_noncLTC_ct(idx_scB_C1_LTC, :);
vers_scB_C2_LTC_ct = vers_scB_noncLTC_ct(idx_scB_C2_LTC, :);
vers_scB_C3_LTC_ct = vers_scB_noncLTC_ct(idx_scB_C3_LTC, :);
vers_scB_C4_LTC_ct = vers_scB_noncLTC_ct(idx_scB_C4_LTC, :);
vers_scB_C1_LTC = transpose(transMat_scB_LTC * vers_scB_C1_LTC_ct') + center_scB_LTC;
vers_scB_C2_LTC = transpose(transMat_scB_LTC * vers_scB_C2_LTC_ct') + center_scB_LTC;
vers_scB_C3_LTC = transpose(transMat_scB_LTC * vers_scB_C3_LTC_ct') + center_scB_LTC;
vers_scB_C4_LTC = transpose(transMat_scB_LTC * vers_scB_C4_LTC_ct') + center_scB_LTC;
vers_scB_Clusters_LTC = {vers_scB_C1_LTC, vers_scB_C2_LTC, vers_scB_C3_LTC, vers_scB_C4_LTC};
% assign label to each cluster (assuming RAS+ orientation)
centerCluster_LTC(1, :) = mean(vers_scB_C1_LTC, 1);
centerCluster_LTC(2, :) = mean(vers_scB_C2_LTC, 1);
centerCluster_LTC(3, :) = mean(vers_scB_C3_LTC, 1);
centerCluster_LTC(4, :) = mean(vers_scB_C4_LTC, 1);
[~, idx_aLTC] = max(centerCluster_LTC(:, 2));
[~, idx_pLTC] = min(centerCluster_LTC(:, 2));
[~, idx_eLTC] = max(centerCluster_LTC(:, 1));
[~, idx_iLTC] = min(centerCluster_LTC(:, 1));
vers_scB_aLTC = vers_scB_Clusters_LTC{idx_aLTC};
vers_scB_pLTC = vers_scB_Clusters_LTC{idx_pLTC};
vers_scB_iLTC = vers_scB_Clusters_LTC{idx_iLTC};
vers_scB_eLTC = vers_scB_Clusters_LTC{idx_eLTC};
subs_scB_aLTC = round(vers_scB_aLTC ./ size_voxel);
subs_scB_pLTC = round(vers_scB_pLTC ./ size_voxel);
subs_scB_iLTC = round(vers_scB_iLTC ./ size_voxel);
subs_scB_eLTC = round(vers_scB_eLTC ./ size_voxel);
% ---------------------------------------------------------



%% Parcellate TC
vers_iC_cMTC = vers_iC_MTC(ismember(subs_iC_MTC, subs_scB_cMTC, 'rows'), :);
vers_iC_aMTC = vers_iC_MTC(ismember(subs_iC_MTC, subs_scB_aMTC, 'rows'), :);
vers_iC_pMTC = vers_iC_MTC(ismember(subs_iC_MTC, subs_scB_pMTC, 'rows'), :);
vers_iC_iMTC = vers_iC_MTC(ismember(subs_iC_MTC, subs_scB_iMTC, 'rows'), :);
vers_iC_eMTC = vers_iC_MTC(ismember(subs_iC_MTC, subs_scB_eMTC, 'rows'), :);
vers_iC_cLTC = vers_iC_LTC(ismember(subs_iC_LTC, subs_scB_cLTC, 'rows'), :);
vers_iC_aLTC = vers_iC_LTC(ismember(subs_iC_LTC, subs_scB_aLTC, 'rows'), :);
vers_iC_pLTC = vers_iC_LTC(ismember(subs_iC_LTC, subs_scB_pLTC, 'rows'), :);
vers_iC_iLTC = vers_iC_LTC(ismember(subs_iC_LTC, subs_scB_iLTC, 'rows'), :);
vers_iC_eLTC = vers_iC_LTC(ismember(subs_iC_LTC, subs_scB_eLTC, 'rows'), :);
subs_iC_cMTC = subs_iC_MTC(ismember(subs_iC_MTC, subs_scB_cMTC, 'rows'), :);
subs_iC_aMTC = subs_iC_MTC(ismember(subs_iC_MTC, subs_scB_aMTC, 'rows'), :);
subs_iC_pMTC = subs_iC_MTC(ismember(subs_iC_MTC, subs_scB_pMTC, 'rows'), :);
subs_iC_iMTC = subs_iC_MTC(ismember(subs_iC_MTC, subs_scB_iMTC, 'rows'), :);
subs_iC_eMTC = subs_iC_MTC(ismember(subs_iC_MTC, subs_scB_eMTC, 'rows'), :);
subs_iC_cLTC = subs_iC_LTC(ismember(subs_iC_LTC, subs_scB_cLTC, 'rows'), :);
subs_iC_aLTC = subs_iC_LTC(ismember(subs_iC_LTC, subs_scB_aLTC, 'rows'), :);
subs_iC_pLTC = subs_iC_LTC(ismember(subs_iC_LTC, subs_scB_pLTC, 'rows'), :);
subs_iC_iLTC = subs_iC_LTC(ismember(subs_iC_LTC, subs_scB_iLTC, 'rows'), :);
subs_iC_eLTC = subs_iC_LTC(ismember(subs_iC_LTC, subs_scB_eLTC, 'rows'), :);



%% Extract faces of each subregion
% TC with recovered full-thickness cartilage loss
faces_scB_cMTC = CM_cal_extractFaces_OR(faces_scB_MTC, subs_scB_MTC, subs_scB_cMTC);
[Mesh_scB_cMTC.vertices, Mesh_scB_cMTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_MTC, faces_scB_cMTC);
faces_scB_aMTC = CM_cal_extractFaces_OR(faces_scB_MTC, subs_scB_MTC, subs_scB_aMTC);
[Mesh_scB_aMTC.vertices, Mesh_scB_aMTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_MTC, faces_scB_aMTC);
faces_scB_pMTC = CM_cal_extractFaces_OR(faces_scB_MTC, subs_scB_MTC, subs_scB_pMTC);
[Mesh_scB_pMTC.vertices, Mesh_scB_pMTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_MTC, faces_scB_pMTC);
faces_scB_iMTC = CM_cal_extractFaces_OR(faces_scB_MTC, subs_scB_MTC, subs_scB_iMTC);
[Mesh_scB_iMTC.vertices, Mesh_scB_iMTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_MTC, faces_scB_iMTC);
faces_scB_eMTC = CM_cal_extractFaces_OR(faces_scB_MTC, subs_scB_MTC, subs_scB_eMTC);
[Mesh_scB_eMTC.vertices, Mesh_scB_eMTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_MTC, faces_scB_eMTC);
faces_scB_cLTC = CM_cal_extractFaces_OR(faces_scB_LTC, subs_scB_LTC, subs_scB_cLTC);
[Mesh_scB_cLTC.vertices, Mesh_scB_cLTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_LTC, faces_scB_cLTC);
faces_scB_aLTC = CM_cal_extractFaces_OR(faces_scB_LTC, subs_scB_LTC, subs_scB_aLTC);
[Mesh_scB_aLTC.vertices, Mesh_scB_aLTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_LTC, faces_scB_aLTC);
faces_scB_pLTC = CM_cal_extractFaces_OR(faces_scB_LTC, subs_scB_LTC, subs_scB_pLTC);
[Mesh_scB_pLTC.vertices, Mesh_scB_pLTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_LTC, faces_scB_pLTC);
faces_scB_iLTC = CM_cal_extractFaces_OR(faces_scB_LTC, subs_scB_LTC, subs_scB_iLTC);
[Mesh_scB_iLTC.vertices, Mesh_scB_iLTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_LTC, faces_scB_iLTC);
faces_scB_eLTC = CM_cal_extractFaces_OR(faces_scB_LTC, subs_scB_LTC, subs_scB_eLTC);
[Mesh_scB_eLTC.vertices, Mesh_scB_eLTC.faces] = MPT_remove_unreferenced_vertices(vers_scB_LTC, faces_scB_eLTC);

% original FC
if ~isempty(subs_iC_cMTC)
    faces_iC_cMTC = CM_cal_extractFaces_OR(faces_iC_MTC, subs_iC_MTC, subs_iC_cMTC);
    [Mesh_iC_cMTC.vertices, Mesh_iC_cMTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_MTC, faces_iC_cMTC);
else
    Mesh_iC_cMTC = [];
end

if ~isempty(subs_iC_aMTC)
    faces_iC_aMTC = CM_cal_extractFaces_OR(faces_iC_MTC, subs_iC_MTC, subs_iC_aMTC);
    [Mesh_iC_aMTC.vertices, Mesh_iC_aMTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_MTC, faces_iC_aMTC);
else
    Mesh_iC_aMTC = [];
end

if ~isempty(subs_iC_pMTC)
    faces_iC_pMTC = CM_cal_extractFaces_OR(faces_iC_MTC, subs_iC_MTC, subs_iC_pMTC);
    [Mesh_iC_pMTC.vertices, Mesh_iC_pMTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_MTC, faces_iC_pMTC);
else
    Mesh_iC_pMTC = [];
end

if ~isempty(subs_iC_iMTC)
    faces_iC_iMTC = CM_cal_extractFaces_OR(faces_iC_MTC, subs_iC_MTC, subs_iC_iMTC);
    [Mesh_iC_iMTC.vertices, Mesh_iC_iMTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_MTC, faces_iC_iMTC);
else
    Mesh_iC_iMTC = [];
end

if ~isempty(subs_iC_eMTC)
    faces_iC_eMTC = CM_cal_extractFaces_OR(faces_iC_MTC, subs_iC_MTC, subs_iC_eMTC);
    [Mesh_iC_eMTC.vertices, Mesh_iC_eMTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_MTC, faces_iC_eMTC);
else
    Mesh_iC_eMTC = [];
end

if ~isempty(subs_iC_cLTC)
    faces_iC_cLTC = CM_cal_extractFaces_OR(faces_iC_LTC, subs_iC_LTC, subs_iC_cLTC);
    [Mesh_iC_cLTC.vertices, Mesh_iC_cLTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_LTC, faces_iC_cLTC);
else
    Mesh_iC_cLTC = [];
end

if ~isempty(subs_iC_aLTC)
    faces_iC_aLTC = CM_cal_extractFaces_OR(faces_iC_LTC, subs_iC_LTC, subs_iC_aLTC);
    [Mesh_iC_aLTC.vertices, Mesh_iC_aLTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_LTC, faces_iC_aLTC);
else
    Mesh_iC_aLTC = [];
end

if ~isempty(subs_iC_pLTC)
    faces_iC_pLTC = CM_cal_extractFaces_OR(faces_iC_LTC, subs_iC_LTC, subs_iC_pLTC);
    [Mesh_iC_pLTC.vertices, Mesh_iC_pLTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_LTC, faces_iC_pLTC);
else
    Mesh_iC_pLTC = [];
end

if ~isempty(subs_iC_iLTC)
    faces_iC_iLTC = CM_cal_extractFaces_OR(faces_iC_LTC, subs_iC_LTC, subs_iC_iLTC);
    [Mesh_iC_iLTC.vertices, Mesh_iC_iLTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_LTC, faces_iC_iLTC);
else
    Mesh_iC_iLTC = [];
end

if ~isempty(subs_iC_eLTC)
    faces_iC_eLTC = CM_cal_extractFaces_OR(faces_iC_LTC, subs_iC_LTC, subs_iC_eLTC);
    [Mesh_iC_eLTC.vertices, Mesh_iC_eLTC.faces] = MPT_remove_unreferenced_vertices(vers_iC_LTC, faces_iC_eLTC);
else
    Mesh_iC_eLTC = [];
end


%% Combine results
switch knee_side
    case "right"
        %% Vertices
        % TC with recovered full-thickness cartilage loss
        versSubReg_scB_TC.cMTC = vers_scB_cMTC;
        versSubReg_scB_TC.aMTC = vers_scB_aMTC;
        versSubReg_scB_TC.pMTC = vers_scB_pMTC;
        versSubReg_scB_TC.iMTC = vers_scB_iMTC;
        versSubReg_scB_TC.eMTC = vers_scB_eMTC;
        versSubReg_scB_TC.cLTC = vers_scB_cLTC;
        versSubReg_scB_TC.aLTC = vers_scB_aLTC;
        versSubReg_scB_TC.pLTC = vers_scB_pLTC;
        versSubReg_scB_TC.iLTC = vers_scB_iLTC;
        versSubReg_scB_TC.eLTC = vers_scB_eLTC;
        % original TC
        versSubReg_iC_TC.cMTC = vers_iC_cMTC;
        versSubReg_iC_TC.aMTC = vers_iC_aMTC;
        versSubReg_iC_TC.pMTC = vers_iC_pMTC;
        versSubReg_iC_TC.iMTC = vers_iC_iMTC;
        versSubReg_iC_TC.eMTC = vers_iC_eMTC;
        versSubReg_iC_TC.cLTC = vers_iC_cLTC;
        versSubReg_iC_TC.aLTC = vers_iC_aLTC;
        versSubReg_iC_TC.pLTC = vers_iC_pLTC;
        versSubReg_iC_TC.iLTC = vers_iC_iLTC;
        versSubReg_iC_TC.eLTC = vers_iC_eLTC;

        %% Mesh
        % TC with recovered full-thickness cartilage loss
        meshSubReg_scB_TC.cMTC = Mesh_scB_cMTC;
        meshSubReg_scB_TC.aMTC = Mesh_scB_aMTC;
        meshSubReg_scB_TC.pMTC = Mesh_scB_pMTC;
        meshSubReg_scB_TC.iMTC = Mesh_scB_iMTC;
        meshSubReg_scB_TC.eMTC = Mesh_scB_eMTC;
        meshSubReg_scB_TC.cLTC = Mesh_scB_cLTC;
        meshSubReg_scB_TC.aLTC = Mesh_scB_aLTC;
        meshSubReg_scB_TC.pLTC = Mesh_scB_pLTC;
        meshSubReg_scB_TC.iLTC = Mesh_scB_iLTC;
        meshSubReg_scB_TC.eLTC = Mesh_scB_eLTC;
        % original TC
        meshSubReg_iC_TC.cMTC = Mesh_iC_cMTC;
        meshSubReg_iC_TC.aMTC = Mesh_iC_aMTC;
        meshSubReg_iC_TC.pMTC = Mesh_iC_pMTC;
        meshSubReg_iC_TC.iMTC = Mesh_iC_iMTC;
        meshSubReg_iC_TC.eMTC = Mesh_iC_eMTC;
        meshSubReg_iC_TC.cLTC = Mesh_iC_cLTC;
        meshSubReg_iC_TC.aLTC = Mesh_iC_aLTC;
        meshSubReg_iC_TC.pLTC = Mesh_iC_pLTC;
        meshSubReg_iC_TC.iLTC = Mesh_iC_iLTC;
        meshSubReg_iC_TC.eLTC = Mesh_iC_eLTC;

    case "left"
        %% Vertices
        % TC with recovered full-thickness cartilage loss
        versSubReg_scB_TC.cMTC = vers_scB_cLTC;
        versSubReg_scB_TC.aMTC = vers_scB_aLTC;
        versSubReg_scB_TC.pMTC = vers_scB_pLTC;
        versSubReg_scB_TC.iMTC = vers_scB_eLTC;
        versSubReg_scB_TC.eMTC = vers_scB_iLTC;
        versSubReg_scB_TC.cLTC = vers_scB_cMTC;
        versSubReg_scB_TC.aLTC = vers_scB_aMTC;
        versSubReg_scB_TC.pLTC = vers_scB_pMTC;
        versSubReg_scB_TC.iLTC = vers_scB_eMTC;
        versSubReg_scB_TC.eLTC = vers_scB_iMTC;
        % original TC
        versSubReg_iC_TC.cMTC = vers_iC_cLTC;
        versSubReg_iC_TC.aMTC = vers_iC_aLTC;
        versSubReg_iC_TC.pMTC = vers_iC_pLTC;
        versSubReg_iC_TC.iMTC = vers_iC_eLTC;
        versSubReg_iC_TC.eMTC = vers_iC_iLTC;
        versSubReg_iC_TC.cLTC = vers_iC_cMTC;
        versSubReg_iC_TC.aLTC = vers_iC_aMTC;
        versSubReg_iC_TC.pLTC = vers_iC_pMTC;
        versSubReg_iC_TC.iLTC = vers_iC_eMTC;
        versSubReg_iC_TC.eLTC = vers_iC_iMTC;

        %% Mesh
        % TC with recovered full-thickness cartilage loss
        meshSubReg_scB_TC.cMTC = Mesh_scB_cLTC;
        meshSubReg_scB_TC.aMTC = Mesh_scB_aLTC;
        meshSubReg_scB_TC.pMTC = Mesh_scB_pLTC;
        meshSubReg_scB_TC.iMTC = Mesh_scB_eLTC;
        meshSubReg_scB_TC.eMTC = Mesh_scB_iLTC;
        meshSubReg_scB_TC.cLTC = Mesh_scB_cMTC;
        meshSubReg_scB_TC.aLTC = Mesh_scB_aMTC;
        meshSubReg_scB_TC.pLTC = Mesh_scB_pMTC;
        meshSubReg_scB_TC.iLTC = Mesh_scB_eMTC;
        meshSubReg_scB_TC.eLTC = Mesh_scB_iMTC;
        % original TC
        meshSubReg_iC_TC.cMTC = Mesh_iC_cLTC;
        meshSubReg_iC_TC.aMTC = Mesh_iC_aLTC;
        meshSubReg_iC_TC.pMTC = Mesh_iC_pLTC;
        meshSubReg_iC_TC.iMTC = Mesh_iC_eLTC;
        meshSubReg_iC_TC.eMTC = Mesh_iC_iLTC;
        meshSubReg_iC_TC.cLTC = Mesh_iC_cMTC;
        meshSubReg_iC_TC.aLTC = Mesh_iC_aMTC;
        meshSubReg_iC_TC.pLTC = Mesh_iC_pMTC;
        meshSubReg_iC_TC.iLTC = Mesh_iC_eMTC;
        meshSubReg_iC_TC.eLTC = Mesh_iC_iMTC;
end

end