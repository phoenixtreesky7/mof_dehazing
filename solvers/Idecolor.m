function [idec,cosangle,cosangleS]=Idecolor(hue,sat,lig,lsbar,ik,ip,ig,inu,imu,ichi,ieta)

[x,y,z]=size(hue);

%% Constr %%
angle=((ik*hue+ip)*pi)/180;
cosangle=ig*cos(angle);
cosangleS=sat.*cosangle;
%angleS=angle.*sat;
%cosangleS=cos(angleS);
LconstrL=zeros(x,y);
LconstrS=ones(x,y);
mask=ones(x,y);
for i=1:x
    for j=1:y
        if sat(i,j)>imu && lig(i,j)<inu
            mask(i,j)=0;
        end 
    LconstrS(i,j)=min(max(lig(i,j)*(1+cosangleS(i,j)),0),2);
    LconstrL(i,j)=min(max(lig(i,j)+lsbar*cosangle(i,j),0),2);
        %if Lconstr(i,j)<lig(i,j)
           %Lconstr(i,j)=lig(i,j);
        %end
    end
end


%figure,imshow(LconstrL)
%figure,imshow(LconstrS)

h=fspecial('gaussian',95,5.5);
Mask=imfilter(mask,h);
Lconstr=Mask.*LconstrL+(1-Mask).*LconstrS;

%figure,imshow(Mask)
%figure,imshow(Lconstr)

%Lconstr=lig.*(1+cosangle);
%% Res %%
Lmin=min(min(Lconstr));
Lmax=max(max(Lconstr));

Lres=ichi*((Lconstr-Lmin)/(Lmax-Lmin));
%figure,imshow(Lres)
%% Dec %%

idec=(Lres+ieta*lig)/(ieta+1);
%figure,imshow(idec)














