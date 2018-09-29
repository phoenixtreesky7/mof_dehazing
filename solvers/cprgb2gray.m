%   Distribution code Version 1.0 -- 09/23/2011 by Jiaya Jia Copyright 2011, The Chinese University of Hong Kong.
%
%   The Code is created based on the method described in the following paper 
%   [1] "Contrast Preserving Decolorization", Cewu Lu, Li Xu, Jiaya Jia,
%   IEEE International Conference on Computational Photography (ICCP), 2012
%  
%   The code and the algorithm are for non-comercial use only.
%   webpage: http://www.cse.cuhk.edu.hk/~leojia/projects/color2gray/

function grayIm = cprgb2gray(Im,sigma)
%cprgb2gray - contrast preserving color to gray
%   S = cprgb2gray(Im, sigma) performs contrast preserving decolorization
%   on color image Im, with controling parameter sigma
%
%   Paras: 
%   @Im    : Input image (double), only color images are acceptable.
%   @sigma : Controlling parameter defined in Eq. 11 in [1]. 2e-2 by default.
%
%   Example
%   ==========
%   Im  = im2double(imread('23.png'));
%   gIm  = cprgb2gray(Im); % Default Parameters (sigma = 2e-2)
%   figure, imshow(Im), figure, imshow(gIm);

if ~exist( 'sigma', 'var' ),
    sigma = 0.02;
end

if ndims(Im)~=3
    grayIm = Im;
    return;
end


%% parameter seting
order = 2;
pre_E = inf;
E = 0;
tol = 10^(-4);
maxIter = 15;
iterCount = 0;

%% polynomial initialization
[polyGrad, Cg, combination ] = grad_system(Im, order);
alf = weak_order(Im);

%% Solver   
Mt = wei_update_matrix(polyGrad, Cg);
wei = wei_inti(combination);

while  norm(E - pre_E,2) > tol
  iterCount = iterCount + 1;  
  pre_E = E;  

  G_pos = ( 1 + alf )/2.*exp(- 0.5*(polyGrad*wei - Cg).^2/sigma^2);
  G_neg = ( 1 - alf )/2.*exp(- 0.5*(polyGrad*wei + Cg).^2/sigma^2);
  EXPsum = G_pos + G_neg;
  EXPterm = (G_pos - G_neg)./(EXPsum + double(EXPsum == 0) );
  wei = Mt*EXPterm; 
 
  E = energyCalcu(Cg,polyGrad, wei, sigma); 
 
  if  iterCount > maxIter
      break;
  end
end
grayIm  = grayImContruct(wei, Im, order);

end

function E = energyCalcu(Cg,polyGrad,wei,sigma)
  P =  -log(exp(-(polyGrad*wei - Cg).^2/sigma) + exp(-(polyGrad*wei + Cg).^2/sigma));
  E = mean(P);
end

function alf = weak_order(Im)
   [n,m] = size(Im(:,:,1));
   if (n + m) > 800
       sizeFactor = 800/(n + m);
       Im = imresize(Im,round([n,m]*sizeFactor));
   end

  Rg =  singleChannelGrad(Im(:,:,1));
  Gg =  singleChannelGrad(Im(:,:,2));
  Bg =  singleChannelGrad(Im(:,:,3));
  level = 0.05;
 
  alf = double(Rg > level).* double(Gg > level).* double(Bg > level);
  alf = alf - double(Rg < -level).* double(Gg < -level).* double(Bg < -level);
  disp([num2str(round(100*sum(abs(alf))/length(alf))),'% pixel use weak order']);
end


function [ polyGrad,Cg,combination ] = grad_system(Im,order)
   [n,m] = size(Im(:,:,1));
   if (n + m) > 800
       sizeFactor = 800/(n + m);
       Im = imresize(Im,round([n,m]*sizeFactor));
   end   
   polyGrad = [];
   combination = [];
   Cg = ColorGrad(Im);
   for r = 0 : order
       for g = 0 : order
           for b = 0 : order
               if (r + g + b) <= order && (r + g + b) > 0
                   combination = [combination;[r,g,b]];
                   curIm = (Im(:,:,1).^r).* (Im(:,:,2).^g).* (Im(:,:,3).^b);
                   curGrad = singleChannelGrad(curIm);
                   polyGrad  = [polyGrad, curGrad ];
               end
           end
       end
   end
end

function imGradVector = singleChannelGrad(imChannel)
   Xg =  (imfilter(imChannel,[1,-1])); Xg(:,end) = 0;   
   Yg =  (imfilter(imChannel,[1;-1])); Xg(end,:) = 0;
   imGradVector = [Xg(:);Yg(:)];
end

function Cg = ColorGrad(Im)
  ImLab = applycform(Im,makecform('srgb2lab'));
  ImL = singleChannelGrad(ImLab(:,:,1));
  Ima = singleChannelGrad(ImLab(:,:,2));
  Imb = singleChannelGrad(ImLab(:,:,3));
  Cg = sqrt(ImL.^2 + Ima.^2 + Imb.^2)/100;
end

function Mt = wei_update_matrix(poly, Cg)
  B = poly';
  for ii = 1 : size(B,1)
    B(ii,:) = B(ii,:).*Cg';
  end
  Mt = (poly'*poly)\B;
end

function wei = wei_inti(combination)
  initRGB = [0.33;0.33;0.33]; 
  wei = combination*initRGB;
  wei = wei.* double(sum(combination,2) == 1); 
end

function  grayIm  = grayImContruct(wei,Im, order)
   [n,m] = size(Im(:,:,1));
   grayIm = zeros(n,m);
   ImR = Im(:,:,1); ImG = Im(:,:,2); ImB = Im(:,:,3);
   kk = 0;
   for r = 0 : order
       for g = 0 : order
           for b = 0 : order
               if (r + g + b) <= order &&  (r + g + b) > 0
                   kk = kk + 1;
                   grayIm  = grayIm + wei(kk)*(ImR.^r).*(ImG.^g).*(ImB.^b);
               end
           end
       end
   end   
   grayIm =  (grayIm- min(grayIm(:)))/(max(grayIm(:)) - min(grayIm(:)));
end





