function [ fldb ] = get_fldb( datasetName, varargin )
%GET_FLDB Get fldb structure for the specified dataset
% datasetName 
%   should be name of a directory under '/data'

datasetDir = fullfile('data',datasetName);
datasetFnName = ['setup_' datasetName];
fldbPath = fullfile(datasetDir,'fldb.mat');

if ~exist(datasetDir,'dir'), 
    error('Unknown dataset: %s', datasetName);
end

if exist(fldbPath,'file'), 
    fldb = load(fldbPath);
else
    if exist([datasetFnName '.m'],'file'),
        fldb = eval([datasetFnName '(''' datasetDir ''')']);
    else
        fldb = setup_dataset_fldb(datasetDir, varargin{:});
    end
    save(fldbPath,'-struct','fldb');
end

end

