function [Y, X, frame] = alignlabelfeature(gt, feature)
%% ALIGNLABELFEATURE Aligns ground truth data with feature data. Feature
%   data frames not in the ground truth are ignored. 
%
% ARGS
% gt   - n x 3 matrix of all ground truth labels for a batch. The first
%        column is the stroke id. The second column is the start frame id
%        of the stroke and the third column is end frame id of the stroke.
% feature - matrix of all features for a batch. Each row is an observation.
% 
% RETURNS
% Y     - labels, a 2 x nframe matrix. The first row is gesture stroke
%   label; the second row is the indicator of when a gesture stroke ends.
% X     - feature vectors, a d x nframe matrix. 
% frame - frame numbers, a 1 x nframe matrix.

p = 1;
X = [];
Y = [];
frame = [];
nfeatures = size(feature, 1);
for i = 1 : size(gt, 1)
  while feature(p, 1) < gt(i, 2)
    p = p + 1;
  end
  startNDX = p;
  
  while p <= nfeatures && feature(p, 1) <= gt(i, 3)
    p = p + 1;
  end
  endNDX = p - 1;
  
  X = [X feature(startNDX : endNDX, 2 : end)']; %#ok<AGROW>
  newY = ones(2, endNDX - startNDX + 1);
  newY(1, :) = gt(i, 1);
  %% Helps to distinguish consecutive gestures with the same label.
  newY(2, end) = 2;
  Y = [Y newY]; %#ok<AGROW>
  frame = [frame feature(startNDX : endNDX, 1)']; %#ok<AGROW>
end
assert(size(Y, 2) == size(frame, 2));
end