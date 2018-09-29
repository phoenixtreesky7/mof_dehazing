function imDst = autolevel(varargin)

[I, low_crop, high_crop]  = parse_inputs(varargin{ : });
I = im2uint8(I);
[hei, wid, ~] = size(I);

PixelNumber = wid * hei;

if size(I, 3) == 3
   [hist_red, ~] = imhist(I( :, :, 1));
   [hist_green, ~] = imhist(I( :, :, 2));
   [hist_blue, ~] = imhist(I( :, :, 3));

   cum_red = cumsum(hist_red);
   cum_green = cumsum(hist_green);
   cum_blue = cumsum(hist_blue);

   min_red = find(cum_red >= PixelNumber * low_crop, 1, 'first');
   min_green = find(cum_green >= PixelNumber * low_crop, 1, 'first');
   min_blue = find(cum_blue >= PixelNumber * low_crop, 1, 'first');

   max_red = find(cum_red >= PixelNumber * (1 - high_crop), 1, 'first');
   max_green = find(cum_green >= PixelNumber * (1 - high_crop), 1, 'first');
   max_blue = find(cum_blue >= PixelNumber * (1 - high_crop), 1, 'first');

   map_red = linearmap(min_red, max_red);
   map_green = linearmap(min_green, max_green);
   map_blue = linearmap(min_blue, max_blue);

   imDst = zeros(hei, wid, 3, 'uint8');
   imDst( :, :, 1) = map_red (I( :, :, 1) + 1);
   imDst( :, :, 2) = map_green(I( :, :, 2) + 1);
   imDst( :, :, 3) = map_blue(I( :, :, 3) + 1);

else
   HistGray = imhist(I( :, : ));
   CumGray = cumsum(hist_red);
   minGray = find(CumGray >= PixelNumber*low_crop, 1, 'first');
   maxGray = find(CumGray >= PixelNumber*(1 - high_crop), 1, 'first');
   GrayMap = linearmap(minGray, maxGray);

   imDst = zeros(hei, wid, 'uint8');
   imDst( :, : ) = GrayMap (I( :, : ) + 1); 
end



%%%%%%%% function of linearmap %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function map = linearmap(low, high)
map = [0 : 1 : 255];
for i = 0 : 255
   if(i < low)
       map(i + 1) = 0;
   elseif (i > high)
       map(i + 1) = 255;
   else
       map(i + 1) = uint8((i - low) / (high - low) * 255);
   end
end


%%%%%%%% function of parse_inputs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [I, low_crop, high_crop] = parse_inputs(varargin)
narginchk(1, 3)
I = varargin{1};
validateattributes(I, {'double', 'logical', 'uint8', 'uint16', 'int16', 'single'}, {}, ...
             mfilename, 'Image', 1);

if nargin == 1
   low_crop = 0.005;
   high_crop = 0.005;
elseif nargin == 3
   low_crop = varargin{2};
   high_crop = varargin{3};
else
   error(message('images : im2double : invalidIndexedImage', 'single, or logical.'));
end