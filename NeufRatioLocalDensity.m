function [FiberSegment] = NeufRatioLocalDensity(Image, Darkcount, Density)
% Find fiber like structures using Neuf filtering.
% example: FiberSegment = NeufRatioLocalDensity(Image, Darkcount, Density)
% After Neuf filtering and Ratio calculation, any pixel that has a higher 
% than high threshold will be regarded as an fiber pixel '1'. Then, this 
% function will try to look over every 3*3 pixels that are centered at this
% pixel, and regard this pixel as an fiber pixel if and only if: 
% 1. Within those 3*3 pixels, there is at least one pixel has already been 
% decided as '1', which is a fiber pixel; 
% 2. This pixel has an atan(Gy/Gx)angle that is within 30 degree from that 
% existing fiber pixel.
% if Density is not given, by default it is 2.


if nargin < 3
    Density = 2; % by default, density of fiber is set to 2%.
end

OrigImage = double(Image) - Darkcount; % camera darkcount should be measurement in lab
[a, b] = size(OrigImage);
ImageRatioOut = zeros(a,b);
ImageRatioOutLow = zeros(a,b);

Gx = [-ones(5) 2*ones(5) -ones(5)]; % the defacult fiber thickness is 5
Gy = Gx';

ImageX = double(imfilter(OrigImage,Gx,'replicate'));
ImageY = double(imfilter(OrigImage,Gy,'replicate'));
ImageAngle = (atan2(ImageY,ImageX)/(2*pi))*360; 
% for directionality based double thresholding. May not necessary if high speed is needed.

ImageX(ImageX<0) = 0; % rectify
ImageY(ImageY<0) = 0;

ImageMagnitude = sqrt(ImageX.^2+ImageY.^2); % this is the Neuf enhanced image

RatioImage = ImageMagnitude./OrigImage; % this is the Ratio image
% ImageRatioSeg = RatioImage;

DensityRatioThres = prctile(RatioImage(:), 100 - Density,'all'); 
% find the threshold value according to the density set

DensityRatioThresLow = prctile(RatioImage(:), 100 - (Density * 1.5),'all'); 
% find a lower threshold for double thresholding. May not necessary if high speed is needed.

ImageRatioOut(RatioImage > DensityRatioThres) = 1; % segmentation
ImageRatioOut(ImageMagnitude < 2000) = 0; 
% in case a plane contains no fiber-like structures. This is the background
% cleaning in paper
ImageRatioOutLow(RatioImage > DensityRatioThresLow) = 1; 
ImageRatioOutLow(ImageMagnitude < 2000) = 0; 


ImageRatioOut = bwareaopen(ImageRatioOut,4,8); % remove very small connected pixels
ImageRatioOutLow = bwareaopen(ImageRatioOutLow,4,8); % remove very small connected pixels


% start the local density constrain

XNumber = 50; % to divide an image to 50*50 subimages
SubMatrixX = floor(b / XNumber); % how many subimages in the horizontal direction

YNumber = 50; % to divide an image to 50*50 subimages
SubMatrixY = floor(a / YNumber); % how many subimages in the vertical direction

SubImageSize = XNumber * YNumber;
DensityPixelNumber = SubImageSize * (Density/100); % for a giving density, how many '1' pixels will be in the subimage

for m = 1:SubMatrixX
    for n = 1:SubMatrixY
        ImageOutLocal = ImageRatioOut((n-1)*YNumber+1:n*YNumber,(m-1)*XNumber+1:m*XNumber); % local subimages segmentation
        ImageOutLocalSum = sum(ImageOutLocal(:));
        
        if ImageOutLocalSum >= DensityPixelNumber*3 % if subimage pixels with assigned '1' has a density greater than 3 times density, this means it is not sparse but relatively good.
            if ImageOutLocalSum >= DensityPixelNumber*4 % if subimage pixels with assigned ones has a density greater than 5 times density, this means it is dense area
                ImageOutLocalSumCase = 1;
            end
            if ImageOutLocalSum >= DensityPixelNumber*3 && ImageOutLocalSum < DensityPixelNumber*4 % relative dense but not too dense area
                ImageOutLocalSumCase = 2;
            end
            
            RatioImageLocal = RatioImage((n-1)*YNumber+1:n*YNumber,(m-1)*XNumber+1:m*XNumber);
            
            switch ImageOutLocalSumCase
                case 1
                    ImageOutmnSuroundDensityThres = prctile(RatioImageLocal,100 - Density*4,'all'); % to reduce very dense area density in segmentation
                    ImageOutLocal(RatioImageLocal<ImageOutmnSuroundDensityThres) = 0;
                case 2
                    ImageOutmnSuroundDensityThres = prctile(RatioImageLocal,100 - Density*3,'all'); % to reduce relative dense area density in segmentation
                    ImageOutLocal(RatioImageLocal<ImageOutmnSuroundDensityThres) = 0;
            end
            
            ImageRatioOut((n-1)*YNumber+1:n*YNumber,(m-1)*XNumber+1:m*XNumber) = ImageOutLocal; % local density reduced in segmentation
        end
    end
end

% FiberSegment = ImageRatioOut; % The segmentation is a combination of Neuf, Ratio, Local sparsity constrain
% if you don't want to use the directionality based double thresholding,
% you should use the 'ImageRatioOut' as the output of this function and
% delete all the rest part of this code.

% for directionality determination
for m = 2:a-1
    for n = 2:b-1
        if RatioImage(m,n) > DensityRatioThresLow && RatioImage(m,n) < DensityRatioThres
            SurroundSum = sum(sum(ImageRatioOut(m-1:m+1,n-1:n+1)));
            if SurroundSum >= 1
                SurroundingPixelsAngle = ImageAngle(m-1:m+1,n-1:n+1);
                PixelAngle = ImageAngle(m,n);
                for j = 1:3
                    for k = 1:3
                        if abs(SurroundingPixelsAngle(j,k)-PixelAngle) <= 30 % we consider pixels with <30 degree difference as having the same directionality
                            ImageRatioOut(m,n) = 1;
                            break
                        end
                        if abs(SurroundingPixelsAngle(j,k))>= 150 && abs(PixelAngle) >= 150  
                            AngleBufMin = -180 - min(SurroundingPixelsAngle(j,k),PixelAngle);
                            AngleBufMax = 180 - max(SurroundingPixelsAngle(j,k),PixelAngle);
                            if AngleBufMax - AngleBufMin <= 30 
                                ImageRatioOut(m,n) = 1;
                                break
                            end
                        end
                    end
                    if ImageRatioOut(m,n) == 1
                        break
                    end
                end
            end
        end
    end
end    
FiberSegment = ImageRatioOut; % The segmentation is a combination of Neuf, Ratio, Local density constrain, directionality

end




