function LS=sumLS(lig,sat,lsnu,lsmu)


[x,y,z]=size(lig);
N=x*y;

for i=1:x
    for j=1:y
        if lig(i,j)<lsnu
            lig(i,j)=0;
        end
        if sat(i,j)<lsmu
            sat(i,j)=0;
        end
    end
end


LS_m=lig.*sat;
LS_s=sum(sum(LS_m));
LS=LS_s/N;




