function [win_dark,win_darkp]=dcp_multiscale(I, patch)
% this code using to calculate the DCP for different scales
% Input - patch: is a 1D vector 

patch_length = length(patch);
[h, w, z]=size(I);
win_dark = cell(patch_length,1);
for index = 1 : h                 
    for jndex = 1 : w
        win_darkp(index, jndex)=min(I(index, jndex, :));%将三个通道中最暗的值赋给dark_I(i,j),显然，三维图变成了二维图
    end
end

% win_dark_p=1-0.95*win_dark;
for index = 1 : patch_length
    win_dark{index} = ordfilt2(win_darkp, 1, ones(patch(index), patch(index)), 'symmetric');
end
