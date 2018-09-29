
% This is a Matlab re-implementation of the paper.
%
% Multi-scale Optimal Fusion Model for Single Image Dehazing
%
% Dong Zhao, Long Xu, Yihua Yan, Jie Chen, Lingyu Duan
% 2018.07.23


close all
clear all
clc

path_MOF = 'F:\1_MyWork\GitHub\mof_dome\MOF\';  % your path for results saving
path_input = 'F:\1_MyWork\GitHub\mof_dome\hazy\';  % your path for input reading

if ~exist(path_MOF)
    mkdir(path_MOF);
end
%%  Image Reading
imgDataDir  = dir(path_input);
length_file = size(imgDataDir, 1);
for ifile = 1 : length_file
    if (isequal(imgDataDir(ifile).name, '.')||...
            isequal(imgDataDir(ifile).name, '..')||...
            imgDataDir(ifile).isdir)
        continue;
    end
    image_name = dir([path_input '*.png']);
end

%% Parameters Setting
denoise = 1;
subsampling = 2;
method.A = 1;              % A estimating method:           0 -> DCP method;   1 -> HezeLine method
method.exposure = 1;   % Exposure method:                0 -> our paper;       1 -> LIME method
method.stretch = 1;      % D_{tanh} stretched method:  0 -> linear;              1 -> tanh
RunningTime = zeros(1,  size(image_name, 1))';
PixleNumber = zeros(1,  size(image_name, 1));

%% MOF Dehazing
for pic = 1 : 1 : size(image_name, 1)
    pic
    
    image_hazy = im2double(imread(strcat(path_input, image_name(pic).name)));
    PixleNumber(pic) = size(image_hazy, 1) * size(image_hazy, 2);

    % Scale number
    dcpR(1) = 2 * floor(log10(PixleNumber(pic)));  alpha = 1;
    dcpR(2) = 2 * dcpR(1);                                    alpha = 2;
%   dcpR(3) = 3 * dcpR(1);                                    alpha = 3;
%   dcpR(4) = 4 * dcpR(1);                                    alpha = 4;
    %%   A
    t1 = clock;
    if ~method.A
        % --  DCP A  -- %
        dark = dcp(image_hazy, 15);
        numpx = floor(PixleNumber(pic) / 1000);
        J_dark_vec = reshape(dark, PixleNumber(pic), 1);
        I_vec = reshape(image_hazy, PixleNumber(pic), 3);
        
        [J_dark_vec, indices] = sort(J_dark_vec);
        indices = indices(PixleNumber(pic) - numpx + 1 : end);
        
        atmSum = zeros(1, 3);
        for ind = 1 : numpx
            atmSum = atmSum + I_vec(indices(ind), : );
        end
        dcp_A = atmSum / numpx;
        A(pic,:) = dcp_A;
        
        % display of dcp_A
        % dcp_A_figure(:, :, 1) = dcp_A(1) * ones(50 * 50);
        % dcp_A_figure(:, :, 2) = dcp_A(2) * ones(50 * 50);
        % dcp_A_figure(:, :, 3) = dcp_A(3) * ones(50 * 50);
        % figure,imshow([dcp_A_figure])
        % saveName = [path_MOF 'mof_' num2str(pic) '_A_dcp'  '.png'];
        % imwrite(dcp_A_figure, saveName);
    else
        % --  Haze-Line  A  -- %
        %
        gamma = 1;
        [ hazeline_A ] = reshape( estimate_airlight( image_hazy .^ (gamma)), 1, 1, 3 );
        A(pic, :) = hazeline_A;
        
        % display of hazeline_A
        % hazeline_A(pic, :)_figure(:,:,1) = hazeline_A(pic, :)(1)*ones(50*50);
        % hazeline_A(pic, :)_figure(:,:,2) = hazeline_A(pic, :)(2)*ones(50*50);
        % hazeline_A(pic, :)_figure(:,:,3) = hazeline_A(pic, :)(3)*ones(50*50);
        % figure,imshow([hazeline_A(pic, :)_figure])
        % saveName = [path_MOF 'mof_' num2str(pic) '_A_hl'  '.png'];
        % imwrite(hazeline_A(pic, :)_figure, saveName);
    end
    %% Transmission t Estimating and Refining
    image_norm = zeros(size(image_hazy));
    for index = 1 : 3
        image_norm(:, :, index) = image_hazy(:, :, index) ./ A(pic, index);
    end
    
    % setting for mof
    w = [5, 11, 17, 23] ;                          % window size for Gaussian filter
    N = length(dcpR) + 1;    tau = 0.138;
    Wm = sum(dcpR-1);  dcpRExp=exp(tau .* (dcpR - 1)) ;  Wme = sum(dcpRExp);
    W =flipud(dcpRExp' / Wme);      % parameter v in the literatrue
    
    [dark_patch, dark_pixel] = dcp_multiscale(image_norm, dcpR);
    t = cell(length(dcpR) + 1, 1);
    
    omega = 1;
    t{1} = max(min( 1 - omega * dark_pixel, 1), 0 );
    for index = 2 : N
        t{index} = min( 1 - omega * dark_patch{index - 1}, 1 );
    end
    
    % refine t using MOF model
    [ mof_t_gif, mof_t ] = mof_main( image_hazy, t, W, w, N, pic, subsampling, method.stretch );
    
    %% Dehazing
    dehazingMOF = getRadiance( A(pic, :), image_hazy, mof_t_gif );
    
    %% Exposure Enhancement
    % there are two different exposure enhancement algorithms
    if ~method.exposure
        % --  ours  -- %
        [ dehazingMOF_E, mean_L_I(pic), mean_L_J(pic), mean_L_MOF(pic) ] = imexposure( dehazingMOF, image_hazy);
    else
        % --  LIME  -- %
        % Guo X, Li Y, Ling H. LIME: Low-light image enhancement via illumination map estimation[J]. IEEE Transactions on Image Processing, 2017, 26(2): 982-993.
        dehazingMOF_E = imexposure_lime(dehazingMOF, denoise);
    end
    
    % running time
    t2=clock;
    RunningTime(pic) = etime(t2, t1) ;
    
    %% Results Saving
    figure(1), imshow( [image_hazy, dehazingMOF_E] );
    saveName = [path_MOF 'MOF_' num2str(pic,'%03d')  '_A' num2str(method.A) '_E' num2str(method.exposure) '_S' num2str(subsampling) '_M' num2str(alpha) '.png'];
    imwrite(dehazingMOF_E, saveName);
    
    'END'
    
end
RunningTime = RunningTime';


