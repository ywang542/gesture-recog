function viewspeed(Y, X, frame, param)
%%
% ARGS
% X - a sequence

figure;

nFrames = size(X, 2);
pos = X(1 : 3, :);
speed = computespeed(pos, frame);

plot(1 : nFrames, speed, 1 : nFrames, X(2, :), 'r');

ngestures = param.vocabularySize;
gestureLabel = gesturelabel();
colormap(bipolar(ngestures));
image('XData', [1, nFrames], 'YData', [0.1, 0.08], 'CData', Y(1, :));
h = colorbar;
set(h, 'YTick', 1 : ngestures);
set(h, 'YTickLabel', gestureLabel, 'FontSize', 12);

axis([1 nFrames -0.6 0.1]);
legend('smoothed speed', 'smoothed');
end