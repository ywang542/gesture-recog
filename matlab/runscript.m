dirname = 'G:\data\stand_hog1';
combinedDataName = 'combinedData';
dataOption = 0;

dataFile = fullfile(dirname, 'data.mat');
combinedDataFile = fullfile(dirname, [combinedDataName '.mat']);

%% Process and save data.
switch dataOption
  case 1
    if exist(dataFile, 'file')
      load(dataFile);
    else 
      data = [];
    end
    data = prepdata(dirname, 'prevData', data);
    combinedData = {combinedata(data)};
    savevariable(dataFile, 'data', data);
    savevariable(combinedDataFile, 'combinedData', combinedData);
  case 2
    % Load data.
    load(combinedDataFile); 
end

testSplit = {[1 : 2, 4, 6, 8, 10, 11]; [3, 5, 7, 9]; []};

jobParam = jobparam;
hyperParam = hyperparam(combinedData{1}.param, 'dataFile', combinedDataName);

% fold = 1, batch = 1, seed = 1
nModels = length(hyperParam.model);
R = cell(1, nModels);
for i = 1 : nModels
  R{i} = runexperiment(hyperParam.model{i}, testSplit, 1, 1, 1, combinedData);
end

fprintf('Training error = %f\n', R{1}.stat('TrError'));
fprintf('Testing error = %f\n', R{1}.stat('VaError'));