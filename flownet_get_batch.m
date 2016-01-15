function inputs = flownet_get_batch(fldb, batch, varargin)
% FLOWNET_GET_BATCH Construct input
% 
% Hang Su

opts.mode = 'fixed' ; % 'random'
opts.imageSize = [224 224] ;
opts.interpolation = 'bicubic' ;
opts.subwins = [1 1 1] ;
opts.scaleRange = [0.8 1.2] ;
opts.nSamples = 4 ;
opts.channelAvg = single([123.6591  116.7663  103.9318]) ;
opts.convert2Pol = false; 
[opts,varargin] = vl_argparse(opts,varargin);

% initialization
N = get_subwins([],[],opts.subwins);
inputs{1} = 'im1';
inputs{3} = 'im2';
inputs{5} = 'flow';
inputs{2} = zeros([opts.imageSize(1), opts.imageSize(2), 3, numel(batch)*N], 'single'); 
inputs{4} = zeros([opts.imageSize(1), opts.imageSize(2), 3, numel(batch)*N], 'single'); 
inputs{6} = zeros([opts.imageSize(1), opts.imageSize(2), 2, numel(batch)*N], 'single'); 

% Map: id --> <inputid, idx>
loadedImages = containers.Map('KeyType','double','ValueType','any');
[Y, I] = ismember(batch,fldb.flows.id); assert(all(Y(:)));
[Y, I1] = ismember(fldb.flows.im1,fldb.frames.id); assert(all(Y(:)));
[Y, I2] = ismember(fldb.flows.im2,fldb.frames.id); assert(all(Y(:)));

for i=1:numel(batch), 
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
    if strcmpi(opts.mode,'fixed'), 
      subwins = get_subwins([size(im1,1) size(im1,2)],opts.imageSize,opts.subwins); 
    else
      subwins = get_subwins([size(im1,1) size(im1,2)],opts.imageSize,opts.scaleRange,opts.nSamples);
    end
    for j=1:size(subwins,2), 
        if subwins(5,j)~=1,
            im1 = imresize(im1,round(size(im1(:,:,1))*subwins(5,j)),...
                'method',opts.interpolation);
            im2 = imresize(im2,round(size(im2(:,:,1))*subwins(5,j)),...
                'method',opts.interpolation);
            flo = imresize(flo,round(size(flo(:,:,1))*subwins(5,j)),...
                'method',opts.interpolation);
        end
        inputs{2}(:,:,:,(i-1)*N+j) = im1(subwins(2):subwins(2)+subwins(4)-1,...
            subwins(1):subwins(1)+subwins(3)-1,:);
        inputs{4}(:,:,:,(i-1)*N+j) = im2(subwins(2):subwins(2)+subwins(4)-1,...
            subwins(1):subwins(1)+subwins(3)-1,:);
        flo = flo.*subwins(5,j);
        inputs{6}(:,:,:,(i-1)*N+j) = flo(subwins(2):subwins(2)+subwins(4)-1,...
            subwins(1):subwins(1)+subwins(3)-1,:);
    end
    inputs{2} = bsxfun(@minus,inputs{2},reshape(opts.channelAvg,[1 1 3 1]));
    inputs{4} = bsxfun(@minus,inputs{4},reshape(opts.channelAvg,[1 1 3 1]));
end

if opts.convert2Pol, 
  inputs{6} = flow_convert(inputs{6},'cartesian','polar_quant');
end

end
