function [img_rgb,lightness]=decolor(img)
I=im2double(img);
[x,y,z]=size(img);
Num=x*y;

%%  RGB to HSL  %%
img_hsl=colorspace('hsl<-',img);

hue=img_hsl(:,:,1);
saturation=img_hsl(:,:,2);
lightness=img_hsl(:,:,3);

%figure,imshow(1-Hue)
%figure,imshow(saturation)
%figure,imshow(lightness)


kappa=2;
phi=300;
gamma=0.7;
nu=0.382;
mu=0.1;
chi=1.2;
eta=0.2;

LS_bar=sumLS(lightness,saturation,nu,mu);
[I_dec,COSangle,COSangleS]=Idecolor(hue,saturation,lightness,LS_bar,kappa,phi,gamma,nu,mu,chi,eta);

%r = 60;
%eps = 10^-6;
%q = guidedfilter_color(I, I_dec, r, eps);
%I_dec=max(min(reshape(q,x,y),1),0);

%lightness=I_dec;
lightness=min(I_dec,1);
%figure,imshow(lightness)
%%  HSL to RGB  %%
img_hsl=cat(3,hue,saturation,lightness);
%figure,imshow(img_hsl);
img_rgb=colorspace('rgb<-hsl',img_hsl);
%figure,imshow(img_rgb);





