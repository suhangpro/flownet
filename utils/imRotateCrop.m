function imout = imRotateCrop(im, theta, varargin)
%IMROTATECROP rotates and crops an image, removing undefined areas
%   When an image is rotated some pixels in the output image correspond to
%   positions outside the boundaries of the input image. Such pixels have
%   to be given an arbitrary value such as 0, and appear typically as black
%   triangles when the rotated image is displayed. IMROTATECROP crops the
%   output to remove these triangles.
% 
%   IMOUT = IMROTATECROP(IMG, THETA) rotates an image IMG by THETA degrees
%   about its centre point using nearest neighbour interpolation. The
%   rotation is anticlockwise for positive THETA. The output image IMOUT is
%   cropped symmetrically with its aspect ratio chosen to retain the
%   maximum number of pixels.
%
%   IMOUT = IMROTATECROP(IMG, THETA, METHOD) also specifies the
%   interpolation method. METHOD is passed as the third argument to
%   IMROTATE. The default is 'nearest'.
% 
%   IMOUT = IMROTATECROP(IMG, THETA, NAME1, VALUE1, ...)
%   IMOUT = IMROTATECROP(IMG, THETA, METHOD, NAME1, VALUE1, ...) allow
%   additional parameters to be set using name-value pairs.
% 
%       'AspectRatio' sets the width/height ratio of IMOUT. Values may be:
% 
%           'maxArea' (default) - The output image has the maximum possible
%           area (i.e. number of pixels).
% 
%           'fourPoint' - The corners of the output image all lie within a
%           pixel's width of the rotated boundaries of the input image. If
%           there is no four-point solution (see notes below) IMOUT will be
%           empty.
% 
%           'same' - The aspect ratio of IMOUT is set as close as possible
%           to the aspect ratio of IMG. Slight differences arise because
%           the widths and heights of the arrays must be integers.
% 
%           A positive scalar - The aspect ratio of IMOUT is set as close
%           as possible to the value given.
% 
%       'Position' sets the position of IMOUT within the rotated image. The
%       value must be a real scalar in the range -1 to +1 and has the
%       following effects, where A is the aspect ratio of IMG:
% 
%           -1 places IMOUT as far as possible to the left (for A >= 1) or
%           bottom (for A < 1) of the unrotated image;
%
%           0 (default) places IMOUT centrally;
% 
%           +1 places IMOUT as far as possible to the right (for A >= 1) or
%           top (for A < 1) of the unrotated image;
% 
%       Intermediate values give intermediate positions. The position
%       parameter has no effect if the aspect ratio is such as to produce a
%       four-point contact.
% 
%   BOXOUT = IMROTATECROP(BOXIN, THETA, ...) where BOXIN is a structure
%   computes the size and position without rotating an image. BOXIN must
%   have fields 'width' and 'height' whose values are positive scalars
%   giving the width and height of the input image. These do not need to be
%   integers. BOXOUT will be a structure with fields 'width', 'height',
%   'xshift' and 'yshift' giving the width and height of the output image,
%   together with the vector offset of the centre of the output image
%   relative to the centre of the input image (using the standard image
%   coordinate system). The output values are not rounded to integers. If a
%   four-point solution is requested when none exists, BOXOUT.width and
%   BOXOUT.height will be NaN.
% 
%   Notes
%   -----
% 
%   Two opposite corners of the boundary of the output image will always
%   lie on rotated sides of the input image. If 'AspectRatio' is set to
%   'maxArea' these will be the longer sides.
% 
%   If 'Position' is +1 or -1 a third corner will lie on one of the rotated
%   sides.
% 
%   There will be an output aspect ratio for which all four corners lie on
%   rotated sides if tan(T) <= R, where T is the modulus of the angle
%   between the longer sides of the rotated image and the nearest cardinal
%   direction, and R is the length of the shorter side of the input image
%   divided by the length of the longer side.
% 
%   This four-point solution will also be the maximum area solution if
%   sin(2*T) <= R.
% 
%   Examples
%   --------
% 
%   img = imread('cameraman.tif');
%   imrot = imRotateCrop(img, 30, 'bilinear');
%   imshow(imrot);
% 
%   img = imread('peppers.png');
%   theta = -35;
%   imrot_nocrop = imrotate(img, theta);    % not cropped
%   imshow(imrot_nocrop);                   % display uncropped image
%   boxin.width = size(img, 2);
%   boxin.height = size(img, 1);
%   % get coordinates of output region keeping aspect ratio the same and
%   % pushing to left of image
%   boxout = imRotateCrop(boxin, theta, ...
%           'AspectRatio', 'same', 'Position', -1);
%   % plot box on uncropped image, showing where cropped image would be
%   xcentre = (1+size(imrot_nocrop, 2))/2 + boxout.xshift;
%   ycentre = (1+size(imrot_nocrop, 1))/2 + boxout.yshift;
%   w2 = boxout.width/2;
%   h2 = boxout.height/2;
%   xcrds = xcentre + [w2 w2 -w2 -w2 w2];   % box corner coords
%   ycrds = ycentre + [h2 -h2 -h2 h2 h2];
%   hold on;
%   plot(xcrds, ycrds, 'g-');
%   hold off;
%
%   See also: IMROTATE

% Copyright 2014 David Young

inp = inputParser;
inp.addOptional('Method', 'nearest', ...
    @(s) ~ismember(s, {'AspectRatio' 'Position'}));
inp.addParameter('AspectRatio', 'maxArea', ...
    @(s) (ischar(s) && ismember(s, {'maxArea' 'fourPoint' 'same'})) || ...
    checkattributes(s, {'numeric'}, {'positive' 'scalar'}));
inp.addParameter('Position', 0, ...
    @(p) validateattributes(p, {'numeric'}, ...
    {'real' 'scalar' '>=' -1 '<=' 1}));
inp.parse(varargin{:});
method = inp.Results.Method;
aspect = inp.Results.AspectRatio;
position = inp.Results.Position;

crdsOnly = isstruct(im);
if crdsOnly
    w = im.width;
    h = im.height;
    if w <= 0 || h <= 0
        error('imRotateCrop:badSize', 'Width and height must be positive');
    end
else
    [h, w, ~] = size(im);
end

[wp, hp, xoff, yoff] = fitrect(w, h, theta, aspect, position);

if crdsOnly
    
    imout.width = wp;
    imout.height = hp;
    imout.xshift = xoff;
    imout.yshift = -yoff;   % reverse for image coord convention
    
else
    
    if isnan(wp)
        imout = [];      % no four-point solution
    else
        imout = imrotate(im, theta, method, 'loose');
        
        [hr, wr, ~] = size(imout);
        % dimension are of box on outside of outer pixels
        y0 = 1 + ceil((hr - hp)/2 - yoff);
        y1 = floor((hr + hp)/2 - yoff);
        x0 = 1 + ceil((wr - wp)/2 + xoff);
        x1 = floor((wr + wp)/2 + xoff);
        imout = imout(y0:y1, x0:x1, :);
    end
    
end

end


function [wp, hp, xoff, yoff] = fitrect(w, h, theta, aspect, position)
% Inputs: the width and height of the original rectangle, the angle by
% which it is rotated, the aspect ratio of the output rectangle, and the
% position parameter for the output rectangle.
% Outputs: the width and height of the output rectangle, the offset of the
% centre of the output rectangle from the centre of the input rectangle.

% Transform to a problem where the input aspect ratio is greater than 1
% and the angle of rotation is between 0 and 45 degrees.
a = w / h;                  % save original aspect ratio
tall = w < h;
if tall
    [w, h] = deal(h, w);    % invert aspect ratio if necessary
end
csgn = cosd(theta);         % save original rotation
ssgn = sind(theta);         % angle
c = abs(csgn);              % symmetries allow most of computation to use
s = abs(ssgn);              % absolute rotation angles
bigrot = s > c;
if bigrot                   % take complement of angle if necessary
    [s, c, ssgn, csgn] = deal(c, s, csgn, ssgn);
end
swapxy = xor(tall, bigrot);

% Now working with c, s in range 0 to 1/sqrt(2) and r in range 0 to 1
r = h / w;                  % inverse original aspect ratio
sin2th = 2 * c * s;
cos2th = c*c - s*s;
gamma = NaN;
delta = NaN;
fourpt = false;

% switch on aspect ratio spec to find either:
%   delta: (delta+1)/2 is the fraction of the distance along the long side
%   of the rotated rectangle, starting at bottom left, at which an output
%   corner touches it; or
%   gamma: (gamma+1)/2 is the fraction of the distance along the short side
%   starting at bottom right, at which an output corner touches it.
if strcmp(aspect, 'fourPoint')
    
    if s <= r*c             % four contacts possible?
        fourpt = true;
        if cos2th > eps     % test for special 45 degree, r=1 case
            delta = (1 - r*sin2th)/cos2th; % general case
        else
            delta = 0;      % special case
        end
    end
    
elseif strcmp(aspect, 'maxArea')
    
    if sin2th < r           % four contact is max area solution?
        fourpt = true;
        if cos2th > eps     % test for special 45 degree, r=1 case
            delta = (1 - r*sin2th)/cos2th; % general 4-contact case
        else
            delta = 0;      % special 4-contact case
        end
    else
        delta = r * cos2th / sin2th; % 2-contact max area solution
    end
    
else        % aspect ratio specified
    
    if strcmp(aspect, 'same')
        aspect = a;     % same as original image
    end
    if swapxy
        aspect = 1 / aspect;    % allow for initial transformation
    end
    
    if r * (aspect*c + s) <= aspect*s + c  % test for long side contact
        delta = r * (c*aspect - s) / (s*aspect + c);
    else    % short side contact
        gamma = (c - s*aspect) / (r * (s + c*aspect));
    end
    
end

% use delta or gamma to find output width and height
xoff = 0;           % default position offset
yoff = 0;
if ~isnan(delta)
    
    wp =  c * delta * w + s * h;
    hp = -s * delta * w + c * h;
    
    if position && ~fourpt
        % shift parallel to long side, +ve to right
        shift = position * ((1+delta)*w/2 - c*wp);
        xoff = csgn * shift;
        yoff = ssgn * shift;
    end
    
elseif ~isnan(gamma)
    
    wp = c * w - s * gamma * h;
    hp = s * w + c * gamma * h;
    
    if position
        % shift parallel to short side - complex sign correction so still
        % +ve to right
        shift = position * sign(csgn*ssgn) * ((1+gamma)*h/2 - c*hp);
        if bigrot
            shift = -shift;
        end
        xoff = ssgn * shift;
        yoff = -csgn * shift;
    end
    
else    % four point solution requested, but not possible
    
    wp = NaN;
    hp = NaN;
    
end

% reverse transform carried out at start
if swapxy
    [wp, hp, xoff, yoff] = deal(hp, wp, yoff, xoff);
end
if tall
    xoff = -xoff;
end

end