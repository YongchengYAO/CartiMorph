function bestModel = CM_cal_bestCurveFit_poly(x, y, maxOrder)

if maxOrder==9
    % fit 7 polynomial equations
    [curve_poly3, gof_poly3, ~] = fit(x, y, 'poly3');
    [curve_poly4, gof_poly4, ~] = fit(x, y, 'poly4');
    [curve_poly5, gof_poly5, ~] = fit(x, y, 'poly5');
    [curve_poly6, gof_poly6, ~] = fit(x, y, 'poly6');
    [curve_poly7, gof_poly7, ~] = fit(x, y, 'poly7');
    [curve_poly8, gof_poly8, ~] = fit(x, y, 'poly8');
    [curve_poly9, gof_poly9, ~] = fit(x, y, 'poly9');

    % find the best model
    RMSE = [gof_poly3.rmse, gof_poly4.rmse, gof_poly5.rmse, ...
        gof_poly6.rmse, gof_poly7.rmse, gof_poly8.rmse, gof_poly9.rmse];
    curveFitModels = {curve_poly3, curve_poly4, curve_poly5,...
        curve_poly6, curve_poly7, curve_poly8, curve_poly9};
    [~, idx_bestModel] = min(RMSE);
    bestModel = curveFitModels{idx_bestModel};
end

if maxOrder==8
    % fit 7 polynomial equations
    [curve_poly3, gof_poly3, ~] = fit(x, y, 'poly3');
    [curve_poly4, gof_poly4, ~] = fit(x, y, 'poly4');
    [curve_poly5, gof_poly5, ~] = fit(x, y, 'poly5');
    [curve_poly6, gof_poly6, ~] = fit(x, y, 'poly6');
    [curve_poly7, gof_poly7, ~] = fit(x, y, 'poly7');
    [curve_poly8, gof_poly8, ~] = fit(x, y, 'poly8');

    % find the best model
    RMSE = [gof_poly3.rmse, gof_poly4.rmse, gof_poly5.rmse, ...
        gof_poly6.rmse, gof_poly7.rmse, gof_poly8.rmse];
    curveFitModels = {curve_poly3, curve_poly4, curve_poly5,...
        curve_poly6, curve_poly7, curve_poly8};
    [~, idx_bestModel] = min(RMSE);
    bestModel = curveFitModels{idx_bestModel};
end

if maxOrder==7
    % fit 7 polynomial equations
    [curve_poly3, gof_poly3, ~] = fit(x, y, 'poly3');
    [curve_poly4, gof_poly4, ~] = fit(x, y, 'poly4');
    [curve_poly5, gof_poly5, ~] = fit(x, y, 'poly5');
    [curve_poly6, gof_poly6, ~] = fit(x, y, 'poly6');
    [curve_poly7, gof_poly7, ~] = fit(x, y, 'poly7');

    % find the best model
    RMSE = [gof_poly3.rmse, gof_poly4.rmse, gof_poly5.rmse, ...
        gof_poly6.rmse, gof_poly7.rmse];
    curveFitModels = {curve_poly3, curve_poly4, curve_poly5,...
        curve_poly6, curve_poly7};
    [~, idx_bestModel] = min(RMSE);
    bestModel = curveFitModels{idx_bestModel};
end

if maxOrder==6
    % fit 7 polynomial equations
    [curve_poly3, gof_poly3, ~] = fit(x, y, 'poly3');
    [curve_poly4, gof_poly4, ~] = fit(x, y, 'poly4');
    [curve_poly5, gof_poly5, ~] = fit(x, y, 'poly5');
    [curve_poly6, gof_poly6, ~] = fit(x, y, 'poly6');

    % find the best model
    RMSE = [gof_poly3.rmse, gof_poly4.rmse, gof_poly5.rmse, ...
        gof_poly6.rmse];
    curveFitModels = {curve_poly3, curve_poly4, curve_poly5,...
        curve_poly6};
    [~, idx_bestModel] = min(RMSE);
    bestModel = curveFitModels{idx_bestModel};
end

if maxOrder==5
    % fit 3 polynomial equations
    [curve_poly3, gof_poly3, ~] = fit(x, y, 'poly3');
    [curve_poly4, gof_poly4, ~] = fit(x, y, 'poly4');
    [curve_poly5, gof_poly5, ~] = fit(x, y, 'poly5');

    % find the best model
    RMSE = [gof_poly3.rmse, gof_poly4.rmse, gof_poly5.rmse];
    curveFitModels = {curve_poly3, curve_poly4, curve_poly5};
    [~, idx_bestModel] = min(RMSE);
    bestModel = curveFitModels{idx_bestModel};
end

end