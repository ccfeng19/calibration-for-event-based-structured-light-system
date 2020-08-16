function [X3,Y3,Z3] = reconstruct_Scene(disparityMap, stereoParams,Q)

validateattributes(disparityMap, {'double', 'single'}, ...
    {'2d', 'real', 'nonsparse'}, ...
    mfilename, 'disparityImage');

validateattributes(stereoParams, {'stereoParameters'}, {}, ...
    mfilename, 'stereoParams');

% calculate the 3D locations
% output is of the same class as disparity map
numPoints = numel(disparityMap);
[y, x] = meshgrid(1:180,1:240);
points2dHomog = [x(:), y(:), disparityMap(:), ...
    ones(numPoints, 1, 'like', disparityMap)];
points3dHomog = points2dHomog * Q;
points3d = bsxfun(@times, points3dHomog(:, 1:3), 1./points3dHomog(:, 4));

% create outputs
X3 = reshape(points3d(:, 1), size(disparityMap));
Y3 = reshape(points3d(:, 2), size(disparityMap));
Z3 = reshape(points3d(:, 3), size(disparityMap));

% invalid disparity results in the 3D location being NaN.
X3(disparityMap == -realmax('single')) = NaN;
Y3(disparityMap == -realmax('single')) = NaN;
Z3(disparityMap == -realmax('single')) = NaN;

end