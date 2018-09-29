%% The Code is created based on the method described in the following papers: 
%   [1] Q. Liu, P.X. Liu, W. Xie, Y. Wang, D. Liang, ¡°GcsDecolor: Gradient correlation similarity for efficient contrast preserving decolorization,¡± 
%    IEEE Trans. Image Process., vol. 24, no. 9, pp. 2889-2904, 2015. 
%   Author: Q. Liu, P.X. Liu, W. Xie, Y. Wang, D. Liang
%   Date  : 02/7/2016
%   Version : 1.0 
%   The code and the algorithm are for non-comercial use only.
%   Copyright 2016, Department of Electronic Information Engineering, Nanchang University.
%   The current version is not optimized.

%   GcsDecolor2 - contrast preserving color-to-gray via Gradient correlation similarity
%   S = GcsDecolor2(Im, Lpp) performs contrast preserving decolorization
%   on color image Im, with controling parameter Lpp
%
%   Paras: 
%   @Im  : Input image (double), only color images are acceptable.
%   @Lpp : Controlling parameter defined in [1]. 0.25 by default.
%
%   Example
%   ==========
%   Im  = im2double(imread('23.png'));
%   gIm  = GcsDecolor2(Im); % Default Parameters (Lpp = 0.25)
%   figure, imshow(Im), figure, imshow(gIm);

function  [img,Es,bw]  = GcsDecolor2(im,Lpp)

if ~exist( 'Lpp', 'var' ),
    Lpp = 0.25;
end

%%  Proprocessing 
[n,m,ch] = size(im); 
W = wei();
 
%%  Global and Local Contrast Computing
ims = imresize(im, round(64/sqrt(n*m)*[n,m]),'nearest');
R = ims(:,:,1);G = ims(:,:,2);B = ims(:,:,3);
imV = [R(:),G(:),B(:)];
%defaultStream = RandStream.getDefaultStream;  
%savedState = defaultStream.State;
t1 = randperm(size(imV,1));
Pg = [imV - imV(t1,:)];

ims = imresize(ims, 0.5 ,'nearest');
Rx = ims(:,1:end-1,1) - ims(:,2:end,1);
Gx = ims(:,1:end-1,2) - ims(:,2:end,2);
Bx = ims(:,1:end-1,3) - ims(:,2:end,3);

Ry = ims(1:end-1,:,1) - ims(2:end,:,1);
Gy = ims(1:end-1,:,2) - ims(2:end,:,2);
By = ims(1:end-1,:,3) - ims(2:end,:,3);
Pl = [[Rx(:),Gx(:),Bx(:)];[Ry(:),Gy(:),By(:)]];

P = [Pg;Pl ]; 
det = sqrt(sum(P.^2,2))/1.41;
P( (det < 0.05),:) = []; 

L = P*W';LL = repmat(L,[1,1,3]);
LL3(:,:,1) = repmat(abs(P(:,1)),[1,size(W,1)]) + Lpp;
LL3(:,:,2) = repmat(abs(P(:,2)),[1,size(W,1)]) + Lpp;
LL3(:,:,3) = repmat(abs(P(:,3)),[1,size(W,1)]) + Lpp;
U = (abs(LL).*LL3)./(LL.^2 + LL3.^2);  
Es = mean(mean(U,1),3);
 
%% Output
[NULLval,bw] = max(Es); 
img = imlincomb(W(bw,1),im(:,:,1) , W(bw,2),im(:,:,2) ,  W(bw,3),im(:,:,3));
 
end

function W = wei()
W = [    0         0    1.0000
         0    0.1000    0.9000
         0    0.2000    0.8000
         0    0.3000    0.7000
         0    0.4000    0.6000
         0    0.5000    0.5000
         0    0.6000    0.4000
         0    0.7000    0.3000
         0    0.8000    0.2000
         0    0.9000    0.1000
         0    1.0000         0
    0.1000         0    0.9000
    0.1000    0.1000    0.8000
    0.1000    0.2000    0.7000
    0.1000    0.3000    0.6000
    0.1000    0.4000    0.5000
    0.1000    0.5000    0.4000
    0.1000    0.6000    0.3000
    0.1000    0.7000    0.2000
    0.1000    0.8000    0.1000
    0.1000    0.9000         0
    0.2000         0    0.8000
    0.2000    0.1000    0.7000
    0.2000    0.2000    0.6000
    0.2000    0.3000    0.5000
    0.2000    0.4000    0.4000
    0.2000    0.5000    0.3000
    0.2000    0.6000    0.2000
    0.2000    0.7000    0.1000
    0.2000    0.8000         0
    0.3000         0    0.7000
    0.3000    0.1000    0.6000
    0.3000    0.2000    0.5000
    0.3000    0.3000    0.4000
    0.3000    0.4000    0.3000
    0.3000    0.5000    0.2000
    0.3000    0.6000    0.1000
    0.3000    0.7000    0.0000
    0.4000         0    0.6000
    0.4000    0.1000    0.5000
    0.4000    0.2000    0.4000
    0.4000    0.3000    0.3000
    0.4000    0.4000    0.2000
    0.4000    0.5000    0.1000
    0.4000    0.6000    0.0000
    0.5000         0    0.5000
    0.5000    0.1000    0.4000
    0.5000    0.2000    0.3000
    0.5000    0.3000    0.2000
    0.5000    0.4000    0.1000
    0.5000    0.5000         0
    0.6000         0    0.4000
    0.6000    0.1000    0.3000
    0.6000    0.2000    0.2000
    0.6000    0.3000    0.1000
    0.6000    0.4000    0.0000
    0.7000         0    0.3000
    0.7000    0.1000    0.2000
    0.7000    0.2000    0.1000
    0.7000    0.3000    0.0000
    0.8000         0    0.2000
    0.8000    0.1000    0.1000
    0.8000    0.2000    0.0000
    0.9000         0    0.1000
    0.9000    0.1000    0.0000
    1.0000         0         0];
end 