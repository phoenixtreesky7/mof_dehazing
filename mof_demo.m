
% This is a Matlab re-implementation of the paper.
%
% Multi-scale Optimal Fusion Model for Single Image Dehazing
%
% Dong Zhao, Long Xu, Yihua Yan, Jie Chen, Lingyu Duan
% 2018.07.23


close all
clear all
clc

path_MOF = 'F:\1_MyWork\Ipaper\MOF_els\PIC\hazy\MOF\';  % your path for results saving
path_input = 'D:\DongWorks\DehazingNeuroComputing\DEHAZING\dehazingMATLAB\DehazingImages\DehazingImage_Input\outdoor_datasets\hazy\';  % your path for input reading

if ~exist(path_MOF)
    mkdir(path_MOF);
end
%%  Image Reading Method One
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
% %%  Image Reading Method Two
% im_path_pro = genpath(path_input);    % 获得文件夹data下所有子文件的路径，这些路径存在字符串p中，以';'分割
% im_path = im_path_pro(size(path_input,2)+2 :end);
% Length.im_path = size(im_path,2);               %字符串p的长度
% path = {};              %建立一个单元数组，数组的每个单元中包含一个目录
% temp = [];
% for path_num = 1 : Length.im_path %寻找分割符';'，一旦找到，则将路径temp写入path数组中
%     if im_path(path_num) ~= ';'
%         temp = [temp im_path(path_num)];
%     else
%         temp = [temp '\']; %在路径的最后加入 '\'
%         path = [path ; temp];
%         temp = [];
%     end
% end
% clear im_path  temp;
% %至此获得data文件夹及其所有子文件夹（及子文件夹的子文件夹）的路径，存于数组path中。
% %下面是逐一文件夹中读取图像
% Length.img = 1;
% file_num = size(path,1);  % 子文件夹的个数
% for fn = 1 : file_num
%     file_path =  path{fn};    % 图像文件夹路径
%     img_path_list = [];
%     img_path_list = dir(strcat(file_path, '*.png'));
%     if ~isempty(img_path_list)
%         img_num = size(img_path_list,1);       %该文件夹中图像数量
%     else
%         img_num = 0;
%     end
%     if img_num > 0
%         for fin = 1 : img_num
%             image_name{Length.img, 1} =strcat(img_path_list(fin).folder, '\', img_path_list(fin).name);  % 图像名
%             Length.img = Length.img + 1;
%         end
%     end
% end

%% Parameters Setting
denoise = 0;
subsampling = 2;
method.A = 0;                   % A estimating method:              0 -> DCP method;   1 -> HezeLine method 
                                         % If your PC has GPU, you can set method.A = 1,
                                         % else please choose method.A = 0
method.exposure = 1;   % Exposure method:                     0 -> our paper;        1 -> LIME method
method.stretch = 0;        % D_{tanh} stretched method:  0 -> linear;                1 -> tanh
gpu_ava = 1;                      % GPU is available when using haze-line A estimating, i.e. method.A =1
RunningTime = zeros(size(image_name, 1), 1);
PixleNumber = zeros(size(image_name, 1), 1);

%% MOF Dehazing
for pic = 4 : 1 : size(image_name, 1)
    pic
    
    image_hazy = im2double(imread(strcat(path_input, image_name(pic).name)));
    PixleNumber(pic) = size(image_hazy, 1) * size(image_hazy, 2);
    
    % Scale number
    dcpR(1) = 2 * floor(log10(PixleNumber(pic)));  alpha = 1;
    dcpR(2) = 2 * dcpR(1);                                    alpha = 2;
    %   dcpR(3) = 3 * dcpR(1);                                    alpha = 3;
    %   dcpR(4) = 4 * dcpR(1);                                    alpha = 4;
    %%   A
    time1 = clock;
    if ~method.A
        % --  DCP A  -- %
        dark = dcp(image_hazy, 25);
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
        image_hazy_downsample = image_hazy(1:4:end, 1:4:end, :);
        [ hazeline_A ] = reshape( estimate_airlight( image_hazy_downsample.^gamma, gpu_ava), 1, 1, 3 );
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
    
    omega = 0.95;
    t{1} = max(min( 1 - omega * dark_pixel, 1), 0 );
%         imagesc( t{1} , [0 1]); colormap jet; axis off % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
%     saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_tpi'  ],'png');
    for index = 2 : N
        t{index} = min( 1 - omega * dark_patch{index - 1}, 1 );
%                 imagesc( t{index} , [0 1]); colormap jet; axis off % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
%     saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_tpa' num2str(index) ],'png');
    end

    
    % refine t using MOF model
    [ mof_t_gif, runningtime_mof, runningtime_gif ] = mof_main( image_hazy, t, W, w, N, pic, subsampling, method.stretch );
    
    %% Dehazing
    dehazingMOF = getRadiance( A(pic, :), image_hazy, mof_t_gif );
    
    %% Exposure Enhancement
    % there are two different exposure enhancement algorithms
    if method.exposure == 0
        % --  ours  -- %
        [ dehazingMOF_E, mean_L_I(pic), mean_L_J(pic), mean_L_MOF(pic) ] = imexposure( dehazingMOF, image_hazy);
    elseif method.exposure == 1
        % --  LIME  -- %
        % Guo X, Li Y, Ling H. LIME: Low-light image enhancement via illumination map estimation[J]. IEEE Transactions on Image Processing, 2017, 26(2): 982-993.
        dehazingMOF_E = imexposure_lime(dehazingMOF, denoise);
    else
        dehazingMOF_E = dehazingMOF;
    end
    
    % running time
    time2=clock;
    RunningTime(pic) = etime(time2, time1) ;
     
    %% Results Saving
     figure(1), imshow( [image_hazy, dehazingMOF_E] );
    saveName = [path_MOF 'DCP_' num2str(pic,'%03d') '.png'];  %   '_A' num2str(method.A) '_E' num2str(method.exposure) '_S' num2str(subsampling) '_M' num2str(alpha) 
    imwrite(dehazingMOF, saveName);
%     saveName = [path_MOF 'DCP_t_' num2str(pic,'%03d') '.png'];  %   '_A' num2str(method.A) '_E' num2str(method.exposure) '_S' num2str(subsampling) '_M' num2str(alpha) 
%     imwrite(mof_t_gif, saveName);
    
    'END'
    
end



