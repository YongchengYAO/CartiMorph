function img_out = CM_imgPreprocess_resample(img_in, imgSize_out, method, datatype)

n_dims = length(imgSize_out);
imgSize_in = size(img_in);
scaling = imgSize_in ./ imgSize_out;

if n_dims==2
    % define grid
    xg = 0.5:imgSize_in(1)-0.5;
    yg = 0.5:imgSize_in(2)-0.5;
    % define gridded interpolator
    F = griddedInterpolant({xg, yg}, double(img_in));
    F.Method = method;
    % define query points
    xq = transpose(scaling(1)/2+0.5:scaling(1):scaling(1)*imgSize_out(1));
    yq = transpose(scaling(2)/2+0.5:scaling(2):scaling(2)*imgSize_out(2));
    img_out = (F({xq(1:end), yq(1:end)}));
    img_out = cast(img_out, datatype);
elseif n_dims==3
    % define grid
    xg = 0.5:imgSize_in(1)-0.5;
    yg = 0.5:imgSize_in(2)-0.5;
    zg = 0.5:imgSize_in(3)-0.5;
    % define gridded interpolator
    F = griddedInterpolant({xg, yg, zg}, double(img_in));
    F.Method = method;
    % define query points
    xq = transpose(scaling(1)/2+0.5:scaling(1):scaling(1)*imgSize_out(1));
    yq = transpose(scaling(2)/2+0.5:scaling(2):scaling(2)*imgSize_out(2));
    zq = transpose(scaling(3)/2+0.5:scaling(3):scaling(3)*imgSize_out(3));
    img_out = F({xq(1:end), yq(1:end), zq(1:end)});
    img_out = cast(img_out, datatype);
else
    error('wrong dimension of voxel size')
end

end