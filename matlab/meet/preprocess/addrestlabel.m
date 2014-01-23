function [Y, X, frame] = addrestlabel(Y, X, frame, param)
%% ADDRESTLABEL Add rest label according to speed. Only add rest label for 
%   type 0 (discrete) gestures.
%
% ARGS
% Y, X, frame - cell array of sequences or structure of cell arrays.

restLabel = param.vocabularySize;
sampleRate = param.kinectSampleRate;
[~, ~, gestureType] = gesturelabel();
if isstruct(X)
  fn = fieldnames(X);
  for i = 1 : length(fn)
    X1 = X.(fn{i});
    Y1 = Y.(fn{i});
    frame1 = frame.(fn{i});
    [Y.(fn{i}), X.(fn{i}), frame.(fn{i})] = addrestlabel1(Y1, X1, frame1,...
          restLabel, gestureType, sampleRate);
  end
else
  [Y, X, frame] = addrestlabel1(Y, X, frame, restLabel, gestureType, sampleRate);
end
end

function [Y, X, frame] = addrestlabel1(Y, X, frame, restLabel, gestureType, sampleRate)
% ARGS
% Y   - 2 x n array.
% sampleRate  - Kinect sample rate.

for n = 1 : numel(X)
  X1 = X{n};
  Y1 = Y{n};
  frame1 = frame{n};
  pos = X1(1 : 3, :);
  speed = computespeed(pos, frame1);

  y = X1(2, :);

  type = gestureType(Y1(1, :));
  rest = speed < 0.009 & y < -0.55 & type == 0;
  if any(rest)
    runs = contiguous(rest, 1);
    runs = runs{1, 2};

    for i = 1 : size(runs, 1)
      startNdx = runs(i, 1);
      endNdx = runs(i, 2);
      Y1(1, startNdx : endNdx) = restLabel;
    end   
  end
  
  [Y{n}, X{n}, frame{n}] = removestartandend(Y1, X1, frame1, ...
        gestureType, sampleRate);
  Y{n} = addflabel(Y{n});
end
end

function [Y1, X1, frame1] = removestartandend(Y1, X1, frame1, ...
      gestureType, sampleRate)
% Each gesture is about 3s.
REMOVE_LEN = 15; % 1s at 30Hz
scaledLen = round(REMOVE_LEN / sampleRate);

type1 = gestureType(Y1(1, :));
runs = contiguous(type1, 1);
runs = runs{1, 2};
removeMask = zeros(size(type1));
for i = 1 : size(runs)
  startNdx = runs(i, 1);
  endNdx = runs(i, 2);
  removeMask(startNdx : min(startNdx + scaledLen, endNdx)) = 1;
  removeMask(max(endNdx - scaledLen, startNdx) : endNdx) = 1;
end

% Remove uncertain labels
keepNdx = removeMask ~= 1;
X1 = X1(:, keepNdx);
Y1 = Y1(:, keepNdx);
frame1 = frame1(:, keepNdx);
end

function Y = filtershort(Y, restLabel, minLen)

runs = contiguous(Y(1, :));
for l = 1 : size(runs, 1)
  label = runs{l, 1};
  if label < restLabel
    run = runs{l, 2};
    for r = 1 : size(run, 1)
      endNdx = run(r, 2);
      startNdx = run(r, 1);
      if  endNdx - startNdx < 0
        Y(startNdx : endNdx) = restLabel;
      end
    end
  end
end
end