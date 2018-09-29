function [ exposureOutput, mean_luminance_I, mean_luminance_J, mean_exposureOutput ] = imexposure( J, I )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a function to enhance the input image's exposure.
% Image Exposure Algorithm using GIF
%
% Input  :
%        J        The poor exposure image, color iamge
%        I        The guidance of the Guided Image Filter, grayscale
%   lambda  The regular parameter
% Output:
%   exposureOutput     The exposure improved image
%   exposureScaling     The exposure scaling for each pixels
%
% NOTE !!!
% 1.  The I and J should be double format.
% 2.  The J can also be a color image, while the guidedfilter() function
% should be replaced by the guidedfilter_color().
%
% This algorithm is drived by:
% Investigating Haze-relevant Features in A Learning Framework for Image Dehazing
% Ketan Tang et.al.    2014  CVPR
%
% Edit by Dong Zhao, 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%I = decolor(I);
hsl_I=colorspace('hsl<-', I);
hsl_J=colorspace('hsl<-', J);
I_gray = rgb2gray( I );

luminance_I = hsl_I(:, :, 3);
luminance_J = max(hsl_J(:, :, 3), 0);
[x, y] = size( luminance_I );
mean_luminance_I = mean( mean( luminance_I ) );
mean_luminance_J = mean( mean( luminance_J ) );

%lambda = 0.1;
eps = 10^(-6);
lambda = 0.1*mean_luminance_J;
IxI = lambda * luminance_I .* luminance_I;
JxJ = luminance_J .* luminance_J;
IxJ = luminance_J .* luminance_I;

[x,y] = size(I_gray);
for index = 1 : x
    for jndex = 1 : y
        if JxJ(index, jndex) + IxI(index, jndex) == 0
            JxJ(index, jndex) = 0.02;
        end
    end
end

S = ( IxJ + IxI ) ./ ( JxJ + IxI );

s = 1;
exposureScaling = gradient_guidedfilter_fast( I_gray, S, eps, s );
hsl_J(:, :, 3) = max( min( exposureScaling .* hsl_J(:, :, 3), max( max( luminance_I) ) ), 0 );

exposureOutput = colorspace('rgb<-hsl', hsl_J);
exposureOutput_gray = im2double(rgb2gray(exposureOutput));
for index = 1 : x
    for jndex = 1 : y
        if exposureOutput_gray(index, jndex) >=0.7
            exposureOutput_gray(index, jndex) = 0;
        end
    end
end

mean_exposureOutput = mean(mean(exposureOutput_gray));
weight = ((1-mean_exposureOutput)^2 - 0.6) * 10;
if weight > 1 && weight < 2
    exposureOutput = weight * autolevel(exposureOutput);
elseif weight > 2
    exposureOutput = (weight + 1) * autolevel(exposureOutput);
elseif weight < 1
     exposureOutput = auto_level(exposureOutput);
end












