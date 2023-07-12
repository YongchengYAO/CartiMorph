function img_out = CM_imgPreprocess_resample(img_in, imgSize_out, method, datatype)

n_dims = length(imgSize_out);
imgSize_in = size(img_in);

if n_dims==2
    % define grid
    xg = 0.5:imgSize_in(1)-0.5;
    yg = 0.5:imgSize_in(2)-0.5;
    % define gridded interpolator
    F = griddedInterpolant({xg, yg}, double(img_in));
    F.Method = method;
    % define query points
    xq = transpose(0.5:(imgSize_in(1)-1)/(imgSize_out(1)-1):imgSize_in(1)-0.5);
    yq = transpose(0.5:(imgSize_in(2)-1)/(imgSize_out(2)-1):imgSize_in(2)-0.5);
    img_out = (F({xq(1:end), yq(1:end)}));
    img_out = cast(img_out, datatype);
elseif n_dims==3
    % define grid
    xg = 0.5:1:imgSize_in(1)-0.5;
    yg = 0.5:1:imgSize_in(2)-0.5;
    zg = 0.5:1:imgSize_in(3)-0.5;
    % define gridded interpolator
    F = griddedInterpolant({xg, yg, zg}, double(img_in));
    F.Method = method;
    % define query points
    xq = transpose(0.5:(imgSize_in(1)-1)/(imgSize_out(1)-1):imgSize_in(1)-0.5);
    yq = transpose(0.5:(imgSize_in(2)-1)/(imgSize_out(2)-1):imgSize_in(2)-0.5);
    zq = transpose(0.5:(imgSize_in(3)-1)/(imgSize_out(3)-1):imgSize_in(3)-0.5);
    img_out = F({xq(1:end), yq(1:end), zq(1:end)});
    img_out = cast(img_out, datatype);
else
    error('wrong dimension of voxel size')
end
end
