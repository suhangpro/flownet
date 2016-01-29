function [ tfm1, tfm2 ] = get_transformations( sz0, sz, varargin)
% GET_TRANSFORMATIONS get transformation arguments 
%   
% additional arguments: 
%   'mode':   'random' | 'fixed'
%   'output': 'image' | 'flow'
%   'scale':  [s_min, s_max] (when 'mode'=='random')
%             [s_1, s_2, ... s_N_a] (when 'mode'=='fixed')
%   'angle':  [a_min, a_max] (counter-clockwise rotation is positive)
%   'flip':   [0] | [1] | [0,1]
%   'N':      number of total regions (when 'mode'=='random')
%   'N_x':    number of different horizontal translations (when 'mode'=='fixed')
%   'N_y':    number of different vertical translations (when 'mode'=='fixed')
%   'N_a':    number of different rotation angles (when 'mode'=='fixed')
%   'delta':  [d_y, d_x] relative displacement (when 'output'=='flow')
%             the displaced x will be in the range of [x-w*d_x,x+w*d_x]
%   'randFn': randFn(v_min,v_max)
% 
%   tfm1 and tfm2 will be 7 x N matrices, where each column specifies a 
%   transformation in form of [x_tl,y_tl,w,h,s,r,f]
% 
% Hang Su
% 
args.mode = 'random';
args.output = 'image';
args.scale = [1];
args.angle = [0];
args.flip = [0];
args.N = 1;
args.N_x = 1;
args.N_y = 1;
args.delta = [0 0];
args.randFn = @(v_min,v_max) (rand()*(v_max-v_min)+v_min);
args = vl_argparse(args, varargin);

% TODO NOT_YET_IMPLEMENTED

end

