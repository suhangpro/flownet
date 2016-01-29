function fldb = setup_fldb_sintel(datasetDir, varargin)
% SETUP_FLDB_SINTEL Build default fldb structure for Sintel dataset
% 
% Hang Su

opts.seed = 0;
opts.type = 'clean'; % 'clean' | 'final'
opts.split_file = ''; % 'sintel.split'
opts.ratio = [0.8 0.2]; % train:val ratio, used only when split_file is empty
opts = vl_argparse(opts,varargin); 

opts.ratio = opts.ratio/sum(opts.ratio); 
fldb.rootDir = datasetDir; 
fldb.meta.sets = {'train', 'val', 'test'}; 
fldb.meta.flowDirection = 'forward'; 

% initialization 
fldb.frames.id    = [];
fldb.frames.name  = {};
fldb.frames.seqId = [];
fldb.flows.id     = [];
fldb.flows.name   = {}; 
fldb.flows.im1    = [];
fldb.flows.im2    = [];
fldb.flows.set    = []; 

% train & val -- frames 
currDir = fullfile('training',opts.type); 
files = dir(fullfile(fldb.rootDir,currDir));
seqDirs = {files.name};
seqDirs = sort(setdiff(seqDirs([files.isdir]),{'.','..'}));
seqId = 0;
for i=1:numel(seqDirs), 
  files = dir(fullfile(fldb.rootDir,currDir,seqDirs{i},'*.png')); 
  if isempty(files), continue; end;
  seqId = seqId + 1;
  imNames = sort({files.name}); 
  fldb.frames.name = [fldb.frames.name cellfun(@(s) ...
    fullfile(currDir,seqDirs{i},s),imNames,'UniformOutput',false)];
  fldb.frames.seqId = [fldb.frames.seqId ones(1,numel(imNames),'int32')*seqId];
end
fldb.frames.id = int32(1:numel(fldb.frames.name));

% train & val -- flows 
currDir = fullfile('training','flow'); 
files = dir(fullfile(fldb.rootDir,currDir)); 
seqDirs_flow = {files.name};
seqDirs_flow = sort(setdiff(seqDirs_flow([files.isdir]),{'.','..'}));
assert(isequal(seqDirs,seqDirs_flow));  % train/val seqs should have gt flow
mapObj_im_id = containers.Map(cellfun(@(s) cut_id_str(s),fldb.frames.name, ...
  'UniformOutput', false), fldb.frames.id); 
for i=1:numel(seqDirs), 
  files = dir(fullfile(fldb.rootDir,currDir,seqDirs{i},'*.flo'));
  if isempty(files), continue; end;
  floNames = sort({files.name}); 
  fldb.flows.name = [fldb.flows.name cellfun(@(s) ...
    fullfile(currDir,seqDirs{i},s),floNames,'UniformOutput',false)];
end
fldb.flows.im1 = cellfun(@(s) mapObj_im_id(s), ...
  cellfun(@(s) cut_id_str(s),fldb.flows.name, 'UniformOutput',false)); 
fldb.flows.im2 = fldb.flows.im1 + 1; % assume flow on consecutive frames 
fldb.flows.id = int32(1:numel(fldb.flows.name)); 

% test -- frames 
currDir = fullfile('test',opts.type); 
files = dir(fullfile(fldb.rootDir,currDir));
seqDirs = {files.name};
seqDirs = sort(setdiff(seqDirs([files.isdir]),{'.','..'}));
for i=1:numel(seqDirs), 
  files = dir(fullfile(fldb.rootDir,currDir,seqDirs{i},'*.png')); 
  if isempty(files), continue; end;
  seqId = seqId + 1;
  imNames = sort({files.name}); 
  fldb.frames.name = [fldb.frames.name cellfun(@(s) ...
    fullfile(currDir,seqDirs{i},s),imNames,'UniformOutput',false)];
  fldb.frames.seqId = [fldb.frames.seqId ones(1,numel(imNames),'int32')*seqId];
end
assert(numel(fldb.frames.id)==max(fldb.frames.id));
fldb.frames.id = [fldb.frames.id ...
  (numel(fldb.frames.id)+1):numel(fldb.frames.name)];

% train/val/test split
if isempty(opts.split_file),
  % random split
  rng(opts.seed);
  n_flows = numel(fldb.flows.id);
  nTrain = round(opts.ratio(1)*n_flows);
  if numel(opts.ratio==2) || opts.ratio(3)==0,
    nVal = n_flows-nTrain;
    nTest = 0;
  else
    nVal = min(round(opts.ratio(2)*n_flows),n_flows-nTrain);
    nTest = n_flows - nTrain - nVal;
  end
  inds = [ones(1,nTrain,'int32') 2*ones(1,nVal,'int32') 3*ones(1,nTest,'int32')];
  fldb.flows.set = inds(randperm(n_flows));
else
  % read split from file
  fid = fopen(opts.split_file);
  texts = textscan(fid,'%s %d');
  mapObj_flow_set = containers.Map(texts{1},int32(texts{2}));
  fldb.flows.set = cellfun(@(s) mapObj_flow_set(s), ...
    cellfun(@(s) cut_id_str(s), fldb.flows.name, 'UniformOutput', false));
end

end

function s = cut_id_str(s)
  sepLocs = strfind(s,filesep);
  dotLocs = strfind(s,'.'); 
  s = s(sepLocs(end-1)+1:dotLocs(end)-1);
end