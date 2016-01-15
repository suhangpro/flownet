function [ wins ] = get_subwins( sz0, sz, scales, N)
% GET_SUBWINS get subwindows within images 
%   usages: 
%   1. wins = get_subwins(sz0, sz, N)
%       here Ns is a matrix with 3 columns -- [scales, Nxs, Nys]
%   2. wins = get_subwins(sz0, sz, [scale1 scale2], N)
%       this will generate N random samples between scale1 and scale2
% 
%   wins will be a 5 x N matrix, where each column specifies a subwindow 
%   [x_tl,y_tl,w,h] or [x_tl,y_tl,w,h,s]; for the first usage 
%   N=Ns(:,2)'*Ns(:,3)
% 
% Hang Su
% 

if isempty(sz0) || isempty(sz), 
    if nargin>=4,  
        wins = N; 
    else
        wins = scales(:,2)'*scales(:,3);
    end
    return;
end

if size(scales,2)==3,                                       % fixed subwins
    N = scales(:,2)'*scales(:,3);
    wins = zeros(5, N);
    N_cur = 0;
    for i=1:size(scales,1), 
        [S, N1, N2] = deal(scales(i,1),scales(i,2),scales(i,3));
        wins(3:5,N_cur+(1:N1*N2)) = repmat([sz(2);sz(1);S],[1,N1*N2]);
        sz0_s = round(sz0*S);
        assert(all(sz0_s>0));
        assert(all(sz0_s-sz>=0),'scale too low');
        Xs = round(linspace(1,sz0_s(2)-sz(2)+1,N1+2)); Xs = Xs(2:end-1);
        Ys = round(linspace(1,sz0_s(1)-sz(1)+1,N2+2)); Ys = Ys(2:end-1);
        wins(1,N_cur+(1:N1*N2)) = repmat(Xs,[1,N2]);
        wins(2,N_cur+(1:N1*N2)) = reshape(repmat(Ys,[N1,1]),[1 N1*N2]);
        N_cur = N_cur + N1*N2;
    end
else                                                       % random subwins
    assert(numel(scales)==2 || numel(scales)==1);
    if ~exist('N','var'), N = 1; end
    if numel(scales)==1, scales = [scales scales]; end
    assert(all(min(scales)*sz0-sz>=0),'scale too low');
    wins = zeros(5,N); 
    wins(3,:) = sz(2); wins(4,:) = sz(1); 
    wins(5,:) = rand(1,N)*(scales(2)-scales(1))+scales(1);
    wins(1:2,:) = round(rand(2,N).*bsxfun(@minus,round(bsxfun(@times,...
        sz0(:),wins(5,:))),sz(:))+1);
end

end

