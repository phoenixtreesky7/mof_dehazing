function [t_mof_gif, t_mof] = mof_main(image_hazy, t, W, w, N, pic, subsampling, stretch)

% This code is used to estimate the final refining transmission ultilating MOF model.
%
% Input - image_hazy :   the color image
%                             t :   pixel-wise and patch-wise transmission maps in t{.} cell
%                            w :   scale of the Gaussion window
%                           W :   Weight of different scale in fusion
%                            N :   Scale number
%                          pic :   the pic number in path_MOF
% Output -  t_mof_gif :   refined transmission map smoothed by fast GD-GIF
%                      t_mof :   refined transmission map without smoothed
%
% Dong Zhao  2016.11.01

path_MOF = 'F:\DehazingImages\DehazingImage_Input\outdoor_datasets\MOF\';
if ~exist(path_MOF)
    mkdir(path_MOF);
end

[x, y] = size(t{1});
t_mof = zeros(size(t{1}));

% Different Decolorization Algorithms you can try
imageGray = GcsDecolor2(image_hazy);
%imageGray = SPDecolor(image_hazy);
%imageGray = rgb2gray(image_hazy);

Diff_t = cell(N-1,1);   Diff_t_G = cell(N-1,1);    Diff_t_stretch = cell(N-1,1);
Diff_t_Scale = cell(N-1,1);

%% MOF
for index = 1 : N-1
    t_temp = t_mof;
    t_mof = zeros(x, y);
    
    % --   D_t  -- %
    Diff_t{index} = max( t{index + 1} - t{1}, 0.001 );
    %imagesc( Diff_t{index}, [0 1]); colormap jet;axis off  % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
    %saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_diff' num2str(index) ],'png');
    Diff_t{index} = ( Diff_t{index} - min( min( Diff_t{index} ) ) ) / ( max( max( Diff_t{index} ) ) - min( min( Diff_t{index} ) ) );
    
    % --  D_g  -- %
    gaussian_kernel = fspecial( 'gaussian', [ w(index), w(index) ], 0.5 );
    Diff_t_G{index} = imfilter( Diff_t{index}, gaussian_kernel, 'conv', 'same', 'replicate' );
    %imagesc( Diff_t_G{index}, [0 1]); colormap jet; axis off % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
    %saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_gaus' num2str(index) ],'png');
    
    % --  D_tanh  -- %
    thr = 0.5; k = 0.05; e = 2.718281828;
    if ~stretch
        % --  linear stretch  -- %
        for xi = 1 : x
            for xj = index : y
                if  Diff_t_G{index}(xi, xj) >= thr
                    Diff_t_stretch{index}(xi, xj) = 0.95 + 0.05 * Diff_t_G{index}(xi, xj);
                else
                    Diff_t_stretch{index}(xi, xj) = 0.05 * Diff_t_G{index}(xi, xj);
                end
            end
        end
        %imagesc(Diff_t_stretch{index},[0 1]);colormap jet;  colorbar('FontSize',30, 'FontWeight','bold'); axis image;
        %saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_linear' num2str(index) ],'png');
    else
        
        % --  tanh stretch  -- %
        for xi = 1 : x
            for xj = index : y
                if  Diff_t_G{index}(xi, xj) >= thr
                    xtr1 = 10 * (Diff_t_G{index}(xi, xj) - (thr + k));
                    Diff_t_stretch{index}(xi, xj) = ((e.^xtr1 - e.^(-xtr1)) ./ (e.^xtr1 + e.^(-xtr1)) + 1) / 2;
                else
                    xtr1 = 10 * (Diff_t_G{index}(xi, xj) - (thr - k));
                    Diff_t_stretch{index}(xi, xj) = ((e.^xtr1 - e.^(-xtr1)) ./ (e.^xtr1 + e.^(-xtr1)) + 1) / 2;
                end
            end
        end
        %imagesc( Diff_t_stretch{index}, [0 1]); colormap jet; axis off     % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
        %saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_tanh' num2str(index) ],'png');
    end
    
    Diff_t_stretch_non{index} = 1 - Diff_t_stretch{index};
    
    % --  single-scale t_mof  -- %
    lambda_d = 0.00001;
    Diff_t_Scale{index} =  ( Diff_t_stretch_non{index} .* t{index + 1} + Diff_t_stretch{index} .* t{1} + lambda_d ) ./ ( Diff_t_stretch_non{index}.^2 + Diff_t_stretch{index}.^2 + lambda_d);
    %imagesc( Diff_t_Scale{index} , [0 1]); colormap jet; axis off % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
    %saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_tmof' num2str(index) ],'png');
    
    % --  multi-scale t_mof  -- %
    Diff_t_Scale{index} = W(index) * Diff_t_Scale{index};
    t_mof = Diff_t_Scale{index}  + t_temp;
    %imagesc( t_mof, [0 1]); colormap jet; axis off % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
    %saveas(gcf,[ path_MOF 'MS_'  num2str(pic) '_msfuse' ],'png');
end

%% Fast GD-GIF
% --  t_mof_gif    -- %
eps = 10^-3;
[t_mof_gif, chi_I, weight, gamma, mean_a, mean_b] = gradient_guidedfilter_fast(imageGray, t_mof, eps, subsampling );
t_mof_gif = min(max(t_mof_gif, 0.1), 1);
%imagesc( t_mof_gif, [0 1]); colormap jet; axis off % colorbar('FontSize',30, 'FontWeight','bold'); axis image;
%saveas(gcf,[ path_MOF 'MOF_'  num2str(pic) '_tcomgif'  ],'png');






