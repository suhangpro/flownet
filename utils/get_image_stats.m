function [averageImage, rgbMean, rgbCovariance, cnt] = get_image_stats(imList, varargin)
% [averageImage, rgbMean, rgbCovariance, cnt] = get_image_stats(imList, varargin)
% options: 'batchSize', 'imreadFn'
args.batchSize = 256;
[args, varargin] = vl_argparse(args, varargin); 

if strcmpi(imList{1}(end-3:end), '.jpg'), 
  args.imreadFn = @(c) vl_imreadjpeg(c, 'numThreads', 12);
else
  args.imreadFn = @(c) cellfun(@(s) single(imread_safe(s)), c, 'UniformOutput', false);
end
args =vl_argparse(args, varargin); 

cnt = 0; n = 0;
accu = {}; rgbm1 = {}; rgbm2 = {}; 
for t=1:args.batchSize:numel(imList), 
  batch_time = tic;
  fprintf('collecting image stats: batch starting with image %s ...', imList{t}) ;
  ims = args.imreadFn(imList(t:min(numel(imList),t+args.batchSize-1)));
  ims = ims(cellfun(@(s) ~isempty(s), ims)); 
  ims = cat(4,ims{:});
  z = reshape(permute(ims,[3 1 2 4]),3,[]) ;
  n = n + size(z,2) ;
  cnt = cnt + size(ims, 4); 
  accu{end+1} = sum(ims, 4) ;
  rgbm1{end+1} = sum(z,2) ;
  rgbm2{end+1} = z*z' ;
  batch_time = toc(batch_time) ;
  fprintf(' %.2f s (%.1f images/s)\n', batch_time, size(ims, 4)/ batch_time) ;
end
averageImage = sum(cat(4,accu{:}),4)/cnt ;
rgbm1 = sum(cat(2,rgbm1{:}),2)/n ;
rgbm2 = sum(cat(3,rgbm2{:}),3)/n ;
rgbMean = rgbm1 ;
rgbCovariance = rgbm2 - rgbm1*rgbm1' ;

function im = imread_safe(path)
try
  im = imread(path);
catch
  warning('Unable to load image: %s', path);
  im = [];
end


