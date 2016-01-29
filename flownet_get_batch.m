function inputs = flownet_get_batch(fldb, batch, varargin)
% FLOWNET_GET_BATCH Construct input
%
% Hang Su

opts.multiplier = 64;
opts.interpolation = 'bilinear' ;
opts.avgPixel = single([123.6591  116.7663  103.9318]) ;
opts.convertFlowFmt = '';

opts.imageSize = [384 512] ;
opts.mode = 'random' ; % 'random', 'fixed'
opts.subwins = [1 1 1] ;
opts.scaleRange = [0.8 1.2] ;
opts.nSamples = 4 ;

[opts,~] = vl_argparse(opts,varargin);

% initialization
N = get_subwins([],[],opts.subwins);
inputs{1} = 'im1';
inputs{3} = 'im2';
inputs{5} = 'gt';
inputs{2} = zeros([opts.imageSize(1), opts.imageSize(2), 3, numel(batch)*N], 'single');
inputs{4} = zeros([opts.imageSize(1), opts.imageSize(2), 3, numel(batch)*N], 'single');
inputs{6} = zeros([opts.imageSize(1), opts.imageSize(2), 2, numel(batch)*N], 'single');

% Map: id --> <inputid, idx>
loadedImages = containers.Map('KeyType','int32','ValueType','any');
[Y, I] = ismember(batch,fldb.flows.id); assert(all(Y(:)));
[Y, I1] = ismember(fldb.flows.im1,fldb.frames.id); assert(all(Y(:)));
[Y, I2] = ismember(fldb.flows.im2,fldb.frames.id); assert(all(Y(:)));

for i=1:numel(batch),
  % load images and flows
  idx = I(i);
  im1_id = fldb.flows.im1(idx);
  im2_id = fldb.flows.im2(idx);
  if loadedImages.isKey(im1_id),
    im1 = loadedImages(im1_id);
  else
    imPath = fullfile(fldb.rootDir,fldb.frames.name{I1(idx)});
    im1 = imread_255(imPath,3);
    loadedImages(im1_id) = im1;
  end
  if loadedImages.isKey(im2_id),
    im2 = loadedImages(im2_id);
  else
    imPath = fullfile(fldb.rootDir,fldb.frames.name{I2(idx)});
    im2 = imread_255(imPath,3);
    loadedImages(im2_id) = im2;
  end
  flo = readFlowFile(fullfile(fldb.rootDir,fldb.flows.name{idx}));
  assert(all(size(im1)==size(im2)) && ...
    all(size(im1(:,:,1))==size(flo(:,:,1))));
  
  % compute subwins according to translation/scaling/flipping/rotation
  % TODO NOT_YET_IMPLEMENTED
  if strcmpi(opts.mode,'fixed'),
    subwins = get_subwins([size(im1,1) size(im1,2)],opts.imageSize,opts.subwins);
  elseif strcmpi(opts.mode,'random'),
    subwins = get_subwins([size(im1,1) size(im1,2)],opts.imageSize,opts.scaleRange,opts.nSamples);
  end
  
  % obtain actual crops according to subwins
  % TODO NOT_YET_IMPLEMENTED
  for j=1:size(subwins,2),
    if subwins(5,j)~=1,
      im1_rs = imresize(im1,round(size(im1(:,:,1))*subwins(5,j)),...
        'method',opts.interpolation);
      im2_rs = imresize(im2,round(size(im2(:,:,1))*subwins(5,j)),...
        'method',opts.interpolation);
      flo_rs = imresize(flo,round(size(flo(:,:,1))*subwins(5,j)),...
        'method',opts.interpolation);
    end
    inputs{2}(:,:,:,(i-1)*N+j) = im1_rs(subwins(2,j):subwins(2,j)+subwins(4,j)-1,...
      subwins(1,j):subwins(1,j)+subwins(3,j)-1,:);
    inputs{4}(:,:,:,(i-1)*N+j) = im2_rs(subwins(2,j):subwins(2,j)+subwins(4,j)-1,...
      subwins(1,j):subwins(1,j)+subwins(3,j)-1,:);
    flo_rs = flo_rs.*subwins(5,j);
    inputs{6}(:,:,:,(i-1)*N+j) = flo_rs(subwins(2,j):subwins(2,j)+subwins(4,j)-1,...
      subwins(1,j):subwins(1,j)+subwins(3,j)-1,:);
  end
  
  % rgb perturbation
  % TODO NOT_YET_IMPLEMENTED
  
  % deduct average pixel values
  inputs{2} = bsxfun(@minus,inputs{2},reshape(opts.avgPixel,[1 1 3 1]));
  inputs{4} = bsxfun(@minus,inputs{4},reshape(opts.avgPixel,[1 1 3 1]));
end

if ~isemtpy(opts.convertFlowFmt) && ~strcmpi(opts.convertFlowFmt,'none'),
  inputs{6} = flow_convert(inputs{6},'cartesian',opts.convertFlowFmt);
end

end
