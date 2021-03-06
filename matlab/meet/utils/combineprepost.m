function Y = combineprepost(Y)
%% COMBINEPREPOST combines pre- and post-strokes with the gesture.
%
% ARGS
% Y - cell array of label sequences.

nseqs = size(Y, 2);

for i = 1 : nseqs
  seq = Y{i};
  % Finds index of the end frames.
  ndx = find(seq(2, :) == 2);
  startNDX = 1;
  for j = 1 : length(ndx)
    endNDX = ndx(j);
    Ylabel = seq(1, endNDX);
    switch Ylabel
      case 11
        seq(1, startNDX : endNDX) = seq(1, endNDX + 1);
        seq(2, endNDX) = 1;
      case 12
        newLabel = 13;
        if startNDX > 1
          newLabel = seq(1, startNDX - 1);
          seq(2, startNDX - 1) = 1;
        elseif seq(1, endNDX + 1) == 13
          seq(2, endNDX) = 1;
        end
        seq(1, startNDX : endNDX) = newLabel;
    end
    startNDX = endNDX + 1;
  end
  checkseq(seq);
  Y{i} = seq;
end
end

function checkseq(seq)

n = size(seq, 2);
for i = 1 : n - 1
  if seq(1, i) == seq(1, i + 1)
    assert(seq(2, i) == 1);
  else
    assert(seq(2, i) == 2);
  end
end
assert(seq(2, n) == 2);
end