function [ flow ] = flow_convert( flow, fromType, toType, angles, dists )
%FLOW_CONVERT Convert between optical flow representations
%   
%   fromType:: 'cartesian'|'polar'|'polar_quant'
%     (default: none) 
%   toType:: 'cartesian'|'polar'|'polar_quant'
%     (default: none) 
%   angles::  used in polar coordinates quantization
%     (default: pi/12:pi/12:2*pi-pi/12)
%   dists:: used in polar coordinates quantization 
%     (default: [0.2:0.2:1 1.5:0.5:3.5 4.5:1:8.5 10.5:2:18.5 23.5:5:33.5])
% HSU

if nargin<3, error('No enough input'); end

if ~exist('angles','var') || isempty(angles), 
  angles = pi/12:pi/12:2*pi-pi/12;
end

if ~exist('dists','var') || isempty(dists), 
  dists = [0.2:0.2:1 1.5:0.5:3.5 4.5:1:8.5 10.5:2:18.5 23.5:5:33.5];
end

if strcmpi(fromType,toType), return; end

switch lower(fromType)
  case 'cartesian',       % cartesian==>
    switch lower(toType)
      case 'polar', flow = flow_cart2pol(flow);
      case 'polar_quant', 
        flow = flow_cart2pol(flow);
        flow = cont2discrete(flow, angles, dists); 
      otherwise, error('wrong parameter: %s', toType);
    end
  case 'polar',           % polar==>
    switch lower(toType)
      case 'cartesian', flow = flow_pol2cart(flow);
      case 'polar_quant', flow = cont2discrete(flow, angles, dists); 
      otherwise, error('wrong parameter: %s', toType);
    end
  case 'polar_quant',  % polar(quant)==>
    switch lower(toType)
      case 'polar', flow = discrete2cont(flow, angles, dists);
      case 'cartesian' 
        flow = discrete2cont(flow, angles, dists);
        flow = flow_pol2cart(flow); 
      otherwise, error('wrong parameter: %s', toType);
    end
  otherwise, error('wrong parameter: %s',from);
end

end

function flow = flow_pol2cart(flow)
[x,y] = pol2cart(flow(:,:,1,:),flow(:,:,2,:));
flow = cat(3,x,y);
end

function flow = flow_cart2pol(flow)
[th,r] = cart2pol(flow(:,:,1,:),flow(:,:,2,:));
th(th<0) = th(th<0) + 2*pi;
flow = cat(3,th,r);
end

function X = cont2discrete(X, interv1, interv2)
nQ1 = numel(interv1) + 1;
nQ2 = numel(interv2) + 1;
[~, bin1] = histc(X(:,:,1,:),[-inf interv1(:)' inf]);
[~, bin2] = histc(X(:,:,2,:),[-inf interv2(:)' inf]);
Y = sub2ind([nQ1 nQ2], bin1, bin2);
% Y = sub2ind([nQ2 nQ1], bin2, bin1);
X = zeros(size(Y),'like',X);
X(:) = Y(:);
end

function X = discrete2cont(X, interv1, interv2)
nQ1 = numel(interv1) + 1; 
nQ2 = numel(interv2) + 1; 
[bin1, bin2] = ind2sub([nQ1 nQ2], X); 
% [bin2, bin1] = ind2sub([nQ2 nQ1], X); 
v1 = ([interv1(:)' interv1(end)+(interv1(end)-interv1(end-1))/2] + ...
  [0 interv1(:)']) / 2; 
v2 = ([interv2(:)' interv2(end)+(interv2(end)-interv2(end-1))/2] + ...
  [0 interv2(:)']) / 2; 
X = zeros([size(X,1) size(X,2) 2 size(X,4)], 'like', X); 
X(:,:,1,:) = v1(bin1);
X(:,:,2,:) = v2(bin2); 
end
