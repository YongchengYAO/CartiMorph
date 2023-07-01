function [cx, cy, R] = CM_cal_fitCircle(x, y)
x = x(:);
y = y(:);
a = -1 * [x, y, ones(size(x))] \ (x.^2 + y.^2);
cx = -0.5 * a(1);
cy = -0.5 * a(2);
R = sqrt((a(1)^2 + a(2)^2)/4 - a(3));
end