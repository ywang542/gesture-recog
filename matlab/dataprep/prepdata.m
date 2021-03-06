function data = prepdata(dirname, varargin)
%% PREPAREDATA prepares the data from YANG dataset into right 
% structure for preprocessing.
%
% ARGS
% dirname     - directory of the main database name, i.e. 'chairgest'.
%
% OPTIONAL ARGS
% sensorType  - string of sensor type, i.e., 'Kinect' or 'Xsens'. Specifies
%   which processed sensor data file to read. ['Kinect']
% gtSensorType - ground truth sensor type. Specifies which ground truth
%   data file to read. ['Kinect']
% prevData  - previous saved data. [[]]
%
% RETRURN
% data  - a cell array. Each cell is for one user and is a structure with fields:
%   Y     - a cell array of ground truth labels.
%   X     - a cell array of features.

sensorType = 'Kinect';
gtSensorType = 'Kinect';
dataType = 'Converted';
gestureDefDir = dirname;
prevData = []; % Previous processed and saved data.

pidToProcess = [];

for i = 1 : 2 : length(varargin)
  value = varargin{i + 1};
  switch varargin{i}
    case 'sensorType'
      sensorType = value;
    case 'gtSensorType'
      gtSensorType = value;
    case 'prevData'
      prevData = value;
    case 'pid'
      pidToProcess = value;
    case 'gestureDefDir'
      gestureDefDir = value;
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
  if ~isempty(pidToProcess) && ~ismember(pid, pidToProcess)
    continue;
  end
  sessionNames = dataSet.getSessionNames(pid);
  data{p}.userId = pid;
  data{p}.Y = {};
  data{p}.X = {};
  data{p}.frame = {};
  data{p}.file = {};
  data{p}.nEvent = {};
  
  paramInitialized = false;
  prevFileSet = java.util.HashSet;
  
  if ~isempty(prevData) && p <= length(prevData)
    sessionNameSet = java.util.HashSet;
    for i = 1 : length(sessionNames)
      sessionNameSet.add(sessionNames{i});
    end
    
    prevFiles = prevData{p}.file;
    for i = 1 : length(prevFiles)
      if sessionNameSet.contains(prevFiles{i}{2})
        data{p}.Y{end + 1} = prevData{p}.Y{i};
        data{p}.X{end + 1} = prevData{p}.X{i};
        data{p}.frame{end + 1} = prevData{p}.frame{i};
        data{p}.file{end + 1} = prevData{p}.file{i};
        data{p}.nEvent{end + 1} = prevData{p}.nEvent{i};
        dataParam = prevData{p}.param;
        paramInitialized = true; % Use previous param.
        prevFileSet.add(prevFiles{i}{2});
      end
    end
  end
  
  for i = 1 : length(sessionNames)
    sessionName = sessionNames{i};
    if prevFileSet.contains(sessionName), continue; end
    sessionDir = fullfile(dirname, pid, sessionName);
    [batches, ndx] = dataSet.getBatchNames(pid, sessionName, sensorType);

    for j = 1 : length(batches)
      fileName = batches{j};
      batchNDXstr = ndx{j};
      batchNDX = str2double(batchNDXstr);
      if batchNDX > 0
        gtFile = fullfile(sessionDir, sprintf(gtFileFormat, batchNDXstr));
        logdebug('prepdatachairgest', 'batch', gtFile);
        [featureData, startDescriptorNdx, imgWidth, sampleRate, ...
            kinectSampleRate] = readfeature(...
            fullfile(sessionDir, fileName), sensorType);
        [gt, vocabSize] = readgt(gtFile, featureData(end, 1), gestureDefDir);

        if ~paramInitialized
          dataParam.vocabularySize = vocabSize;
          dataParam.startDescriptorNdx = startDescriptorNdx;
          dataParam.dir = dirname;
          dataParam.subsampleFactor = sampleRate;
          dataParam.gtSensorType = gtSensorType;
          dataParam.dataType = dataType;
          dataParam.imgWidth = imgWidth;
          dataParam.kinectSampleRate = kinectSampleRate;
          paramInitialized = true;
        end
        [Y, X, frame] = alignlabelfeature(gt, featureData);
        data{p}.Y{end + 1} = Y;
        data{p}.X{end + 1} = X;
        data{p}.frame{end + 1} = frame;
        data{p}.file{end + 1} = {pid, sessionName, batchNDXstr};
        data{p}.nEvent{end + 1} = size(gt, 1);
      end
    end
  end
  data{p}.param = dataParam;
  data{p} = checkautoseg(data{p}, true);
end
end