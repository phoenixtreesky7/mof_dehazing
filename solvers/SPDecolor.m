function [grayIm] = SPDecolor(Im,sigma)
%SPDecolor - contrast preserving color to gray
%   S = SPDecolor(Im, sigma) performs contrast preserving decolorization
%   on color image Im, with controling parameter sigma
%
%   Paras: 
%   @Im    : Input image (double), only color images are acceptable.
%   @sigma : Controlling parameter defined in [1]. 1e-2 by default.
%
%   Example
%   ==========
%   Im  = im2double(imread('23.png'));
%   gIm  = SPDecolor(Im); % Default Parameters (sigma = 1e-2)
%   figure, imshow(Im), figure, imshow(gIm);

if ~exist( 'sigma', 'var' ),
    sigma = 0.005;
end

if ndims(Im)~=3
    grayIm = Im;
    return;
end


%% parameter seting
order = 2;
pre_E = inf;
E = 0;
tol = 10^(-4);  %0;  %
maxIter = 15;
iterCount = 0;

%% polynomial initialization
[polyGrad, Cg, combination ] = grad_system(Im, order);
alf = weak_order(polyGrad);

%% Solver   
%wei = wei_inti(combination);  %9x1µÄjuzhen
wei = zeros(9,1);
Mt = wei_update_matrix(polyGrad);  %, wei, Cg
wei_index = [0,1,0,1,1,0,1,1,1];
wei(wei_index==0) = flipud([0.2989;0.5870;0.1140]);
Cg1 = Cg - polyGrad(:,[1,3,6])*wei([1,3,6]);
Cg2 = Cg + polyGrad(:,[1,3,6])*wei([1,3,6]);

while  norm(E - pre_E,2) > tol
  iterCount = iterCount + 1;  
  pre_E = E;  

  G_pos = ( 1 + alf )/2.*exp(- 0.5*(polyGrad*wei - Cg).^2/sigma^2);
  G_neg = ( 1 - alf )/2.*exp(- 0.5*(polyGrad*wei + Cg).^2/sigma^2);
  EXPsum = G_pos + G_neg;
  EXPterm = (G_pos.*Cg1 - G_neg.*Cg2)./(EXPsum + double(EXPsum == 0) );
  wei_temp = Mt*EXPterm; 
  wei(wei_index==1) = wei_temp;
  
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

function alf = weak_order(polyGrad)
  Rg =  polyGrad(:,6);Gg =  polyGrad(:,3);Bg =  polyGrad(:,1);
  level = 0.05;
 
  alf = double(Rg > level).* double(Gg > level).* double(Bg > level);
  alf = alf - double(Rg < -level).* double(Gg < -level).* double(Bg < -level);
  disp([num2str(round(100*sum(abs(alf))/length(alf))),'% pixel use weak order']);
end


function [ polyGrad,Cg,combination ] = grad_system(Im,order)
%%  Global and Local Contrast Computing
[n,m,ch] = size(Im);
ims = imresize(Im, round(64/sqrt(n*m)*[n,m]),'nearest');
R = ims(:,:,1);G = ims(:,:,2);B = ims(:,:,3);
imV = [B(:),B(:).^2,G(:),G(:).*B(:),G(:).^2,R(:),R(:).*B(:),R(:).*G(:),R(:).^2];
%defaultStream = RandStream.getDefaultStream; savedState = defaultStream.State;
t1 = randperm(size(imV,1));
polyGrad = [imV - imV(t1,:)];
ims = imresize(ims, 0.5 ,'nearest');
Pl = [];
for r = 0 : order
    for g = 0 : order
        for b = 0 : order
            if (r + g + b) <= order && (r + g + b) > 0
                curIm = (Im(:,:,1).^r).* (Im(:,:,2).^g).* (Im(:,:,3).^b);
                Rx = curIm(:,1:end-1,1) - curIm(:,2:end,1);Ry = curIm(1:end-1,:,1) - curIm(2:end,:,1);
                Pl = [Pl,[Rx(:);Ry(:)]];
            end
        end
    end
end
polyGrad = [polyGrad;Pl];
 
Cg = sqrt(sum(polyGrad(:,[1,3,6]).^2,2))/1.41;
Thr = 0.05;polyGrad( (Cg < Thr),:) = []; Cg( (Cg < Thr)) = [];  %
combination = [0 0 1; 0 0 2; 0 1 0; 0 1 1; 0 2 0; 1 0 0; 1 0 1; 1 1 0; 2 0 0];

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

function Mt = wei_update_matrix(poly)  %,wei,Cg
%Cg = Cg-poly(:,[1,3,6])*wei([1,3,6]);
poly(:,[1,3,6]) = [];
B = poly';
% for ii = 1 : size(B,1)
%     B(ii,:) = B(ii,:).*Cg';
% end
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





