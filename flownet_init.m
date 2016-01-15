function net = flownet_init(varargin)
% FLOWNET_INIT  CNN model initialization 

opts.scale = 1 ;
opts.initBias = 0.1 ;
opts.weightDecay = 1 ;
opts.weightInitMethod = 'gaussian' ; 
opts.batchNormalization = false ; 
opts = vl_argparse(opts, varargin) ;

net = dagnn.DagNN();

% image pre-prosessing settings 
net.meta.normalization.mode = 'fixed'; 
net.meta.normalization.imageSize = [224 224] ;
net.meta.normalization.interpolation = 'bicubic' ;
net.meta.normalization.subwins = [1 1 1];
net.meta.normalization.averageImage = single([123.6591  116.7663  103.9318]);

block = dagnn.Concat('dim',3,'numInputs',2);
net.addLayer('im_concat', block, {'im1','im2'}, {'im_concat'}, {});

block = dagnn.Conv('size',[11 11 6 96], 'hasBias', true, 'pad', 5);
net.addLayer('conv1', block, {'im_concat'}, {'conv1'}, {'conv1_f','conv1_b'}); 
block = dagnn.ReLU();
net.addLayer('relu1', block, {'conv1'}, {'relu1'}, {});
block = dagnn.LRN();
net.addLayer('norm1', block, {'relu1'}, {'norm1'}, {}); 

block = dagnn.Conv('size',[5 5 96 128], 'hasBias', true, 'pad', 2);
net.addLayer('conv2', block, {'norm1'}, {'conv2'}, {'conv2_f','conv2_b'}); 
block = dagnn.ReLU();
net.addLayer('relu2', block, {'conv2'}, {'relu2'}, {});
block = dagnn.LRN();
net.addLayer('norm2', block, {'relu2'}, {'norm2'}, {}); 

block = dagnn.Conv('size',[3 3 128 128], 'hasBias', true, 'pad', 1);
net.addLayer('conv3', block, {'norm2'}, {'conv3'}, {'conv3_f','conv3_b'}); 
block = dagnn.ReLU();
net.addLayer('relu3', block, {'conv3'}, {'relu3'}, {});
block = dagnn.LRN();
net.addLayer('norm3', block, {'relu3'}, {'norm3'}, {}); 

block = dagnn.Conv('size',[3 3 128 576], 'hasBias', true, 'pad', 1);
net.addLayer('conv4', block, {'norm3'}, {'conv4'}, {'conv4_f','conv4_b'}); 

block = dagnn.Loss('loss','softmaxlog');
net.addLayer('loss', block, {'conv4','flow'}, {'loss'}, {});
