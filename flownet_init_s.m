function net = flownet_init_s(varargin)
% FLOWNET_S_INIT  FlowNetS model initialization 

net = dagnn.DagNN();

% image pre-prosessing settings 
net.meta.normalization.multiplier = 64;
net.meta.normalization.interpolation = 'bilinear' ;
net.meta.normalization.averageImage = single([123.6591  116.7663  103.9318]);
net.meta.normalization.convertFlowFmt = 'none';

block = dagnn.Concat('dim',3);
net.addLayer('im_concat', block, {'im1','im2'}, {'im_concat'}, {});

% contracting (2^6 downsampled)
net = addConvLayer(net, '1', 'im_concat', [7 7 6 64], 2); 
net = addConvLayer(net, '2', 'relu1', [5 5 64 128], 2); 
net = addConvLayer(net, '3_1', 'relu2', [5 5 128 256], 2); 
net = addConvLayer(net, '3_2', 'relu3_1', [3 3 256 256], 1); 
net = addConvLayer(net, '4_1', 'relu3_2', [3 3 256 512], 2); 
net = addConvLayer(net, '4_2', 'relu4_1', [3 3 512 512], 1); 
net = addConvLayer(net, '5_1', 'relu4_2', [3 3 512 512], 2); 
net = addConvLayer(net, '5_2', 'relu5_1', [3 3 512 512], 1); 
net = addConvLayer(net, '6_1', 'relu5_2', [3 3 512 1024], 2); 
net = addConvLayer(net, '6_2', 'relu6_1', [3 3 1024 1024], 1); 

% expanding w/ skip connections (restore original resolution)
net = addDeconvLayer(net, 'relu6_2', 'relu5_2', 'concat5', 'pred6', [4 4 512 1024], [3 3 1024 2], 2);
net = addDeconvLayer(net, 'concat5', 'relu4_2', 'concat4', 'pred5', [4 4 256 1026], [3 3 1026 2], 2);
net = addDeconvLayer(net, 'concat4', 'relu3_2', 'concat3', 'pred4', [4 4 128 770], [3 3 770 2], 2);
net = addDeconvLayer(net, 'concat3', 'relu2', 'concat2', 'pred3', [4 4 64 386], [3 3 386 2], 2);

% final prediction
block = dagnn.Conv('size',[3 3 194 2], 'hasBias',true, 'pad',1, 'stride',1);
net.addLayer('pred2', block, {'concat2'}, {'pred2'}, {'pred2_f', 'pred2_b'});
%{
block = dagnn.ConvTranspose('size',[7 7 2 2], 'initMethod','bilinear', 'frozen',true, ...
                            'hasBias', false, 'upsample',4, 'crop',[2 1 2 1]);
net.addLayer('pred', block, 'pred2', 'pred', 'pred_f');
net.params(net.getParamIndex('pred_f')).learningRate = 0;
%}

% loss
net = addLossLayer(net, 'pred2', 'gt', 'loss2', 2^2, 2);
net = addLossLayer(net, 'pred3', 'gt', 'loss3', 2^3, 2);
net = addLossLayer(net, 'pred4', 'gt', 'loss4', 2^4, 2);
net = addLossLayer(net, 'pred5', 'gt', 'loss5', 2^5, 2);
net = addLossLayer(net, 'pred6', 'gt', 'loss6', 2^6, 2);
net = addWeightedLoss(net, 'loss', {'loss2','loss3','loss4','loss5','loss6'}, ...
  [0.005 0.01 0.02 0.08 0.32]); 

end

function net = addConvLayer(net, out_suffix, in_name, f_size, stride)

block = dagnn.Conv('size',f_size, 'hasBias',true, 'stride', stride, ...
                   'pad',[ceil(f_size(1)/2-0.5) floor(f_size(1)/2-0.5) ...
                   ceil(f_size(2)/2-0.5) floor(f_size(2)/2-0.5)]);
net.addLayer(['conv' out_suffix], block, {in_name}, {['conv' out_suffix]}, ...
    {['conv' out_suffix '_f'],['conv' out_suffix '_b']}); 

block = dagnn.ReLU('leak',0.1);
net.addLayer(['relu' out_suffix], block, {['conv' out_suffix]}, {['relu' out_suffix]}, {});

end

function net = addDeconvLayer(net, in_coarse, in_fine, out, pred, ...
    deconv_f_sz, pred_f_size, up_x)

block = dagnn.Conv('size', pred_f_size, 'hasBias', true, 'stride', 1, ...
    'pad', [ceil(pred_f_size(1)/2-0.5) floor(pred_f_size(1)/2-0.5) ...
    ceil(pred_f_size(2)/2-0.5) floor(pred_f_size(2)/2-0.5)]);
net.addLayer(pred, block, {in_coarse}, {pred}, {[pred '_f'],[pred '_b']});

block = dagnn.ConvTranspose('size', [2*up_x-1 2*up_x-1 pred_f_size(4) pred_f_size(4)], ...
    'crop', [ceil(up_x/2-0.5) floor(up_x/2-0.5) ceil(up_x/2-0.5) floor(up_x/2-0.5)], ...
    'initMethod', 'bilinear', 'hasBias', false, 'upsample', up_x);
net.addLayer([pred '_up'], block, {pred}, {[pred '_up']}, {[pred '_up_f']});
pidx = net.getParamIndex([pred '_up_f']); 
net.params(pidx).learningRate = 0; 

block = dagnn.ConvTranspose('size', deconv_f_sz, 'hasBias', true, 'upsample', up_x, ...
    'crop', [ceil((deconv_f_sz(1)-up_x)/2) floor((deconv_f_sz(1)-up_x)/2) ...
    ceil((deconv_f_sz(2)-up_x)/2) floor((deconv_f_sz(2)-up_x)/2)]);
net.addLayer([in_coarse '_deconv'], block, {in_coarse}, {[in_coarse '_deconv']}, ...
    {[in_coarse '_deconv_f'] [in_coarse '_deconv_b']});

block = dagnn.ReLU('leak', 0.1);
net.addLayer([in_coarse '_deconv_relu'], block, {[in_coarse '_deconv']}, ...
    {[in_coarse '_deconv_relu']}, {});

block = dagnn.Concat('dim', 3);
net.addLayer(out, block, {in_fine, [in_coarse '_deconv_relu'], [pred '_up']}, {out}, {});

end

function net = addLossLayer(net, pred, flow_gt, loss, down_x, pred_dim)

block = dagnn.Conv('size', [1 1 pred_dim pred_dim], 'hasBias', false, ...
    'stride', down_x, 'initMethod', 'one');
lName = [flow_gt '_' num2str(down_x)]; 
net.addLayer(lName, block, flow_gt, lName, [lName '_f']);
pidx = net.getParamIndex([lName '_f']);
net.params(pidx).learningRate = 0; 

block = dagnn.Loss('loss', 'l2');
net.addLayer(loss, block, {pred, lName}, loss);

end

function net = addWeightedLoss(net, out, loss_layers, ws)

block = dagnn.Concat('dim', 1);
net.addLayer([out '_concat'], block, loss_layers, [out '_concat']);

block = dagnn.Conv('size', [numel(loss_layers) 1 1 1], 'hasBias', false);
net.addLayer(out, block, [out '_concat'], out, [out '_w']);
pidx = net.getParamIndex([out '_w']);
net.params(pidx).value = single(ws(:));
net.params(pidx).learningRate = 0; 

end
