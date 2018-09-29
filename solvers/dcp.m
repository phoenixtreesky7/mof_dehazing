function [win_dark,win_darkp]=dcp(I,patch)
[h,w,z]=size(I);
win_dark = zeros(h,w);
for i=1:h                 
    for j=1:w
        win_darkp(i,j)=min(I(i,j,:));%将三个通道中最暗的值赋给dark_I(i,j),显然，三维图变成了二维图
    end
end
% win_dark_p=1-0.95*win_dark;
win_dark = ordfilt2(win_darkp,1,ones(patch,patch),'symmetric');
