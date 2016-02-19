function [ fldb ] = get_fldb( datasetName, varargin )
%GET_FLDB Get fldb structure for the specified dataset
% datasetName 
%   should be name of a directory under '/data'
% 'func'
%   the function that actually builds the imdb 
%   default: @setup_fldb_generic
% 'rebuild'
%   whether to rebuild imdb if one exists already
%   default: false


args.func = @setup_fldb_generic;
args.rebuild = false; 
args = vl_argparse(args,varargin); 

datasetDir = fullfile('data',datasetName);
fldbPath = fullfile(datasetDir,'fldb.mat');

if ~exist(datasetDir,'dir'), 
    error('Unknown dataset: %s', datasetName);
end

if exist(fldbPath,'file') && ~args.rebuild, 
    fldb = load(fldbPath);
else
    fldb = args.func(datasetDir); 
    save(fldbPath,'-struct','fldb');
end

end

