function J = getRadiance(A,im,tMat)
t0 = 0.05;
J = zeros(size(im));
[x,y,z] = size(im);
if z == 1
       J(:,:) = A + (im(:,:) - A)./max(tMat,t0); 
else
    for ind = 1:3
        
       J(:,:,ind) = A(ind) + (im(:,:,ind) - A(ind))./max(tMat(:,:),t0); 
    end
end
J = J./(max(max(max(J))));