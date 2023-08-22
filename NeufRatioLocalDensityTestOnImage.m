clc
close all
clear all

addpath('E:\CloudStation\study\Neurolab\Publish\TIM\fig\material');
addpath('E:\CloudStation\study\WormDataCenter\Worms');
addpath('D:\StudyInCloud\SynologyDrive\Neurolab\Publish\TIM\fig\material')
addpath('D:\StudyInCloud\SynologyDrive\Dissertation\Figs\Links');

OrigImageStackName = '20230227-3DTIMTV15911-6-LED5-Original-XYCrop-Slice10';
ImageNameBuf = strcat(OrigImageStackName,'.tif');
% OrigImage3D = tiffreadVolume( ImageNameBuf);
SliceNum = 10;
SliceNumStr = num2str(SliceNum);
% OrigImage = OrigImage3D(:,:,SliceNum);
OrigImage = imread(ImageNameBuf);
Darkcount = 83;
Density = 2; 

figure
imshow(OrigImage,[])
title('OrigImage')
impixelinfo

%% get Neuf filtering results
FiberSegment = NeufRatioLocalDensity(OrigImage, Darkcount, Density);

figure
imshow(FiberSegment,[])
title('FiberSegment')
impixelinfo