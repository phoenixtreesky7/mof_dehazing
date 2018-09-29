function lime_out = imexposure_lime(image_input, denoise)

L = imresize(image_input, 1);

% T = max(L(:,:,1),L(:,:,2));
% T = max(T(:,:),L(:,:,3));
% figure, imshow(L./(T+0.05))
%--------------------------------------------------------------


para.lambda = .15;   % Trade-off coefficient
% Although this parameter can perform well in a relatively large range,
% it should be tuned for different solvers and weighting strategies due to
% their difference in value scale.

% Typically, lambda for exact solver < for sped-up solver
% and using Strategy III < II < I
% ---> lambda = 0.15 is fine for SPED-UP SOLVER + STRATEGY III
% ......


para.sigma = 2;      % Sigma for Strategy III
para.gamma = 0.7; %  Gamma Transformation on Illumination Map
para.solver = 1;      % 1: Sped-up Solver; 2: Exact Solver
para.strategy = 3;   % 1: Strategy I; 2: II; 3: III

%---------------------------------------------------------------
tic
[I, T_ini, T_ref] = LIME(L, para);
toc

% figure(1); imshow(L); title('Input');
% figure(2); imshow(I); title('LIME');

%% denoise Processing
if denoise
    YUV = rgb2ycbcr(I);
    Y = YUV(:, :, 1);
    
    sigma_BM3D = 10;
    [~, Y_d] = BM3D(Y, Y, sigma_BM3D, 'lc', 0);
    
    I_d = ycbcr2rgb(cat(3, Y_d, YUV(:, :, 2 : 3)));
    lime_out = (I) .* repmat(T_ref, [1, 1, 3]) + I_d .* repmat(1 - T_ref, [1, 1, 3]);
    
%     figure(5); imshow(I_d); title('Denoised ');
%     figure(6); imshow(lime_out); title('Recomposed');
else
    lime_out = imsharpen(I);
end

end




