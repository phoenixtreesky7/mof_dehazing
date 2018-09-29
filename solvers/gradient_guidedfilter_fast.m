
function [q, chi_I, weight, gamma, mean_a, mean_b] = gradient_guidedfilter_fast(Ipro, ppro, eps, s)
%   GUIDEDFILTER   O(1) time implementation of guided filter.
%
%   - guidance image: I (should be a gray-scale/single channel image)
%   - filtering input image: p (should be a gray-scale/single channel image)
%   - regularization parameter: eps

I = imresize(Ipro, 1/s, 'lanczos3'); % NN is often enough
p = imresize(ppro, 1/s, 'lanczos3');
[hei, wid] = size(I);

r = 60; 


if min(hei, wid) < 2 * r
    r = floor( min(hei, wid) / 2 ) - 1;
end

N = boxfilter(ones(hei, wid), r); % the size of each local patch; N=(2r+1)^2 except for boundary pixels.

mean_I = boxfilter(I, r) ./ N;
mean_p = boxfilter(p, r) ./ N;
mean_Ip = boxfilter(I.*p, r) ./ N;
cov_Ip = mean_Ip - mean_I .* mean_p; % this is the covariance of (I, p) in each local patch.

mean_II = boxfilter(I.*I, r) ./ N;
var_I = mean_II - mean_I .* mean_I;

%weight
epsilon=(0.01*(max(p(:))-min(p(:))))^2;
r1=1;

N1 = boxfilter(ones(hei, wid), r1); % the size of each local patch; N=(2r+1)^2 except for boundary pixels.
mean_I1 = boxfilter(I, r1) ./ N1;
mean_II1 = boxfilter(I.*I, r1) ./ N1;
var_I1 = mean_II1 - mean_I1 .* mean_I1;

chi_I=sqrt(abs(var_I1.*var_I));    
weight=(chi_I+epsilon)/(mean(chi_I(:))+epsilon);     

gamma = (4/(mean(chi_I(:))-min(chi_I(:))))*(chi_I-mean(chi_I(:)));
gamma = 1 - 1./(1 + exp(gamma));

%result
a = (cov_Ip + (eps./weight).*gamma) ./ (var_I + (eps./weight)); 
b = mean_p - a .* mean_I; 

mean_a = boxfilter(a, r) ./ N;
mean_b = boxfilter(b, r) ./ N;

mean_a = imresize(mean_a, [size(Ipro, 1), size(Ipro, 2)], 'lanczos3'); % bilinear is recommended
mean_b = imresize(mean_b, [size(Ipro, 1), size(Ipro, 2)], 'lanczos3');


q = mean_a .* Ipro + mean_b; 
end

















