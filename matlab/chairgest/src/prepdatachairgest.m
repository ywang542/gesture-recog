function data = prepdatachairgest(dirname, varargin)
%% PREPAREDATACHAIRGEST prepares the data from CHAIRGEST dataset into right 
% structure for preprocessing. All session data are concatenated one after 
% another.
%
% ARGS
% dirname     - directory of the main database name, i.e. 'chairgest'.
%
% OPTIONAL ARGS
% sensorType  - string of sensor type, i.e., 'Kinect' or 'Xsens'. ['Kinect']
% subsmapleFactor - subsampling factor. [1]
% gtSensorType  - ground truth reference sensor. ['Kinect'] 
%
% RETRURN
% data  - a cell array. Each cell is for one user and is a structure with fields:
%   Y     - a cell array of ground truth labels.
%   X     - a cell array of features.

sensorType = 'Kinect';
gtSensorType = 'Kinect';
dataType = 'Converted'; 
subsampleFactor = 1; 

for i = 1 : 2 : length(varargin)
  switch varargin{i}
    case 'sensorType'
      sensorType = varargin{i + 1};
    case 'gtSensorType'
      gtSensorType = varargin{i + 1};
    case 'subsampleFactor'
      subsampleFactor = varargin{i + 1};
    otherwise
      error(['Unrecognized option: ' varargin{i}]);
  end
end

gtFileFormat = [gtSensorType 'DataGTD_%s.txt'];

dataSet = ChairgestData(dirname);
pids = dataSet.getPIDs;
npids = length(pids);
data = cell(1, npids);
for p = 1 : npids
  pid = pids{p};
  sessionNames = dataSet.getSessionNames(pid);
  data{p}.userId = pid;
  data{p}.Y = {};
  data{p}.X = {};
  data{p}.frame = {};
  data{p}.file = {};

  paramInitialized = false;
  for i = 1 : length(sessionNames)
    sessionName = sessionNames{i};
    sessionDir = fullfile(dirname, pid, sessionName);
    [batches, ndx] = dataSet.getBatchNames(pid, sessionName, sensorType);

    for j = 1 : length(batches)
      fileName = batches{j};
      batchNdxStr = ndx{j};
      batchNdx = str2double(batchNdxStr);
      if batchNdx > 0
        gtFile = fullfile(sessionDir, sprintf(gtFileFormat, batchNdxStr));
        logdebug('prepdatachairgest', 'batch', gtFile);
        [featureData, descriptorStartNdx, imgWidth, sampleRate] = ...
            readfeature(fullfile(sessionDir, fileName), sensorType);
        [gt, vocabSize] = readgtchairgest(gtFile, featureData(1, 1), ...
            featureData(end, 1));

        if ~paramInitialized
          dataParam.vocabularySize = vocabSize;
          dataParam.startImgFeatNDX = descriptorStartNdx;
          dataParam.dir = dirname;
          dataParam.subsampleFactor = subsampleFactor * sampleRate;
          dataParam.gtSensorType = gtSensorType;
          dataParam.dataType = dataType;
          dataParam.imgWidth = imgWidth;
          paramInitialized = true;
        end
        
        if (batchNdx == 1)
          featureData = filter(featureData, gtSensorType, sampleRate);
        end
        [Y, X, frame] = combinelabelfeature(gt, featureData);
        data{p}.Y{end + 1} = Y;
        data{p}.X{end + 1} = X;
        data{p}.frame{end + 1} = frame;
        data{p}.file{end + 1} = {pid, sessionName, batchNdxStr};
      end
    end
  end
  data{p} = subsample(data{p}, subsampleFactor);
  data{p}.Y = addflabel(data{p}.Y);
  data{p}.param = dataParam;
end
end

function feature = filter(feature, gtSensorType, sampleRate)
FILTER_LEN = 400; % frames
switch gtSensorType
  case 'Kinect',
    feature = feature(feature(:, 1) > FILTER_LEN, :);
  case 'Xsens'
    startNdx = FILTER_LEN / sampleRate;
    feature = feature(startNdx : end, :);
  otherwise
    error('Invalid ground sensor type');
end
end

function [Y, X, frame] = combinelabelfeature(label, feature)
%% Combines label and feature with common frame id.
%
% ARGS
% label   - matrix of all ground truth labels for a batch.
% feature - matrix of all features for a batch. Each row is an observation.
% 
% RETURNS
% Y   - cell array of labels. Each cell is a 2 x nframe matrix.
% X   - cell array of feature vectors. Each cell is a d x nframe matrix. 
% frame   - cell arrays of frame numbers. Each cell is a 1 x nframe matrix.

labelFrameId = label(:, 1);
featureFrameId = feature(:, 1);
% Finds common frames.
[frame, labelNDX, featureNDX] = intersect(labelFrameId, featureFrameId);
Y = label(labelNDX, 2 : 3)';
X = feature(featureNDX, 2 : end)';
frame = frame(:)';
assert(size(Y, 2) == size(frame, 2));
end